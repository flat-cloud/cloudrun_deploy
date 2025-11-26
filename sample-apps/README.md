# Sample Applications for Cloud Run Testing

This directory contains sample applications in various frameworks to test the Cloud Run deployment scripts.

## Available Applications

### 1. **Python Flask** (`python-flask/`)
- Simple REST API with health check
- Minimal dependencies
- Perfect for quick testing

### 2. **Node.js Express** (`nodejs-express/`)
- REST API with JSON responses
- Fast startup time
- Industry standard

### 3. **Go HTTP Server** (`go-http/`)
- Native HTTP server
- Extremely fast and lightweight
- No external dependencies

### 4. **Python FastAPI** (`python-fastapi/`)
- Modern async API framework
- Auto-generated OpenAPI docs
- Type hints and validation

### 5. **Node.js Next.js** (`nodejs-nextjs/`)
- Full-stack React framework
- Server-side rendering
- Static and dynamic pages

## Quick Start

Each app directory contains:
- `Dockerfile` - Container configuration
- `README.md` - App-specific instructions
- Source code files
- `.dockerignore` - Files to exclude from build

## Deploying an App

```bash
# Navigate to the app directory
cd sample-apps/python-flask

# Deploy using the deployment script
../../deploy_to_cloudrun.sh

# Or use the quick start
../../quick_start.sh
```

## Testing Locally

Each app can be tested locally with Docker:

```bash
cd sample-apps/python-flask
docker build -t test-app .
docker run -p 8080:8080 test-app
curl http://localhost:8080
```

## Cost Considerations

All these apps are designed to be cost-effective:
- Small container sizes
- Fast startup times
- Minimal memory usage
- Efficient request handling

With GCP's free tier (2M requests/month), you can test extensively without charges!
