/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  // Optimize for Cloud Run
  compress: true,
  poweredByHeader: false,
}

module.exports = nextConfig
