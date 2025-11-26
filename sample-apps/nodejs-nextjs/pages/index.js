import { useState, useEffect } from 'react';
import Head from 'next/head';

export default function Home() {
  const [info, setInfo] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/info')
      .then(res => res.json())
      .then(data => {
        setInfo(data);
        setLoading(false);
      });
  }, []);

  return (
    <div style={styles.container}>
      <Head>
        <title>Cloud Run Next.js Sample</title>
        <meta name="description" content="Next.js app running on Cloud Run" />
      </Head>

      <main style={styles.main}>
        <h1 style={styles.title}>
          Hello from <span style={styles.highlight}>Cloud Run!</span>
        </h1>

        <p style={styles.description}>
          Next.js full-stack application with server-side rendering
        </p>

        {loading ? (
          <div style={styles.loading}>Loading...</div>
        ) : (
          <div style={styles.infoCard}>
            <h2>Service Information</h2>
            <div style={styles.infoGrid}>
              <div><strong>Framework:</strong> {info?.framework}</div>
              <div><strong>Version:</strong> {info?.version}</div>
              <div><strong>Service:</strong> {info?.environment?.service}</div>
              <div><strong>Revision:</strong> {info?.environment?.revision}</div>
            </div>
          </div>
        )}

        <div style={styles.features}>
          <h2>Features</h2>
          <ul>
            <li>✅ Server-side rendering (SSR)</li>
            <li>✅ API routes built-in</li>
            <li>✅ React 18 with hooks</li>
            <li>✅ Optimized for production</li>
            <li>✅ Fast refresh in development</li>
          </ul>
        </div>

        <div style={styles.links}>
          <a href="/api/info" style={styles.link}>View API →</a>
          <a href="/api/health" style={styles.link}>Health Check →</a>
        </div>
      </main>
    </div>
  );
}

const styles = {
  container: {
    minHeight: '100vh',
    padding: '0 0.5rem',
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
  },
  main: {
    padding: '5rem 0',
    flex: 1,
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    maxWidth: '800px',
  },
  title: {
    margin: 0,
    lineHeight: 1.15,
    fontSize: '4rem',
    textAlign: 'center',
  },
  highlight: {
    color: '#0070f3',
  },
  description: {
    textAlign: 'center',
    lineHeight: 1.5,
    fontSize: '1.5rem',
    marginTop: '1rem',
  },
  loading: {
    fontSize: '1.2rem',
    color: '#666',
    marginTop: '2rem',
  },
  infoCard: {
    marginTop: '2rem',
    padding: '2rem',
    backgroundColor: 'white',
    borderRadius: '8px',
    boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
    width: '100%',
  },
  infoGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: '1rem',
    marginTop: '1rem',
  },
  features: {
    marginTop: '2rem',
    padding: '2rem',
    backgroundColor: 'white',
    borderRadius: '8px',
    boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
    width: '100%',
  },
  links: {
    marginTop: '2rem',
    display: 'flex',
    gap: '1rem',
  },
  link: {
    padding: '1rem 2rem',
    backgroundColor: '#0070f3',
    color: 'white',
    textDecoration: 'none',
    borderRadius: '4px',
    fontWeight: 'bold',
  },
};
