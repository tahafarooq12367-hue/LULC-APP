# =========================================================
# 1. MUST BE FIRST (NO TF INITIALIZATION BEFORE THIS)
# =========================================================
import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"
os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"

# =========================================================
# 2. IMPORTS
# =========================================================
import tensorflow as tf
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
from datetime import datetime

# =========================================================
# 3. CPU SETTINGS (SAFE)
# =========================================================
tf.config.threading.set_intra_op_parallelism_threads(2)
tf.config.threading.set_inter_op_parallelism_threads(2)

# =========================================================
# 4. IMPORT YOUR MODEL
# =========================================================
from model import model

# =========================================================
# 5. FIXED DATASET PATH (YOUR ACTUAL PATH)
# =========================================================
DATASET_PATH = r"E:\c\fyp_All_Data\FYP_new\dataset\EuroSAT"

# Safety check (IMPORTANT)
if not os.path.exists(DATASET_PATH):
    raise FileNotFoundError(f"Dataset path not found: {DATASET_PATH}")

# =========================================================
# 6. SETTINGS
# =========================================================
IMG_SIZE = (64, 64)
BATCH_SIZE = 8
EPOCHS = 25
SEED = 42

tf.random.set_seed(SEED)
np.random.seed(SEED)

# =========================================================
# 7. OUTPUT FOLDER
# =========================================================
output_dir = f"output_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
os.makedirs(output_dir, exist_ok=True)

print("Saving to:", output_dir)

# =========================================================
# 8. LOAD CLASS NAMES
# =========================================================
class_names = sorted([
    d for d in os.listdir(DATASET_PATH)
    if os.path.isdir(os.path.join(DATASET_PATH, d))
])

NUM_CLASSES = len(class_names)
print("Classes found:", NUM_CLASSES)

# =========================================================
# 9. LOAD DATA
# =========================================================
file_paths = []
labels = []

for label, cls in enumerate(class_names):
    class_path = os.path.join(DATASET_PATH, cls)

    for file in os.listdir(class_path):
        if file.lower().endswith((".jpg", ".png", ".jpeg")):
            file_paths.append(os.path.join(class_path, file))
            labels.append(label)

file_paths = np.array(file_paths)
labels = np.array(labels)

print("Total images:", len(file_paths))

# =========================================================
# 10. SPLIT DATA
# =========================================================
X_train, X_temp, y_train, y_temp = train_test_split(
    file_paths, labels,
    test_size=0.2,
    stratify=labels,
    random_state=SEED
)

X_val, X_test, y_val, y_test = train_test_split(
    X_temp, y_temp,
    test_size=0.5,
    stratify=y_temp,
    random_state=SEED
)

# =========================================================
# 11. LOAD IMAGE FUNCTION
# =========================================================
def load_image(path, label):
    img = tf.io.read_file(path)
    img = tf.image.decode_jpeg(img, channels=3)
    img = tf.image.resize(img, IMG_SIZE)
    img = tf.cast(img, tf.float32) / 255.0
    return img, label

# =========================================================
# 12. LIGHT AUGMENTATION (CPU SAFE)
# =========================================================
augment = tf.keras.Sequential([
    tf.keras.layers.RandomFlip("horizontal"),
    tf.keras.layers.RandomRotation(0.1),
])

def augment_fn(img, label):
    return augment(img, training=True), label

# =========================================================
# 13. DATA PIPELINE (STABLE)
# =========================================================
def make_dataset(X, y, training=False):
    ds = tf.data.Dataset.from_tensor_slices((X, y))
    ds = ds.map(load_image, num_parallel_calls=2)

    if training:
        ds = ds.map(augment_fn, num_parallel_calls=2)
        ds = ds.shuffle(1000)

    return ds.batch(BATCH_SIZE).prefetch(1)

train_ds = make_dataset(X_train, y_train, True)
val_ds = make_dataset(X_val, y_val)
test_ds = make_dataset(X_test, y_test)

# =========================================================
# 14. CALLBACKS
# =========================================================
callbacks = [
    tf.keras.callbacks.ModelCheckpoint(
        filepath=os.path.join(output_dir, "best_model.h5"),
        monitor="val_accuracy",
        save_best_only=True,
        verbose=1
    ),

    tf.keras.callbacks.EarlyStopping(
        monitor="val_loss",
        patience=7,
        restore_best_weights=True
    ),

    tf.keras.callbacks.ReduceLROnPlateau(
        monitor="val_loss",
        factor=0.5,
        patience=3,
        min_lr=1e-6
    ),

    tf.keras.callbacks.CSVLogger(
        os.path.join(output_dir, "training_log.csv")
    )
]

# =========================================================
# 15. COMPILE MODEL
# =========================================================
model.compile(
    optimizer=tf.keras.optimizers.Adam(1e-4),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)

print("Model compiled successfully")

# =========================================================
# 16. TRAIN
# =========================================================
history = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=EPOCHS,
    callbacks=callbacks
)

# =========================================================
# 17. SAVE FINAL MODEL
# =========================================================
model.save(os.path.join(output_dir, "final_model.h5"))

# =========================================================
# 18. EVALUATION
# =========================================================
test_loss, test_acc = model.evaluate(test_ds)
print("Test Accuracy:", test_acc)

# =========================================================
# 19. PREDICTIONS
# =========================================================
y_true, y_pred = [], []

for imgs, lbls in test_ds:
    preds = model.predict(imgs, verbose=0)
    y_true.extend(lbls.numpy())
    y_pred.extend(np.argmax(preds, axis=1))

y_true = np.array(y_true)
y_pred = np.array(y_pred)

# =========================================================
# 20. REPORT
# =========================================================
report = classification_report(y_true, y_pred, target_names=class_names)

with open(os.path.join(output_dir, "report.txt"), "w") as f:
    f.write(report)

cm = confusion_matrix(y_true, y_pred)
np.save(os.path.join(output_dir, "confusion_matrix.npy"), cm)

# =========================================================
# 21. SAVE CLASS NAMES
# =========================================================
with open(os.path.join(output_dir, "class_names.txt"), "w") as f:
    for c in class_names:
        f.write(c + "\n")

# =========================================================
# 22. SAVE TFLITE MODEL
# =========================================================
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open(os.path.join(output_dir, "model.tflite"), "wb") as f:
    f.write(tflite_model)

# =========================================================
# 23. SAVE GRAPHS
# =========================================================
plt.plot(history.history["accuracy"], label="train")
plt.plot(history.history["val_accuracy"], label="val")
plt.legend()
plt.title("Accuracy")
plt.savefig(os.path.join(output_dir, "accuracy.png"))
plt.close()

plt.plot(history.history["loss"], label="train")
plt.plot(history.history["val_loss"], label="val")
plt.legend()
plt.title("Loss")
plt.savefig(os.path.join(output_dir, "loss.png"))
plt.close()

print("Training completed successfully.")
print("All outputs saved in:", output_dir)