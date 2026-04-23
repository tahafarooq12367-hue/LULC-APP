# LULC Flask Backend

## Setup

```bash
cd backend
pip install -r requirements.txt
python app.py
```

Server starts on `http://0.0.0.0:5000`

## Endpoints

| Method | Path        | Description                        |
|--------|-------------|------------------------------------|
| POST   | /classify   | Classify an image (multipart form) |
| GET    | /history    | Get previous results               |
| GET    | /health     | Health check + class list          |

## Flutter Connection

- Android Emulator: use `http://10.0.2.2:5000`
- Physical device: use your machine's LAN IP, e.g. `http://192.168.1.x:5000`

Update `_baseUrl` in `lib/services/api_service.dart` accordingly.

## Notes

- The backend loads `best_model.h5` directly — no TFLite needed server-side.
- Custom Keras layers (`Patches`, `PatchEncoder`) are imported from `assets/models/model.py`.
