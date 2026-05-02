# Setup Fitur Kamera & Auto-Close QR

## Fitur yang Ditambahkan

### 1. **Kamera Real-time di Halaman Ticket**
- Webcam preview real-time dengan frame overlay
- Auto-capture foto kendaraan saat klik "Ambil Tiket"
- Upload otomatis ke Supabase Storage
- Flash effect saat capture

### 2. **Auto-Close QR Code**
- QR code otomatis tertutup saat visitor membuka link
- Menggunakan Supabase Realtime Broadcast
- Tidak perlu menunggu countdown 20 detik

### 3. **Storage Foto Kendaraan**
- Foto disimpan di Supabase Storage bucket `vehicle-images`
- URL foto tersimpan di field `vehicle_image` pada tabel `tickets`

---

## Setup Supabase

### 1. Jalankan Migration SQL

Buka **Supabase Dashboard** → **SQL Editor**, lalu jalankan file `migration.sql` yang sudah diupdate:

```sql
-- Pastikan kolom vehicle_image sudah ada di tabel tickets
ALTER TABLE public.tickets ADD COLUMN IF NOT EXISTS vehicle_image TEXT;

-- Buat storage bucket untuk foto kendaraan
INSERT INTO storage.buckets (id, name, public)
VALUES ('vehicle-images', 'vehicle-images', true)
ON CONFLICT (id) DO NOTHING;

-- Policy untuk upload dan read
CREATE POLICY "Allow public upload" ON storage.objects
  FOR INSERT TO anon WITH CHECK (bucket_id = 'vehicle-images');

CREATE POLICY "Allow public read" ON storage.objects
  FOR SELECT TO anon USING (bucket_id = 'vehicle-images');
```

### 2. Enable Realtime Broadcast

Di **Supabase Dashboard** → **Database** → **Replication**:
- Pastikan **Realtime** sudah enabled
- Tidak perlu enable replication untuk tabel (kita pakai Broadcast, bukan Database Changes)

Atau via SQL:
```sql
-- Realtime broadcast tidak perlu konfigurasi khusus
-- Sudah otomatis aktif di Supabase
```

### 3. Verifikasi Storage Bucket

Di **Supabase Dashboard** → **Storage**:
- Pastikan bucket `vehicle-images` sudah ada
- Set sebagai **Public bucket** agar foto bisa diakses via URL
- Atau buat manual via UI jika belum ada

---

## Setup Environment Variables

Pastikan file `.env` sudah berisi:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
VITE_APP_URL=http://localhost:5173
```

Untuk production, ganti `VITE_APP_URL` dengan domain production Anda.

---

## Cara Kerja

### Flow Lengkap:

1. **Operator di /ticket**:
   - Kamera webcam aktif otomatis
   - Preview real-time dengan frame overlay
   - Klik "Ambil Tiket"

2. **Auto-capture & Upload**:
   - Sistem capture frame dari webcam
   - Upload foto ke Supabase Storage (`vehicle-images` bucket)
   - Simpan URL foto ke database (`tickets.vehicle_image`)
   - Generate QR code dengan link `/visitor?t={ticket_id}`

3. **QR Code Display**:
   - QR muncul di layar kiosk
   - Countdown 20 detik dimulai
   - Sistem subscribe ke Realtime channel `ticket-{id}`

4. **Visitor Scan QR**:
   - Visitor buka link di HP
   - VisitorView load data tiket
   - **Broadcast event** `ticket_accessed` ke channel
   - Kiosk menerima event → **Auto close QR**

5. **Auto Close**:
   - QR screen tertutup otomatis
   - Kembali ke welcome screen
   - Kamera tetap aktif untuk tiket berikutnya

---

## Testing

### Test Kamera:
```bash
npm run dev
```

1. Buka `http://localhost:5173/ticket`
2. Izinkan akses kamera saat browser meminta
3. Pastikan preview kamera muncul dengan frame overlay
4. Klik "Ambil Tiket"
5. Lihat flash effect saat capture

### Test Auto-Close:
1. Setelah QR muncul, scan dengan HP atau buka link manual
2. Copy URL dari "Debug URL" di QR screen
3. Buka di tab/device lain
4. QR di kiosk harus langsung tertutup

### Test Upload Storage:
1. Setelah generate tiket, cek Supabase Dashboard → Storage → `vehicle-images`
2. Pastikan ada file foto baru dengan format `{timestamp}-{random}.jpg`
3. Klik file untuk preview
4. Copy public URL dan pastikan bisa diakses

---

## Troubleshooting

### Kamera tidak muncul:
- Pastikan browser sudah diberi izin akses kamera
- Cek console browser untuk error
- Coba refresh halaman
- Pastikan tidak ada aplikasi lain yang pakai kamera

### Upload gagal:
- Cek Supabase Storage bucket `vehicle-images` sudah dibuat
- Pastikan RLS policy sudah benar
- Cek console untuk error upload
- Verifikasi `VITE_SUPABASE_URL` dan `VITE_SUPABASE_ANON_KEY`

### Auto-close tidak jalan:
- Pastikan Realtime sudah enabled di Supabase
- Cek console browser untuk error subscription
- Pastikan kedua tab (kiosk & visitor) terbuka bersamaan
- Coba refresh kedua halaman

### CORS error saat upload:
- Pastikan bucket `vehicle-images` di-set sebagai **public**
- Cek CORS settings di Supabase Storage
- Verifikasi domain di Supabase Dashboard → Settings → API

---

## Konfigurasi Kamera

Untuk mengubah resolusi atau facing mode kamera, edit `src/components/CameraCapture.vue`:

```javascript
const mediaStream = await navigator.mediaDevices.getUserMedia({
  video: {
    width: { ideal: 1280 },    // Ubah resolusi
    height: { ideal: 720 },
    facingMode: 'environment'  // 'user' untuk front camera
  },
  audio: false
})
```

### Untuk CCTV/IP Camera:

Jika ingin connect ke CCTV, ganti `getUserMedia` dengan stream dari RTSP/MJPEG:

```javascript
// Contoh untuk MJPEG stream
const img = new Image()
img.src = 'http://your-cctv-ip/mjpeg'
// Draw img ke canvas secara interval
```

Atau gunakan library seperti `jsmpeg` untuk RTSP stream.

---

## Production Checklist

- [ ] Update `VITE_APP_URL` ke domain production
- [ ] Set proper CORS di Supabase
- [ ] Enable HTTPS untuk akses kamera (required by browser)
- [ ] Set storage retention policy untuk auto-delete old images
- [ ] Implement image compression sebelum upload
- [ ] Add error tracking (Sentry, etc)
- [ ] Test di berbagai browser (Chrome, Firefox, Safari)
- [ ] Test di mobile devices
- [ ] Set proper RLS policies untuk production (jangan pakai `anon` untuk semua)

---

## Next Steps

Fitur yang bisa ditambahkan:
- [ ] ANPR (Automatic Number Plate Recognition) dari foto
- [ ] Image compression sebelum upload
- [ ] Multiple camera support
- [ ] Manual retake foto
- [ ] Preview foto di QR screen
- [ ] Admin dashboard untuk lihat semua foto
- [ ] Auto-delete foto setelah X hari
- [ ] Watermark pada foto
