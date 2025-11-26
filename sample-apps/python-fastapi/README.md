# Python FastAPI Sample App

A modern async FastAPI application for testing Cloud Run deployments.

## Features

- ✅ Modern async/await support
- ✅ Automatic interactive API docs (Swagger UI)
- ✅ Alternative docs (ReDoc)
- ✅ Data validation with Pydantic
- ✅ Type hints throughout
- ✅ High performance async server (uvicorn)
- ✅ Lightweight container (~60MB)

## Endpoints

- `GET /` - Home page with service info
- `GET /health` - Health check
- `GET /api/info` - Detailed service information
- `POST /api/echo` - Echo back JSON with validation
- `GET /docs` - Interactive API documentation (Swagger UI)
- `GET /redoc` - Alternative API documentation (ReDoc)

## Local Testing

### With Python
```bash
pip install -r requirements.txt
uvicorn main:app --reload --port 8080
```

### With Docker
```bash
docker build -t fastapi-app .
docker run -p 8080:8080 -e PORT=8080 fastapi-app
```

Test it:
```bash
curl http://localhost:8080
curl http://localhost:8080/health
curl http://localhost:8080/api/info

# Test with validation
curl -X POST http://localhost:8080/api/echo \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello","data":{"key":"value"}}'

# View interactive docs
open http://localhost:8080/docs
```

## Deploy to Cloud Run

```bash
# From the repository root
./deploy_to_cloudrun.sh

# Or navigate to this directory first
cd sample-apps/python-fastapi
../../deploy_to_cloudrun.sh
```

## Configuration

Environment variables:
- `PORT` - Server port (default: 8080)
- `K_SERVICE` - Cloud Run service name (auto-set)
- `K_REVISION` - Cloud Run revision (auto-set)

## Performance

- Container size: ~60MB
- Cold start: ~2-3 seconds
- Memory usage: ~100MB
- Request throughput: Very high (async)
- Suitable for: Modern APIs, data validation, high-performance services

## Why FastAPI for Cloud Run?

FastAPI is excellent for Cloud Run because:
- Async/await for high concurrency
- Automatic API documentation
- Built-in data validation
- Type safety
- High performance
- Easy to test and maintain
