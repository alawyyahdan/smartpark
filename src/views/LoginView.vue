<template>
  <div class="login-page">
    <div class="login-card">
      <div class="login-header">
        <div class="login-logo">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="11" width="18" height="11" rx="2"/>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
          </svg>
        </div>
        <h1>{{ appName }} Admin</h1>
        <p>Masuk untuk mengakses dashboard</p>
      </div>

      <form @submit.prevent="handleLogin" class="login-form">
        <div class="form-group">
          <label for="email">Email</label>
          <input 
            type="email" 
            id="email"
            v-model="email" 
            placeholder="admin@smartpark.com"
            required
            :disabled="loading"
          />
        </div>

        <div class="form-group">
          <label for="password">Password</label>
          <input 
            type="password" 
            id="password"
            v-model="password" 
            placeholder="••••••••"
            required
            :disabled="loading"
          />
        </div>

        <button type="submit" class="btn-login" :disabled="loading">
          <span v-if="loading" class="spinner"></span>
          <span v-else>Masuk</span>
        </button>

        <p v-if="error" class="error-msg">{{ error }}</p>
      </form>

      <div class="login-footer">
        <p>{{ appName }} v1.0 — Sistem Parkir Cerdas</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase.js'
import { friendlyError } from '../lib/errorMessages.js'
import { applyFavicon, applyTitle } from '../lib/branding.js'

const router = useRouter()

const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')
const appName = ref('SmartPark')

onMounted(async () => {
  const { data } = await supabase.from('settings').select('key, value').in('key', ['app_name', 'app_favicon'])
  if (data) {
    data.forEach(s => {
      if (s.key === 'app_name' && s.value) {
        appName.value = s.value
        applyTitle(s.value, '— Login Admin')
      }
      if (s.key === 'app_favicon' && s.value) applyFavicon(s.value)
    })
  }
})

async function handleLogin() {
  error.value = ''
  loading.value = true

  try {
    const { data, error: authError } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })

    if (authError) throw authError

    // Redirect to admin
    const adminPath = import.meta.env.VITE_ADMIN_PATH || '/admin'
    router.push(adminPath)
  } catch (err) {
    error.value = friendlyError(err) || 'Login gagal. Periksa email dan password Anda.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  background: radial-gradient(ellipse at top, #1a1f3a 0%, #0a0f1e 60%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  position: relative;
}

.login-page::before {
  content: '';
  position: fixed;
  inset: 0;
  background-image: radial-gradient(circle, rgba(99,102,241,.08) 1px, transparent 1px);
  background-size: 40px 40px;
  pointer-events: none;
}

.login-card {
  background: rgba(17,24,39,.9);
  border: 1px solid rgba(99,102,241,.3);
  border-radius: 24px;
  padding: 48px;
  max-width: 420px;
  width: 100%;
  box-shadow: 0 32px 80px rgba(0,0,0,.6);
  backdrop-filter: blur(20px);
  position: relative;
  z-index: 1;
}

.login-header {
  text-align: center;
  margin-bottom: 32px;
}

.login-logo {
  width: 80px;
  height: 80px;
  margin: 0 auto 20px;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.login-header h1 {
  font-size: 28px;
  font-weight: 900;
  color: #f1f5f9;
  margin-bottom: 8px;
  letter-spacing: -0.02em;
}

.login-header p {
  font-size: 14px;
  color: #64748b;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 13px;
  font-weight: 600;
  color: #94a3b8;
}

.form-group input {
  padding: 12px 16px;
  background: rgba(255,255,255,.04);
  border: 1px solid rgba(255,255,255,.08);
  border-radius: 12px;
  color: #f1f5f9;
  font-size: 14px;
  outline: none;
  transition: all 0.2s;
  font-family: var(--font);
}

.form-group input::placeholder {
  color: #475569;
}

.form-group input:focus {
  border-color: #6366f1;
  box-shadow: 0 0 0 3px rgba(99,102,241,0.15);
}

.form-group input:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-login {
  padding: 14px 24px;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  margin-top: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.btn-login:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(99,102,241,0.4);
}

.btn-login:active:not(:disabled) {
  transform: translateY(0);
}

.btn-login:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.spinner {
  width: 18px;
  height: 18px;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}

.error-msg {
  padding: 12px 16px;
  background: rgba(239,68,68,0.1);
  border: 1px solid rgba(239,68,68,0.3);
  border-radius: 10px;
  color: #f87171;
  font-size: 13px;
  text-align: center;
}

.login-footer {
  margin-top: 32px;
  padding-top: 24px;
  border-top: 1px solid rgba(255,255,255,0.08);
  text-align: center;
}

.login-footer p {
  font-size: 12px;
  color: #475569;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
