import os
import sys
import numpy as np
from flask import Flask, request, jsonify
from PIL import Image
import io

os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

import tensorflow as tf
from tensorflow.keras.layers import (
    Input, Conv2D, DepthwiseConv2D, BatchNormalization, Activation,
    Add, GlobalAveragePooling2D, GlobalAveragePooling1D, Dense, Dropout,
    Concatenate, LayerNormalization, MultiHeadAttention, Embedding,
    Resizing, Normalization
)
from tensorflow.keras.models import Model
from tensorflow.keras.regularizers import l2

# ── Rebuild the exact same architecture from model.py ────────────────────

INPUT_SHAPE = (None, None, 3)
IMAGE_SIZE  = (64, 64)
NUM_CLASSES = 10
WEIGHT_DECAY = 1e-4

inputs = Input(shape=INPUT_SHAPE)
x = Resizing(IMAGE_SIZE[0], IMAGE_SIZE[1])(inputs)

mean = [0.485, 0.456, 0.406]
std  = [0.229, 0.224, 0.225]
variance = [s**2 for s in std]
x = Normalization(mean=mean, variance=variance)(x)

# ── Efficient block ───────────────────────────────────────────────────────
def efficient_block(x, filters):
    shortcut = x
    x = DepthwiseConv2D(3, padding='same',
                        depthwise_regularizer=l2(WEIGHT_DECAY))(x)
    x = BatchNormalization()(x)
    x = Activation('relu')(x)
    x = Conv2D(filters, 1, padding='same',
               kernel_regularizer=l2(WEIGHT_DECAY))(x)
    x = BatchNormalization()(x)
    if shortcut.shape[-1] != filters:
        shortcut = Conv2D(1, 1, padding='same')(shortcut)
    x = Add()([x, shortcut])
    return Activation('relu')(x)

e = Conv2D(16, 3, strides=2, padding='same')(x)
e = BatchNormalization()(e)
e = Activation('relu')(e)
for f in [16, 24, 24, 32, 32]:
    e = efficient_block(e, f)
e = GlobalAveragePooling2D()(e)
e = Dense(64, activation='relu')(e)
e = Dropout(0.3)(e)

# ── Residual block ────────────────────────────────────────────────────────
def residual_block(x, filters):
    shortcut = x
    x = Conv2D(filters, 3, padding='same',
               kernel_regularizer=l2(WEIGHT_DECAY))(x)
    x = BatchNormalization()(x)
    x = Activation('relu')(x)
    x = Conv2D(filters, 3, padding='same',
               kernel_regularizer=l2(WEIGHT_DECAY))(x)
    x = BatchNormalization()(x)
    if shortcut.shape[-1] != filters:
        shortcut = Conv2D(1, 1, padding='same')(shortcut)
    x = Add()([x, shortcut])
    return Activation('relu')(x)

r = Conv2D(16, 3, strides=2, padding='same')(x)
r = BatchNormalization()(r)
r = Activation('relu')(r)
for f in [16, 24, 24, 32, 32]:
    r = residual_block(r, f)
r = GlobalAveragePooling2D()(r)
r = Dense(64, activation='relu')(r)
r = Dropout(0.3)(r)

