import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    // In dev, proxy API calls to the local NestJS server
    proxy: { '/api': 'http://localhost:3000' },
  },
});
