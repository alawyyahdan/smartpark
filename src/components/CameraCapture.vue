<template>
  <div class="camera-capture">
    <div class="camera-box" :class="{ 'camera-capturing': isCapturing }">
      <video 
        ref="videoRef" 
        autoplay 
        playsinline
        class="camera-video"
        :class="{ 'camera-hidden': !isStreaming }"
      ></video>
      
      <canvas 
        ref="canvasRef" 
        class="camera-canvas"
        :class="{ 'camera-visible': capturedImage }"
      ></canvas>

      <!-- Overlay saat tidak ada stream -->
      <div v-if="!isStreaming && !error" class="camera-loading">
        <div class="camera-spinner"></div>
        <p>Mengaktifkan kamera...</p>
      </div>

      <!-- Error state -->
      <div v-if="error" class="camera-error">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/>
          <line x1="1" y1="1" x2="23" y2="23"/>
        </svg>
        <p>{{ error }}</p>
      </div>

      <!-- Capture flash effect -->
      <div v-if="isCapturing" class="camera-flash"></div>

      <!-- Frame overlay -->
      <div class="camera-frame" v-if="isStreaming && !capturedImage">
        <div class="frame-corner tl"></div>
        <div class="frame-corner tr"></div>
        <div class="frame-corner bl"></div>
        <div class="frame-corner br"></div>
      </div>
    </div>

    <!-- Camera info -->
    <div class="camera-info" v-if="isStreaming && !capturedImage">
      <div class="camera-status">
        <span class="status-dot"></span>
        <span>Kamera Aktif</span>
      </div>
      <p class="camera-hint">Posisikan kendaraan di dalam frame</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const emit = defineEmits(['captured'])

const videoRef = ref(null)
const canvasRef = ref(null)
const stream = ref(null)
const isStreaming = ref(false)
const isCapturing = ref(false)
const capturedImage = ref(null)
const error = ref('')

async function startCamera() {
  try {
    error.value = ''
    
    // Request camera access
    const mediaStream = await navigator.mediaDevices.getUserMedia({
      video: {
        width: { ideal: 1280 },
        height: { ideal: 720 },
        facingMode: 'environment' // Prefer back camera on mobile
      },
      audio: false
    })

    stream.value = mediaStream
    
    if (videoRef.value) {
      videoRef.value.srcObject = mediaStream
      
      // Wait for video to be ready
      videoRef.value.onloadedmetadata = () => {
        isStreaming.value = true
      }
    }
  } catch (err) {
    console.error('Camera error:', err)
    if (err.name === 'NotAllowedError') {
      error.value = 'Akses kamera ditolak. Mohon izinkan akses kamera.'
    } else if (err.name === 'NotFoundError') {
      error.value = 'Kamera tidak ditemukan pada perangkat ini.'
    } else {
      error.value = 'Gagal mengakses kamera.'
    }
  }
}

async function captureImage() {
  if (!videoRef.value || !canvasRef.value || !isStreaming.value) return null

  isCapturing.value = true

  // Set canvas size to match video
  const video = videoRef.value
  const canvas = canvasRef.value
  canvas.width = video.videoWidth
  canvas.height = video.videoHeight

  // Draw video frame to canvas
  const ctx = canvas.getContext('2d')
  ctx.drawImage(video, 0, 0, canvas.width, canvas.height)

  // Get image as blob
  return new Promise((resolve) => {
    canvas.toBlob((blob) => {
      // Also get data URL for preview
      const dataUrl = canvas.toDataURL('image/jpeg', 0.85)
      capturedImage.value = dataUrl
      
      // Flash effect
      setTimeout(() => {
        isCapturing.value = false
      }, 200)

      resolve({ blob, dataUrl })
    }, 'image/jpeg', 0.85)
  })
}

function stopCamera() {
  if (stream.value) {
    stream.value.getTracks().forEach(track => track.stop())
    stream.value = null
    isStreaming.value = false
  }
}

// Expose capture method to parent
defineExpose({
  captureImage,
  stopCamera
})

onMounted(() => {
  startCamera()
})

onUnmounted(() => {
  stopCamera()
})
</script>

<style scoped>
.camera-capture {
  width: 100%;
}

.camera-box {
  position: relative;
  width: 100%;
  aspect-ratio: 16 / 9;
  background: #000;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 8px 32px rgba(0,0,0,0.4);
}

.camera-video,
.camera-canvas {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: opacity 0.3s ease;
}

.camera-video {
  opacity: 1;
}

.camera-video.camera-hidden {
  opacity: 0;
}

.camera-canvas {
  opacity: 0;
  pointer-events: none;
}

.camera-canvas.camera-visible {
  opacity: 1;
}

/* Loading state */
.camera-loading {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: #94a3b8;
  font-size: 14px;
}

.camera-spinner {
  width: 40px;
  height: 40px;
  border: 3px solid rgba(99,102,241,0.2);
  border-top-color: #6366f1;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

/* Error state */
.camera-error {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: #f87171;
  font-size: 13px;
  text-align: center;
  padding: 20px;
}

.camera-error svg {
  opacity: 0.5;
}

/* Flash effect */
.camera-flash {
  position: absolute;
  inset: 0;
  background: white;
  animation: flash 0.2s ease-out;
  pointer-events: none;
}

@keyframes flash {
  0% { opacity: 0; }
  50% { opacity: 0.8; }
  100% { opacity: 0; }
}

/* Frame overlay */
.camera-frame {
  position: absolute;
  inset: 20px;
  pointer-events: none;
}

.frame-corner {
  position: absolute;
  width: 40px;
  height: 40px;
  border: 3px solid #6366f1;
  opacity: 0.6;
}

.frame-corner.tl {
  top: 0;
  left: 0;
  border-right: none;
  border-bottom: none;
  border-top-left-radius: 8px;
}

.frame-corner.tr {
  top: 0;
  right: 0;
  border-left: none;
  border-bottom: none;
  border-top-right-radius: 8px;
}

.frame-corner.bl {
  bottom: 0;
  left: 0;
  border-right: none;
  border-top: none;
  border-bottom-left-radius: 8px;
}

.frame-corner.br {
  bottom: 0;
  right: 0;
  border-left: none;
  border-top: none;
  border-bottom-right-radius: 8px;
}

/* Camera info */
.camera-info {
  margin-top: 12px;
  text-align: center;
}

.camera-status {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px;
  background: rgba(16,185,129,0.1);
  border: 1px solid rgba(16,185,129,0.2);
  border-radius: 100px;
  font-size: 13px;
  color: #34d399;
  font-weight: 600;
  margin-bottom: 6px;
}

.status-dot {
  width: 8px;
  height: 8px;
  background: #34d399;
  border-radius: 50%;
  animation: pulse 2s ease infinite;
}

.camera-hint {
  font-size: 12px;
  color: #64748b;
  margin-top: 4px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
</style>
