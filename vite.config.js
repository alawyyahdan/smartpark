import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    hmr: {
      overlay: false
    }
  },
  optimizeDeps: {
    include: ['maplibre-gl']
  },
  build: {
    rollupOptions: {
      output: {
        // Pisahkan maplibre ke chunk tersendiri
        manualChunks: (id) => {
          if (id.includes('maplibre-gl')) return 'maplibre'
          if (id.includes('leaflet')) return 'leaflet'
        }
      }
    }
  }
})
