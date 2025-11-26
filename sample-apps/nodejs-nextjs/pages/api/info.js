export default function handler(req, res) {
  res.status(200).json({
    framework: 'Next.js',
    language: 'Node.js + React',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    environment: {
      service: process.env.K_SERVICE || 'local',
      revision: process.env.K_REVISION || 'dev',
      port: process.env.PORT || '8080',
      nodeVersion: process.version,
    },
    features: [
      'Server-side rendering (SSR)',
      'API routes',
      'React 18',
      'Optimized builds',
      'Fast refresh'
    ]
  });
}
