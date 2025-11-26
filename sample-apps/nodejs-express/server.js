const express = require('express');
const app = express();

// Middleware
app.use(express.json());

// Home endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Cloud Run!',
    framework: 'Express',
    language: 'Node.js',
    timestamp: new Date().toISOString(),
    service: process.env.K_SERVICE || 'local',
    revision: process.env.K_REVISION || 'dev'
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Info endpoint
app.get('/api/info', (req, res) => {
  res.json({
    service: 'Express Sample App',
    version: '1.0.0',
    endpoints: {
      '/': 'Home page',
      '/health': 'Health check',
      '/api/info': 'Service information'
    },
    environment: {
      port: process.env.PORT || '8080',
      service: process.env.K_SERVICE || 'local',
      revision: process.env.K_REVISION || 'dev',
      nodeVersion: process.version
    }
  });
});

// Echo endpoint (POST)
app.post('/api/echo', (req, res) => {
  res.json({
    received: req.body,
    timestamp: new Date().toISOString()
  });
});

// Start server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
