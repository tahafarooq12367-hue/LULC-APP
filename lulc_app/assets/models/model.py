import tensorflow as tf
from tensorflow.keras.layers import *
from tensorflow.keras.models import Model
from tensorflow.keras.regularizers import l2

# =================================================
# SETTINGS
# =================================================
INPUT_SHAPE = (None, None, 3)
IMAGE_SIZE = (64, 64)
NUM_CLASSES = 10   # EuroSAT = 10 classes (change if needed)
WEIGHT_DECAY = 1e-4

inputs = Input(shape=INPUT_SHAPE)

# =================================================
# RESIZE TO 64x64 (FIXED FOR TRAIN + INFERENCE)
# =================================================
x = Resizing(IMAGE_SIZE[0], IMAGE_SIZE[1])(inputs)

# =================================================
# NORMALIZATION (ImageNet style)
# =================================================
mean = [0.485, 0.456, 0.406]
std = [0.229, 0.224, 0.225]
variance = [s**2 for s in std]

x = Normalization(mean=mean, variance=variance)(x)

# =================================================
# ================== CNN BACKBONE ==================
# =================================================

# ---------------- Efficient Block ----------------
def efficient_block(x, filters):
    shortcut = x

    x = DepthwiseConv2D(
        3, padding="same",
        depthwise_regularizer=l2(WEIGHT_DECAY)
    )(x)
    x = BatchNormalization()(x)
    x = Activation("relu")(x)

    x = Conv2D(
        filters, 1, padding="same",
        kernel_regularizer=l2(WEIGHT_DECAY)
    )(x)
    x = BatchNormalization()(x)

    if shortcut.shape[-1] != filters:
        shortcut = Conv2D(1, 1, padding="same")(shortcut)

    x = Add()([x, shortcut])
    return Activation("relu")(x)

# Efficient branch
e = Conv2D(16, 3, strides=2, padding="same")(x)
e = BatchNormalization()(e)
e = Activation("relu")(e)

for f in [16, 24, 24, 32, 32]:
    e = efficient_block(e, f)

e = GlobalAveragePooling2D()(e)
e = Dense(64, activation="relu")(e)
e = Dropout(0.3)(e)

# ---------------- Residual Block ----------------
def residual_block(x, filters):
    shortcut = x

    x = Conv2D(filters, 3, padding="same",
               kernel_regularizer=l2(WEIGHT_DECAY))(x)
    x = BatchNormalization()(x)
    x = Activation("relu")(x)

    x = Conv2D(filters, 3, padding="same",
               kernel_regularizer=l2(WEIGHT_DECAY))(x)
    x = BatchNormalization()(x)

    if shortcut.shape[-1] != filters:
        shortcut = Conv2D(1, 1, padding="same")(shortcut)

    x = Add()([x, shortcut])
    return Activation("relu")(x)

# ResNet branch
r = Conv2D(16, 3, strides=2, padding="same")(x)
r = BatchNormalization()(r)
r = Activation("relu")(r)

for f in [16, 24, 24, 32, 32]:
    r = residual_block(r, f)

r = GlobalAveragePooling2D()(r)
r = Dense(64, activation="relu")(r)
r = Dropout(0.3)(r)

# =================================================
# ================== VISION TRANSFORMER ==================
# =================================================

PATCH_SIZE = 16
NUM_PATCHES = (64 // PATCH_SIZE) ** 2
PROJECTION_DIM = 48
NUM_HEADS = 2
TRANSFORMER_UNITS = 96

# ---------------- Patch Extraction ----------------
class Patches(Layer):
    def __init__(self, patch_size):
        super().__init__()
        self.patch_size = patch_size

    def call(self, images):
        patches = tf.image.extract_patches(
            images=images,
            sizes=[1, self.patch_size, self.patch_size, 1],
            strides=[1, self.patch_size, self.patch_size, 1],
            rates=[1, 1, 1, 1],
            padding="VALID"
        )
        patch_dims = patches.shape[-1]
        patches = tf.reshape(
            patches,
            [tf.shape(images)[0], -1, patch_dims]
        )
        return patches

# ---------------- Patch Encoding ----------------
class PatchEncoder(Layer):
    def __init__(self, num_patches, projection_dim):
        super().__init__()
        self.projection = Dense(projection_dim)
        self.position_embedding = Embedding(num_patches, projection_dim)

    def call(self, patches):
        positions = tf.range(start=0, limit=tf.shape(patches)[1], delta=1)
        encoded = self.projection(patches) + self.position_embedding(positions)
        return encoded

patches = Patches(PATCH_SIZE)(x)
encoded = PatchEncoder(NUM_PATCHES, PROJECTION_DIM)(patches)

# ---------------- Transformer Blocks ----------------
for _ in range(3):   # reduced for stability
    x1 = LayerNormalization()(encoded)

    attention = MultiHeadAttention(
        num_heads=NUM_HEADS,
        key_dim=PROJECTION_DIM
    )(x1, x1)

    x2 = Add()([attention, encoded])

    x3 = LayerNormalization()(x2)
    mlp = Dense(TRANSFORMER_UNITS, activation="gelu")(x3)
    mlp = Dense(PROJECTION_DIM)(mlp)

    encoded = Add()([mlp, x2])

vit = LayerNormalization()(encoded)
vit = GlobalAveragePooling1D()(vit)
vit = Dense(64, activation="relu")(vit)
vit = Dropout(0.3)(vit)

# =================================================
# ================== FUSION ==================
# =================================================
combined = Concatenate()([e, r, vit])

x = Dense(128, activation="relu")(combined)
x = BatchNormalization()(x)
x = Dropout(0.4)(x)

x = Dense(64, activation="relu")(x)

# =================================================
# OUTPUT (IMPORTANT FIX)
# =================================================
outputs = Dense(NUM_CLASSES, activation="softmax")(x)

model = Model(inputs, outputs)

# =================================================
# COMPILE (STABLE SETUP)
# =================================================
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)

print("✅ Stable hybrid model created for EuroSAT (64x64)")