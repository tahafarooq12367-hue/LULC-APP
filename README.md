# LULC AI Classifier

A deep learning based Land Use Land Cover (LULC) classification app built with Flutter and a Python Flask backend. Upload satellite or aerial imagery and get instant land cover predictions powered by a hybrid CNN + Vision Transformer model trained on the EuroSAT dataset.

---

## Features

- Classify satellite images into 10 land cover categories
- Confidence scores with pie chart and bar chart visualizations
- Top-3 predictions with color-coded results
- Gallery and camera image input
- Dark satellite-themed UI
- Python Flask backend with TensorFlow inference

## Land Cover Classes

| Class | Description |
|-------|-------------|
| AnnualCrop | Annual crop fields |
| Forest | Dense forest areas |
| HerbaceousVegetation | Grasslands and shrubs |
| Highway | Roads and highways |
| Industrial | Industrial zones |
| Pasture | Pasture land |
| PermanentCrop | Orchards and vineyards |
| Residential | Urban residential areas |
| River | Rivers and waterways |
| SeaLake | Sea and lake bodies |

---

## Project Structure

```
├── backend/                  # Python Flask backend
│   ├── app.py                # Flask server with model inference
│   └── requirements.txt      # Python dependencies
│
└── lulc_app/                 # Flutter mobile app
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   │   ├── splash_screen.dart
    │   │   ├── auth_screen.dart
    │   │   ├── home_screen.dart
    │   │   ├── upload_screen.dart
    │   │   ├── processing_screen.dart
    │   │   ├── result_screen.dart
    │   │   └── previous_work_screen.dart
    │   ├── services/
    │   │   └── api_service.dart
    │   ├── models/
    │   │   └── result_model.dart
    │   └── theme/
    │       └── app_theme.dart
    ├── assets/
    │   └── models/
    │       ├── model.py           # Model architecture
    │       ├── train-model.py     # Training script
    │       ├── predict.py         # Desktop prediction script
    │       ├── class_names.txt    # 10 EuroSAT class names
    │       └── output_*/          # Trained model weights (.h5)
    └── pubspec.yaml
```

---

## Model Architecture

Hybrid deep learning model combining three branches:

- **EfficientNet-style branch** — DepthwiseConv2D blocks with residual connections
- **ResNet branch** — Standard residual convolutional blocks
- **Vision Transformer (ViT) branch** — Patch-based self-attention with positional embeddings

All three branches are fused via concatenation and a final dense classifier. Trained on the [EuroSAT dataset](https://github.com/phelber/EuroSAT) at 64×64 resolution.

---

## Setup

### Backend

Requirements: Python 3.10+, TensorFlow 2.16

```bash
cd backend
pip install -r requirements.txt
python app.py
```

Server starts at `http://0.0.0.0:5000`

### Flutter App

Requirements: Flutter 3.x, Android SDK

```bash
cd lulc_app
flutter pub get
flutter run
```

**Important:** Update the backend URL in `lib/services/api_service.dart`:

```dart
// Android emulator
static const String _baseUrl = 'http://10.0.2.2:5000';

// Physical device (use your PC's LAN IP shown when backend starts)
static const String _baseUrl = 'http://192.168.x.x:5000';
```

Your phone and PC must be on the same WiFi network.

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/classify` | Classify an image (multipart/form-data, field: `image`) |
| GET | `/history` | Get previous results |
| GET | `/health` | Health check + class list |

### Example response from `/classify`

```json
{
  "success": true,
  "label": "Forest",
  "confidence": 94.3,
  "top_results": [
    { "label": "Forest", "confidence": 94.3 },
    { "label": "HerbaceousVegetation", "confidence": 3.8 },
    { "label": "Pasture", "confidence": 1.2 }
  ]
}
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile UI | Flutter (Dart) |
| Charts | fl_chart |
| Backend | Python, Flask |
| ML Framework | TensorFlow 2.x / Keras |
| Dataset | EuroSAT (RGB, 64×64) |
| Image input | image_picker |
| HTTP | http (Dart) |

---

## Training

To retrain the model on your own EuroSAT dataset:

```bash
cd lulc_app/assets/models
# Update DATASET_PATH in train-model.py
python train-model.py
```

Trained weights are saved to `output_<timestamp>/best_model.h5`.