# ── Vision Transformer ────────────────────────────────────────────────────
PATCH_SIZE      = 16
NUM_PATCHES     = (64 // PATCH_SIZE) ** 2   # 16
PROJECTION_DIM  = 48
NUM_HEADS       = 2
TRANSFORMER_UNITS = 96

class Patches(tf.keras.layers.Layer):
    def __init__(self, patch_size, **kwargs):
        super().__init__(**kwargs)
        self.patch_size = patch_size

    def call(self, images):
        patches = tf.image.extract_patches(
            images=images,
            sizes=[1, self.patch_size, self.patch_size, 1],
            strides=[1, self.patch_size, self.patch_size, 1],
            rates=[1, 1, 1, 1],
            padding='VALID',
        )
        patch_dims = patches.shape[-1]
        return tf.reshape(patches, [tf.shape(images)[0], -1, patch_dims])

    def get_config(self):
        cfg = super().get_config()
        cfg['patch_size'] = self.patch_size
        return cfg

class PatchEncoder(tf.keras.layers.Layer):
    def __init__(self, num_patches, projection_dim, **kwargs):
        super().__init__(**kwargs)
        self.num_patches   = num_patches
        self.projection_dim = projection_dim
        self.projection        = Dense(projection_dim)
        self.position_embedding = Embedding(num_patches, projection_dim)

    def call(self, patches):
        positions = tf.range(start=0, limit=tf.shape(patches)[1], delta=1)
        return self.projection(patches) + self.position_embedding(positions)

    def get_config(self):
        cfg = super().get_config()
        cfg.update({'num_patches': self.num_patches,
                    'projection_dim': self.projection_dim})
        return cfg

# Use the same x that went through Resizing + Normalization
vit_input = x   # shape (B, 64, 64, 3) after normalization

patches = Patches(PATCH_SIZE)(vit_input)
encoded = PatchEncoder(NUM_PATCHES, PROJECTION_DIM)(patches)

for _ in range(3):
    x1  = LayerNormalization()(encoded)
    att = MultiHeadAttention(num_heads=NUM_HEADS,
                             key_dim=PROJECTION_DIM)(x1, x1)
    x2  = Add()([att, encoded])
    x3  = LayerNormalization()(x2)
    mlp = Dense(TRANSFORMER_UNITS, activation='gelu')(x3)
    mlp = Dense(PROJECTION_DIM)(mlp)
    encoded = Add()([mlp, x2])

vit = LayerNormalization()(encoded)
vit = GlobalAveragePooling1D()(vit)
vit = Dense(64, activation='relu')(vit)
vit = Dropout(0.3)(vit)

# ── Fusion ────────────────────────────────────────────────────────────────
combined = Concatenate()([e, r, vit])
out = Dense(128, activation='relu')(combined)
out = BatchNormalization()(out)
out = Dropout(0.4)(out)
out = Dense(64, activation='relu')(out)
outputs = Dense(NUM_CLASSES, activation='softmax')(out)

_arch = Model(inputs, outputs)

# ── Load weights from best_model.h5 ──────────────────────────────────────
WEIGHTS_PATH = os.path.join(
    os.path.dirname(__file__), '..', 'lulc_app', 'assets', 'models',
    'output_20260411_223819', 'best_model.h5'
)
CLASS_NAMES_PATH = os.path.join(
    os.path.dirname(__file__), '..', 'lulc_app', 'assets', 'models',
    'class_names.txt'
)
IMG_SIZE = (64, 64)

print('Loading weights...')
_arch.load_weights(WEIGHTS_PATH)
_model = _arch
print('Weights loaded successfully.')

with open(CLASS_NAMES_PATH, 'r') as f:
    CLASS_NAMES = [line.strip() for line in f if line.strip()]

print(f'Classes ({len(CLASS_NAMES)}): {CLASS_NAMES}')

# ── Flask app ─────────────────────────────────────────────────────────────
app = Flask(__name__)


def preprocess(image_bytes: bytes) -> np.ndarray:
    img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    img = img.resize(IMG_SIZE, Image.BILINEAR)
    arr = np.array(img, dtype=np.float32) / 255.0
    return np.expand_dims(arr, axis=0)  # (1, 64, 64, 3)


@app.route('/classify', methods=['POST'])
def classify():
    if 'image' not in request.files:
        return jsonify({'success': False, 'message': 'No image provided'}), 400

    image_bytes = request.files['image'].read()

    try:
        inp   = preprocess(image_bytes)
        preds = _model.predict(inp, verbose=0)[0]  # (10,)

        pred_idx   = int(np.argmax(preds))
        confidence = float(preds[pred_idx])
        label      = CLASS_NAMES[pred_idx]

        top3_idx = np.argsort(preds)[::-1][:3]
        top_results = [
            {'label': CLASS_NAMES[i],
             'confidence': round(float(preds[i]) * 100, 1)}
            for i in top3_idx
        ]

        return jsonify({
            'success':     True,
            'label':       label,
            'confidence':  round(confidence * 100, 1),
            'top_results': top_results,
        })

    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/history', methods=['GET'])
def history():
    return jsonify({'success': True, 'results': []})


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'classes': CLASS_NAMES})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
