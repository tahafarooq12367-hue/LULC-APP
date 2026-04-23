import tensorflow as tf
import numpy as np
import cv2
import os
import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk

# 🔥 custom layers
from model import Patches, PatchEncoder

# ================================
# LOAD MODEL
# ================================
model = tf.keras.models.load_model(
    "output_20260411_223819/best_model.h5",
    custom_objects={
        "Patches": Patches,
        "PatchEncoder": PatchEncoder
    }
)

# ================================
# CLASS NAMES
# ================================
DATASET_PATH = r"E:\c\fyp_All_Data\FYP_new\dataset\EuroSAT"

class_names = sorted([
    d for d in os.listdir(DATASET_PATH)
    if os.path.isdir(os.path.join(DATASET_PATH, d))
])

# ================================
# GUI WINDOW
# ================================
root = tk.Tk()
root.title("Satellite Image Classification")
root.geometry("700x600")

# ================================
# IMAGE DISPLAY
# ================================
img_label = tk.Label(root)
img_label.pack()

# ================================
# RESULT TEXT
# ================================
result_text = tk.Text(root, height=15, width=80)
result_text.pack()

# ================================
# FUNCTION: PREDICT
# ================================
def predict_image():
    file_path = filedialog.askopenfilename(
        filetypes=[("Image Files", "*.jpg *.png *.jpeg")]
    )

    if not file_path:
        return

    # Show image
    img_pil = Image.open(file_path)
    img_pil = img_pil.resize((200, 200))
    img_tk = ImageTk.PhotoImage(img_pil)
    img_label.config(image=img_tk)
    img_label.image = img_tk

    # Preprocess
    img = cv2.imread(file_path)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, (64, 64))
    img = img / 255.0
    img = np.expand_dims(img, axis=0)

    # Predict
    pred = model.predict(img)[0]

    pred_class = np.argmax(pred)
    confidence = np.max(pred)

    # Clear previous text
    result_text.delete(1.0, tk.END)

    # Show main result
    result_text.insert(tk.END, f"Predicted Class: {class_names[pred_class]}\n")
    result_text.insert(tk.END, f"Confidence: {confidence*100:.2f}%\n\n")

    result_text.insert(tk.END, "Class Probabilities:\n")
    result_text.insert(tk.END, "-"*40 + "\n")

    # Show all class percentages
    for i, prob in enumerate(pred):
        result_text.insert(
            tk.END,
            f"{class_names[i]:25s}: {prob*100:.2f}%\n"
        )

# ================================
# BUTTON
# ================================
btn = tk.Button(root, text="Upload Image", command=predict_image, font=("Arial", 14))
btn.pack(pady=10)

# ================================
# RUN
# ================================
root.mainloop()