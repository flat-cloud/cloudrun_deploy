# Node.js Express Sample App

A simple Express.js REST API for testing Cloud Run deployments.

## Features

- ✅ REST API with JSON responses
- ✅ Health check endpoint
- ✅ Echo endpoint for POST testing
- ✅ Environment info display
- ✅ Extremely lightweight (~40MB container)
- ✅ Fast cold start (~1-2 seconds)

## Endpoints

- `GET /` - Home page with service info
- `GET /health` - Health check
- `GET /api/info` - Detailed service information
- `POST /api/echo` - Echo back JSON payload

## Local Testing

### With Node.js
```bash
npm install
npm start
```

### With Docker
```bash
docker build -t express-app .
docker run -p 8080:8080 -e PORT=8080 express-app
```

Test it:
```bash
curl http://localhost:8080
curl http://localhost:8080/health
curl http://localhost:8080/api/info
curl -X POST http://localhost:8080/api/echo -H "Content-Type: application/json" -d '{"test":"data"}'
```

## Deploy to Cloud Run

```bash
# From the repository root
./deploy_to_cloudrun.sh

# Or navigate to this directory first
cd sample-apps/nodejs-express
../../deploy_to_cloudrun.sh
```

## Configuration

Environment variables:
- `PORT` - Server port (default: 8080)
- `K_SERVICE` - Cloud Run service name (auto-set)
- `K_REVISION` - Cloud Run revision (auto-set)

## Performance

- Container size: ~40MB
- Cold start: ~1-2 seconds
- Memory usage: ~50MB
- Suitable for: APIs, webhooks, microservices
