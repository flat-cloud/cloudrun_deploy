# Python Flask Sample App

A simple Flask REST API for testing Cloud Run deployments.

## Features

- ✅ REST API with JSON responses
- ✅ Health check endpoint
- ✅ Environment info display
- ✅ Production-ready with Gunicorn
- ✅ Lightweight (~50MB container)

## Endpoints

- `GET /` - Home page with service info
- `GET /health` - Health check
- `GET /api/info` - Detailed service information

## Local Testing

### With Python
```bash
pip install -r requirements.txt
python app.py
```

### With Docker
```bash
docker build -t flask-app .
docker run -p 8080:8080 -e PORT=8080 flask-app
```

Test it:
```bash
curl http://localhost:8080
curl http://localhost:8080/health
curl http://localhost:8080/api/info
```

## Deploy to Cloud Run

```bash
# From the repository root
./deploy_to_cloudrun.sh

# Or navigate to this directory first
cd sample-apps/python-flask
../../deploy_to_cloudrun.sh
```

## Configuration

Environment variables:
- `PORT` - Server port (default: 8080)
- `K_SERVICE` - Cloud Run service name (auto-set)
- `K_REVISION` - Cloud Run revision (auto-set)

## Performance

- Container size: ~50MB
- Cold start: ~2-3 seconds
- Memory usage: ~100MB
- Suitable for: APIs, webhooks, simple web services
