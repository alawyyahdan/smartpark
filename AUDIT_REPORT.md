# Full Code Audit Report — SmartPark-Web

> **Auditor:** Senior Code Reviewer (AI)
> **Tanggal:** 5 Mei 2026
> **Stack:** Vue.js 3 (Frontend) + Node.js (Backend/MQTT Bridge) + Supabase (DB)

---

## CRITICAL — Harus diperbaiki segera

### 1. RLS Policies terlalu permisif

- **File:** `migration.sql:142-187`
- **Masalah:** Semua tabel punya `FOR ALL TO anon USING (true) WITH CHECK (true)`. Anonymous user bisa **INSERT, UPDATE, DELETE** semua data termasuk `settings`, `gate_accounts`, `sessions`.
- **Fix:** Restrict anon ke SELECT-only pada kebanyakan tabel. Hanya allow INSERT/UPDATE pada `tickets` dan `parking_slots` (untuk visitor flow). Tabel admin (`settings`, `gate_accounts`, `mqtt_logs`) harus authenticated-only.

### 2. Password disimpan plaintext (ini boleh tapi sesuaikan di semua fungsinya MKSDNYA GANTI KE HASH TAPI YA SESUAIKAN JDI GADA ERROR PAS LOGIN BGST)

- **File:** `src/views/ExitGateView.vue:205`, `src/views/AdminView.vue` (saveGateAccount), `migration.sql:72`
- **Masalah:** Password gate account disimpan dan diquery sebagai plaintext: `.eq('password', loginForm.value.password)`.
- **Fix:** Hash password (bcrypt) via Supabase Edge Function/RPC. Rename kolom ke `password_hash`.

---

## HIGH Priority

### 3. Polling 500ms padahal komentar bilang 3 detik (ya ganti aja komentarnya jadi Real-time gw meng mau realtime)

- **File:** `src/views/AdminView.vue:~2535`
- **Masalah:** `setInterval(pollMqttState, 500)` — sangat agresif, memukul database terus-menerus.
- **Fix:** Ubah ke `3000` atau `5000`.

### 4. Memory leak: setInterval tanpa cleanup

- **File:** `src/views/TicketView.vue:369`
- **Masalah:** `setInterval(fetchSlots, 1000)` — interval ID tidak disimpan, tidak pernah di-clear di `onUnmounted`.
- **Fix:** Simpan interval ID dan clear di `onUnmounted`.

### 5. Dead function `applyAppBranding`

- **File:** `src/lib/supabase.js:9-27`
- **Masalah:** Fungsi ini **tidak pernah dimport/dipanggil** di manapun. Router punya versi sendiri (`applyBranding`) yang sudah ada caching.
- **Fix:** Hapus `applyAppBranding` dari `supabase.js`.

### 6. MQTT Bridge log cleanup setiap message

- **File:** `mqtt-bridge/bridge.cjs:34-39`
- **Masalah:** Setiap log message trigger `SELECT count(*)` + potential `DELETE` pada `mqtt_logs`. Sangat berat untuk high-throughput.
- **Fix:** Pindahkan cleanup ke periodic job (misal tiap 5 menit), bukan setiap log.

---

## MEDIUM Priority — Dead Code

### 7. Dead code di `AdminView.vue`


| Fungsi/Variable          | Keterangan                                         |
| ------------------------ | -------------------------------------------------- |
| `getMqttAddress()`       | Didefinisikan tapi tidak pernah dipanggil          |
| `updateSlotTopic()`      | Didefinisikan tapi tidak pernah dipanggil          |
| `calculatePrice()`       | Duplikat dari ExitGateView, tidak pernah dipanggil |
| `getUnitLabel()`         | Didefinisikan tapi tidak dipakai di template       |
| `editingGateAccount` ref | Dideklarasikan tapi tidak pernah digunakan         |


### 8. Dead code di `VisitorView.vue`


| Fungsi/Variable         | Keterangan                                                                   |
| ----------------------- | ---------------------------------------------------------------------------- |
| `confirmParking()`      | Tidak pernah dipanggil dari template (auto-park pakai `handleOccupiedYes()`) |
| `confirmingParking` ref | Tidak pernah digunakan                                                       |


