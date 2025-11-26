# Go HTTP Sample App

A simple Go HTTP server for testing Cloud Run deployments.

## Features

- ✅ Native HTTP server (no frameworks)
- ✅ JSON REST API
- ✅ Health check endpoint
- ✅ Ultra-lightweight (~10MB container)
- ✅ Extremely fast cold start (<1 second)
- ✅ Multi-stage Docker build
- ✅ Low memory footprint (~10MB)

## Endpoints

- `GET /` - Home page with service info
- `GET /health` - Health check
- `GET /api/info` - Detailed service information

## Local Testing

### With Go
```bash
go run main.go
```

### With Docker
```bash
docker build -t go-app .
docker run -p 8080:8080 -e PORT=8080 go-app
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
cd sample-apps/go-http
../../deploy_to_cloudrun.sh
```

## Configuration

Environment variables:
- `PORT` - Server port (default: 8080)
- `K_SERVICE` - Cloud Run service name (auto-set)
- `K_REVISION` - Cloud Run revision (auto-set)

## Performance

- Container size: ~10MB (smallest!)
- Cold start: <1 second (fastest!)
- Memory usage: ~10MB (most efficient!)
- Suitable for: High-performance APIs, microservices, latency-sensitive apps

## Why Go for Cloud Run?

Go is ideal for Cloud Run because:
- Static binary - minimal container size
- Fast startup - reduce cold start time
- Low memory usage - reduce costs
- Excellent concurrency support
- No runtime dependencies
