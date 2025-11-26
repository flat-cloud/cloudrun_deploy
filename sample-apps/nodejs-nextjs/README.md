# Next.js Sample App

A full-stack Next.js application for testing Cloud Run deployments.

## Features

- ✅ Server-side rendering (SSR)
- ✅ Built-in API routes
- ✅ React 18 with modern features
- ✅ Optimized production builds
- ✅ Multi-stage Docker build
- ✅ Standalone output mode
- ✅ Interactive UI with real-time data

## Pages & Endpoints

### Pages
- `/` - Home page with interactive UI

### API Routes
- `/api/health` - Health check endpoint
- `/api/info` - Service information endpoint

## Local Testing

### With Node.js (Development)
```bash
npm install
npm run dev
# Visit http://localhost:3000
```

### With Docker (Production)
```bash
docker build -t nextjs-app .
docker run -p 8080:8080 -e PORT=8080 nextjs-app
```

Test it:
```bash
curl http://localhost:8080/api/health
curl http://localhost:8080/api/info
# Visit http://localhost:8080 in browser
```

## Deploy to Cloud Run

```bash
# From the repository root
./deploy_to_cloudrun.sh

# Or navigate to this directory first
cd sample-apps/nodejs-nextjs
../../deploy_to_cloudrun.sh
```

## Configuration

Environment variables:
- `PORT` - Server port (default: 8080)
- `K_SERVICE` - Cloud Run service name (auto-set)
- `K_REVISION` - Cloud Run revision (auto-set)

## Performance

- Container size: ~120MB
- Cold start: ~3-4 seconds
- Memory usage: ~150MB
- Suitable for: Full-stack apps, dashboards, web applications with UI

## Why Next.js for Cloud Run?

Next.js is great for Cloud Run because:
- Standalone output mode creates optimized bundles
- Built-in API routes (no separate backend needed)
- SSR for better SEO and performance
- Optimized for production
- Large ecosystem and community

## Build Optimization

The Dockerfile uses:
- Multi-stage build to reduce image size
- Standalone output mode for minimal dependencies
- Non-root user for security
- Optimized layer caching