### 9. Dead files (scaffold boilerplate)


| File                            | Keterangan                                                     |
| ------------------------------- | -------------------------------------------------------------- |
| `src/components/HelloWorld.vue` | Tidak dimport di manapun — sisa scaffold Vite                  |
| `src/style.css`                 | Tidak dimport di `main.js` atau file lain — sisa scaffold Vite |


---

## MEDIUM Priority — Duplicate Code

### 10. Slot geometry calculation — 4 file copy-paste

Kalkulasi corner rotation (`METER_TO_DEG`, sin/cos) identik di:

- `ParkingMap.vue:217-230`
- `ParkingMap3D.vue:244-258`
- `AdminSlotMap.vue:120-138`
- `SlotMapPicker.vue:144-155`

> **Fix:** Extract ke `src/lib/geo.js` → `computeSlotCorners(lat, lng, rotation, width, height)`

### 11. `calcHeading()` — duplikat di 2 file

Identik di `ParkingMap.vue` dan `ParkingMap3D.vue`.

> **Fix:** Extract ke `src/lib/geo.js`

### 12. Favicon/branding setup — duplikat di 5+ file

Pattern `document.querySelector("link[rel~='icon']")...` di-copy-paste di semua view.

> **Fix:** Buat composable `src/composables/useBranding.js`

### 13. Formatting functions — duplikat di 3+ file

`formatDateTime()`, `formatNumber()`, `getStatusLabel()`, `getUnitLabel()` duplikat di AdminView, VisitorView, ExitGateView.

> **Fix:** Extract ke `src/lib/formatters.js`

### 14. Pricing logic — duplikat di 2 file

`calcPrice()` di ExitGateView dan `calculatePrice()` di AdminView (yang bahkan dead code).

> **Fix:** Extract ke `src/lib/pricing.js`

### 15. Default settings array — 3x copy-paste dalam AdminView

Array `defaults` untuk reset settings di-copy 3 kali di `resetSettings()`, `resetSemua()`, `hapusSemua()`.

> **Fix:** Extract ke `const DEFAULT_SETTINGS` di module level.

---

## MEDIUM Priority — Error Handling

### 16. Router `beforeEach` tanpa try/catch

- **File:** `src/router/index.js:96-106`
- **Masalah:** Jika `applyBranding()` throw (network error), seluruh navigasi rusak.
- **Fix:** Wrap dalam try/catch.

### 17. Supabase client tanpa validasi env

- **File:** `src/lib/supabase.js:5`
- **Masalah:** Jika `VITE_SUPABASE_URL` undefined, `createClient(undefined, undefined)` throw error cryptic.
- **Fix:** Tambah guard: `if (!supabaseUrl || !supabaseAnonKey) throw new Error('Missing Supabase env vars')`

### 18. `processExit()` catch block kosong

- **File:** `src/views/ExitGateView.vue:376-378`
- **Masalah:** Error ditangkap tapi tidak ditampilkan ke user.
- **Fix:** Tampilkan error message.

### 19. ParkingMap3D route fetch error silenced

- **File:** `src/components/ParkingMap3D.vue:321`
- **Masalah:** Catch block menelan error tanpa logging.
- **Fix:** Tambah `console.warn`.

### 20. `bridge.cjs` SIGINT/SIGTERM race condition

- **File:** `mqtt-bridge/bridge.cjs:215-216`
- **Masalah:** `process.exit(0)` bisa fire sebelum `await` selesai.
- **Fix:** Pastikan semua await selesai sebelum exit.

---

## MEDIUM Priority — Resource Leaks

### 21. ResizeObserver tidak di-disconnect — 4 komponen

File yang terdampak:

- `src/components/ParkingMap.vue`
- `src/components/AdminSlotMap.vue`
- `src/components/SlotMapPicker.vue`
- `src/components/MapCenterPicker.vue`

Semua buat `ResizeObserver` tapi tidak pernah `.disconnect()` di `onUnmounted`.

> **Fix:** Simpan reference dan disconnect di cleanup.

---

## LOW Priority — Magic Numbers & Hardcoded Values

### 22. Default koordinat hardcoded di 5+ file

`-7.2650876, 112.783217` muncul di banyak tempat.

> **Fix:** Buat shared constant `DEFAULT_LAT`, `DEFAULT_LNG` di `src/lib/constants.js`

### 23. `METER_TO_DEG` didefinisikan lokal di 4 file

> **Fix:** Pindah ke `src/lib/geo.js`

### 24. Hardcoded `localhost:5173`

- **File:** `src/lib/ticketGenerator.js:23,38`
- **Masalah:** Default `appUrl` mengarah ke localhost. Di production bisa generate QR yang salah.
- **Fix:** Hapus default atau pakai env var.

### 25. Falsy-zero bug

- **File:** `src/components/SlotMapPicker.vue:109`
- **Masalah:** `if (!lat || !lng)` — koordinat `0` (equator/prime meridian) dianggap falsy.
- **Fix:** Gunakan `if (lat == null || lng == null)` atau `isNaN()`.

### 26. `bridge.cjs` magic numbers

`200` (max logs), `5000` (reconnect), `10000` (connect timeout), `60000` (status report), `5` (message batch) — semua inline.

> **Fix:** Extract ke named constants di top file.

### 27. CameraCapture magic numbers

- **File:** `src/components/CameraCapture.vue`
- **Masalah:** `1280x720` (resolusi), `0.85` (JPEG quality), `200` (flash duration) hardcoded.
- **Fix:** Extract ke named constants.

### 28. Dead emit

- **File:** `src/components/CameraCapture.vue:59`
- **Masalah:** `defineEmits(['captured'])` dideklarasikan tapi event `'captured'` tidak pernah di-emit.
- **Fix:** Hapus atau implementasikan.

---

## LOW Priority — File Terlalu Besar

### 29. `AdminView.vue` — ~2837 baris

Satu file menangani dashboard, tickets, slots, areas, gates, accounts, MQTT, settings, danger zone.

> **Fix:** Pecah ke composables: `useTickets()`, `useSlots()`, `useAreas()`, `useMqtt()`, `useDangerZone()`, `useGates()`

### 30. `VisitorView.vue` — ~2934 baris

Satu file menangani GPS, ticket, slot locking, idle timer, exit mode, debug.

> **Fix:** Pecah ke composables: `useGps()`, `useSlotLocking()`, `useIdleTimer()`, `useExitMode()`

---

## LOW Priority — Naming & Consistency

### 31. Empty conditional block

- **File:** `mqtt-bridge/bridge.cjs:177-179`
- **Masalah:** Block kosong, hanya komentar:
  ```js
  if (enabled && mqttClient && !mqttClient.connected) {
    // mqttClient handles reconnect automatically
  }
  ```
- **Fix:** Hapus block ini.

### 32. Section numbering kacau di migration

- **File:** `migration.sql`
- **Masalah:** Ada dua "section 6", numbering lompat-lompat (6, 8, 9, 10, 11 tapi urutan salah).
- **Fix:** Renumber secara sequential.

### 33. Import terpisah

- **File:** `src/views/LoginView.vue:68`
- **Masalah:** `onMounted` dimport di baris terpisah dari `ref`.
- **Fix:** Gabung: `import { ref, onMounted } from 'vue'`

---

## Ringkasan


| Priority     | Jumlah | Item Kunci                                                                               |
| ------------ | ------ | ---------------------------------------------------------------------------------------- |
| **CRITICAL** | 2      | RLS anon full access, plaintext password                                                 |
| **HIGH**     | 4      | Polling 500ms, memory leak interval, dead `applyAppBranding`, MQTT log cleanup           |
| **MEDIUM**   | 15     | Dead code (7 fungsi), duplicate code (6 pattern), error handling (4), resource leaks (4) |
| **LOW**      | 12     | Magic numbers, file size, naming, scaffold files                                         |


**Total: 33 temuan**