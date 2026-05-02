<template>
  <teleport to="body">
    <div class="toast-container">
      <transition-group name="toast-slide" tag="div" class="toast-stack">
        <div v-for="t in toasts" :key="t.id" class="toast" :class="t.type">
          <svg v-if="t.type === 'success'" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <path d="M20 6 9 17l-5-5"/>
          </svg>
          <svg v-else-if="t.type === 'error'" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>
          </svg>
          <svg v-else width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>
          </svg>
          <span>{{ t.message }}</span>
          <button class="toast-close" @click="removeToast(t.id)">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
      </transition-group>
    </div>
  </teleport>

  <div class="admin-page">
    
    <!-- Header -->
    <header class="admin-header">
      <div class="admin-logo">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <rect x="3" y="11" width="18" height="11" rx="2"/>
          <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
        </svg>
        <span>{{ settings.app_name || 'SmartPark' }} Admin</span>
      </div>
      
      <div class="header-actions">
        <!-- Debug Mode Toggle -->
        <div class="debug-toggle">
          <label class="toggle-label">
            <input type="checkbox" v-model="debugMode" @change="toggleDebugMode" />
            <span class="toggle-slider"></span>
            <span class="toggle-text">Debug Mode</span>
          </label>
        </div>

        <!-- Logout Button -->
        <button class="btn-logout" @click="handleLogout">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
            <polyline points="16 17 21 12 16 7"/>
            <line x1="21" y1="12" x2="9" y2="12"/>
          </svg>
          Keluar
        </button>
      </div>
    </header>

    <!-- Tabs Navigation -->
    <nav class="tabs-nav">
      <button 
        v-for="tab in tabs" 
        :key="tab.id"
        class="tab-btn"
        :class="{ active: activeTab === tab.id }"
        @click="activeTab = tab.id"
      >
        <component :is="tab.icon" />
        {{ tab.label }}
      </button>
    </nav>

    <!-- Tab Content -->
    <div class="tab-content">
      
      <!-- TAB 1: Dashboard -->
      <div v-show="activeTab === 'dashboard'" class="tab-panel">
        <!-- Stats Cards -->
        <section class="stats-section">
      <div class="stat-card">
        <div class="stat-icon stat-blue">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2Z"/>
          </svg>
        </div>
        <div class="stat-content">
          <span class="stat-label">Tiket Hari Ini</span>
          <span class="stat-value">{{ stats.todayTickets }}</span>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon stat-yellow">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 6H5a2 2 0 0 0-2 2v3a2 2 0 0 0 2 2h13l4-3.5L18 6Z"/>
          </svg>
        </div>
        <div class="stat-content">
          <span class="stat-label">Sedang Parkir</span>
          <span class="stat-value">{{ stats.currentlyParked }}</span>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon stat-green">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="11" width="18" height="11" rx="2"/>
          </svg>
        </div>
        <div class="stat-content">
          <span class="stat-label">Slot Tersedia</span>
          <span class="stat-value">{{ stats.availableSlots }}</span>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon stat-purple">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
          </svg>
        </div>
        <div class="stat-content">
          <span class="stat-label">Pendapatan</span>
          <span class="stat-value">Rp {{ formatNumber(stats.todayRevenue) }}</span>
        </div>
      </div>
    </section>



      </div><!-- End Dashboard Tab -->

      <!-- TAB 2: Data Parkir -->
      <div v-show="activeTab === 'tickets'" class="tab-panel">
        
    <!-- Filters & Search -->
    <section class="filters-section">
      <div class="filter-group">
        <button 
          v-for="status in statusFilters" 
          :key="status.value"
          class="filter-btn"
          :class="{ active: filterStatus === status.value }"
          @click="filterStatus = status.value"
        >
          {{ status.label }}
        </button>
      </div>

      <input 
        type="text" 
        v-model="searchQuery" 
        placeholder="Cari tiket..."
        class="search-input"
      />
    </section>

    <!-- Tickets Table -->
    <section class="table-section">
      <div class="table-header">
        <h2>Data Parkir</h2>
        <button class="btn-refresh" @click="fetchTickets">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>
          </svg>
          Refresh
        </button>
      </div>

      <div class="table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>Foto</th>
              <th>Kode Tiket</th>
              <th>Status</th>
              <th>Slot</th>
              <th>Masuk</th>
              <th>Keluar</th>
              <th>Durasi</th>
              <th>Pendapatan</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="ticket in paginatedTickets" :key="ticket.id">
              <td>
                <div class="ticket-image" @click="viewImage(ticket.vehicle_image)" v-if="ticket.vehicle_image">
                  <img :src="ticket.vehicle_image" alt="Vehicle" />
                </div>
                <span v-else class="no-image">—</span>
              </td>
              <td><span class="ticket-code">{{ ticket.ticket_code }}</span></td>
              <td><span class="status-badge" :class="`status-${ticket.status}`">{{ getStatusLabel(ticket.status) }}</span></td>
              <td>{{ ticket.slot_name || '—' }}</td>
              <td>{{ formatDateTime(ticket.created_at) }}</td>
              <td>{{ ticket.exited_at ? formatDateTime(ticket.exited_at) : '—' }}</td>
              <td>{{ ticket.duration || '—' }}</td>
              <td><span v-if="ticket.cost" class="ticket-cost">Rp {{ formatNumber(ticket.cost) }}</span><span v-else>—</span></td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div class="pagination">
        <button @click="currentPage--" :disabled="currentPage === 1" class="page-btn">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="15 18 9 12 15 6"/>
          </svg>
        </button>
        <span class="page-info">Halaman {{ currentPage }} dari {{ totalPages }}</span>
        <button @click="currentPage++" :disabled="currentPage === totalPages" class="page-btn">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="9 18 15 12 9 6"/>
          </svg>
        </button>
      </div>
    </section>

      </div><!-- End Data Parkir Tab -->

      <!-- TAB 3: Slot Management -->
      <div v-show="activeTab === 'slots'" class="tab-panel">

    <!-- Slot Management -->
    <section class="slots-section">
      <div class="slots-header">
        <h2>Manajemen Slot Parkir</h2>
        <button class="btn-add-area" @click="openAddArea">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          Tambah Area
        </button>
      </div>

      <!-- Live Map - semua slot real-time -->
      <AdminSlotMap 
        :slots="slots" 
        :centerLat="parseFloat(settings.default_lat) || -7.2650876"
        :centerLng="parseFloat(settings.default_lng) || 112.783217"
      />

      <!-- Areas List -->
      <div v-if="areas.length === 0" class="empty-state">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <rect x="3" y="11" width="18" height="11" rx="2"/>
          <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
        </svg>
        <p>Belum ada area parkir</p>
        <button class="btn-primary-sm" @click="openAddArea">Tambah Area Pertama</button>
      </div>

      <div v-else class="areas-list">
        <!-- Unassigned Slots (slot tanpa area) -->
        <div v-if="unassignedSlots.length > 0" class="area-card unassigned-area">
          <div class="area-header">
            <div class="area-info">
              <h3>⚠️ Slot Belum Dikelompokkan</h3>
              <p class="area-desc">Slot ini belum masuk ke area manapun. Assign ke area atau buat area baru.</p>
              <span class="area-stats">{{ unassignedSlots.length }} slot</span>
            </div>
          </div>

          <!-- Unassigned Slots Grid -->
          <div class="slots-grid">
            <div 
              v-for="slot in unassignedSlots" 
              :key="slot.id"
              class="slot-card"
              :class="{ occupied: slot.status === 'occupied' }"
              @click="editSlot(slot)"
            >
              <div class="slot-top">
                <div class="slot-led" :class="slot.status === 'available' ? 'led-green' : 'led-red'"></div>
                <div class="slot-name">{{ slot.name }}</div>
              </div>
              <div class="slot-status-text" :class="slot.status === 'available' ? 'text-green' : 'text-red'">
                {{ slot.status === 'available' ? 'Kosong' : 'Terisi' }}
              </div>
            </div>
          </div>
        </div>

        <!-- Areas with Slots -->
        <div v-for="area in areas" :key="area.id" class="area-card">
          <div class="area-header">
            <div class="area-info">
              <h3>{{ area.name }}</h3>
              <p class="area-desc">{{ area.description || area.floor }}</p>
              <div class="area-meta">
                <span class="area-stats">{{ getAreaSlotCount(area.id) }} slot</span>
                <span v-if="area.mqtt_prefix" class="area-mqtt-badge">
                  <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                  </svg>
                  {{ area.mqtt_prefix }}*
                </span>
                <span v-else class="area-mqtt-badge area-mqtt-empty">
                  <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                  </svg>
                  Prefix belum diset
                </span>
              </div>
            </div>
            <div class="area-actions">
              <button class="btn-icon" @click="editArea(area)" title="Edit Area">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
              </button>
              <button class="btn-icon btn-add-slot" @click="addSlotToArea(area)" title="Tambah Slot">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
                </svg>
              </button>
              <button class="btn-icon btn-delete" @click="deleteArea(area)" title="Hapus Area">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                </svg>
              </button>
            </div>
          </div>

          <!-- Slots Grid -->
          <div class="slots-grid">
            <div 
              v-for="slot in getSlotsByArea(area.id)" 
              :key="slot.id"
              class="slot-card"
              :class="{ occupied: slot.status === 'occupied', 'slot-debug': debugMode }"
              @click="debugMode ? debugToggleSlot(slot) : editSlot(slot)"
            >
              <div class="slot-top">
                <div class="slot-led" :class="slot.status === 'available' ? 'led-green' : 'led-red'"></div>
                <div class="slot-name">{{ slot.name }}</div>
              </div>
              <div class="slot-status-text" :class="slot.status === 'available' ? 'text-green' : 'text-red'">
                {{ slot.status === 'available' ? 'Kosong' : 'Terisi' }}
              </div>
              <div class="slot-meta">
                <span v-if="slot.lat && slot.lng" class="slot-coord-badge">
                  <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>
                  </svg>
                  GPS
                </span>
                <span v-else class="slot-coord-badge no-gps">No GPS</span>
                <span class="slot-mqtt-badge" v-if="slot.mqtt_topic">
                  <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                  </svg>
                </span>
              </div>
              <div v-if="debugMode" class="slot-debug-badge">click = toggle</div>
            </div>
          </div>
        </div>
      </div>
    </section>

      </div><!-- End Slot Management Tab -->

      <!-- TAB: Gate Keluar -->
      <div v-show="activeTab === 'gates'" class="tab-panel">
        <section class="settings-section">
          <div class="slots-header">
            <h2>Gate Keluar</h2>
            <button class="btn-add-area" @click="openAddGate">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
              </svg>
              Tambah Gate
            </button>
          </div>

          <div v-if="exitGates.length === 0" class="empty-state">
            <p>Belum ada gate keluar</p>
          </div>

          <div v-else class="gate-list">
            <div v-for="gate in exitGates" :key="gate.id" class="gate-card">
              <div class="gate-info">
                <span class="gate-number">Gate {{ gate.gate_number }}</span>
                <span class="gate-name">{{ gate.name }}</span>
                <span class="gate-coords" v-if="gate.lat && gate.lng">{{ Number(gate.lat).toFixed(5) }}, {{ Number(gate.lng).toFixed(5) }}</span>
                <span class="gate-coords" v-else style="color:#f87171;">Koordinat belum diset</span>
              </div>
              <div class="area-actions">
                <button class="btn-icon" @click="editGate(gate)" title="Edit">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                  </svg>
                </button>
                <button class="btn-icon btn-delete" @click="deleteGate(gate)" title="Hapus">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </section>

        <!-- Akun Gate -->
        <section class="settings-section">
          <div class="slots-header">
            <h2>Akun Petugas Gate</h2>
            <button class="btn-add-area" @click="openAddGateAccount">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
              </svg>
              Tambah Akun
            </button>
          </div>

          <div v-if="gateAccounts.length === 0" class="empty-state">
            <p>Belum ada akun petugas</p>
          </div>

          <div v-else class="gate-list">
            <div v-for="acc in gateAccounts" :key="acc.id" class="gate-card">
              <div class="gate-info">
                <span class="gate-number">{{ acc.username }}</span>
                <span class="gate-name">
                  <span :class="acc.is_online ? 'online-dot' : 'offline-dot'"></span>
                  {{ acc.is_online ? 'Online' : 'Offline' }}
                  <span v-if="acc.current_gate"> — Gate {{ exitGates.find(g => g.id === acc.current_gate)?.gate_number }}</span>
                </span>
              </div>
              <div class="area-actions">
                <button class="btn-icon btn-delete" @click="deleteGateAccount(acc)" title="Hapus">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </section>
      </div><!-- End Gate Tab -->

      <!-- TAB 4: Settings -->
      <div v-show="activeTab === 'settings'" class="tab-panel">
        
        <div class="settings-container">

          <!-- Umum -->
          <section class="settings-section">
            <h2>🌐 Umum</h2>
            
            <div class="settings-form">
              <div class="form-group">
                <label>URL Aplikasi</label>
                <input type="text" v-model="settings.app_url" @blur="saveSettings" placeholder="https://smartpark.example.com" />
                <p class="form-hint">URL untuk generate QR code tiket dan link visitor</p>
              </div>

              <div class="form-group">
                <label>Nama Aplikasi</label>
                <input type="text" v-model="settings.app_name" @blur="saveSettings" placeholder="SmartPark" />
                <p class="form-hint">Judul yang tampil di browser tab dan header</p>
              </div>

              <div class="form-group">
                <label>Favicon URL</label>
                <input type="text" v-model="settings.app_favicon" @blur="saveSettings" placeholder="https://example.com/favicon.ico" />
                <p class="form-hint">URL icon yang tampil di tab browser (format .ico, .png, atau .svg)</p>
              </div>

              <div class="form-group">
                <label>Prefix Kode Tiket</label>
                <input type="text" v-model="settings.ticket_prefix" @blur="saveSettings" placeholder="SP" />
                <p class="form-hint">Prefix kode tiket. Contoh: {{ settings.ticket_prefix || 'SP' }}-20250502-001-xxxx</p>
              </div>
            </div>
          </section>
          
          <!-- Pricing Settings -->
          <section class="settings-section">
            <h2>⚙️ Pengaturan Harga Parkir</h2>
            
            <div class="settings-form">
              <div class="form-group">
                <label>Mode Harga</label>
                <select v-model="settings.pricing_mode" @change="saveSettings">
                  <option value="per_minute">Per Menit</option>
                  <option value="per_hour">Per Jam</option>
                </select>
              </div>

              <div v-if="settings.pricing_mode === 'per_minute'" class="form-group">
                <label>Harga Per Menit</label>
                <div class="input-with-prefix">
                  <span class="prefix">Rp</span>
                  <input type="number" v-model="settings.price_per_minute" @blur="saveSettings" min="0" />
                </div>
              </div>

              <div v-if="settings.pricing_mode === 'per_hour'" class="form-group">
                <label>Harga Per Jam</label>
                <div class="input-with-prefix">
                  <span class="prefix">Rp</span>
                  <input type="number" v-model="settings.price_first_hour" @blur="saveSettings" min="0" />
                </div>
              </div>

              <!-- Harga Khusus Toggle -->
              <div class="toggle-row">
                <div class="toggle-row-info">
                  <span class="toggle-row-title">Harga Khusus</span>
                  <span class="toggle-row-desc">Tarif berbeda setelah durasi tertentu</span>
                </div>
                <button 
                  class="toggle-switch" 
                  :class="{ active: specialPriceEnabled }"
                  @click="specialPriceEnabled = !specialPriceEnabled; toggleSpecialPrice()"
                  type="button"
                >
                  <span class="toggle-knob"></span>
                </button>
              </div>

              <div v-if="specialPriceEnabled" class="toggle-content">
                <div class="form-group">
                  <label>Berlaku setelah</label>
                  <div class="input-group-inline">
                    <input 
                      type="number" 
                      v-model="settings.price_threshold" 
                      @blur="saveSettings" 
                      min="1" 
                      placeholder="1"
                    />
                    <select v-model="settings.threshold_unit" @change="saveSettings">
                      <option value="second">Detik</option>
                      <option value="minute">Menit</option>
                      <option value="hour">Jam</option>
                    </select>
                  </div>
                </div>
                <div class="form-group">
                  <label>Harga setelahnya</label>
                  <div class="input-with-prefix">
                    <span class="prefix">Rp</span>
                    <input type="number" v-model="settings.price_after_first_hour" @blur="saveSettings" min="0" />
                    <span class="suffix">/ {{ settings.pricing_mode === 'per_minute' ? 'menit' : 'jam' }}</span>
                  </div>
                </div>
              </div>

              <!-- Bebas Biaya Toggle -->
              <div class="toggle-row">
                <div class="toggle-row-info">
                  <span class="toggle-row-title">Bebas Biaya</span>
                  <span class="toggle-row-desc">Gratis untuk durasi awal tertentu</span>
                </div>
                <button 
                  class="toggle-switch" 
                  :class="{ active: freeParkingEnabled }"
                  @click="freeParkingEnabled = !freeParkingEnabled; toggleFreeParking()"
                  type="button"
                >
                  <span class="toggle-knob"></span>
                </button>
              </div>

              <div v-if="freeParkingEnabled" class="toggle-content">
                <div class="form-group">
                  <label>Gratis untuk</label>
                  <div class="input-group-inline">
                    <input 
                      type="number" 
                      v-model="settings.free_duration" 
                      @blur="saveSettings" 
                      min="1" 
                      placeholder="15"
                    />
                    <select v-model="settings.free_duration_unit" @change="saveSettings">
                      <option value="second">Detik</option>
                      <option value="minute">Menit</option>
                      <option value="hour">Jam</option>
                    </select>
                  </div>
                </div>
              </div>

              <div class="pricing-preview">
                <h4>Preview Harga:</h4>
                <ul>
                  <li v-if="settings.pricing_mode === 'per_minute' && !specialPriceEnabled">
                    30 menit = Rp {{ formatNumber(settings.price_per_minute * 30) }}
                  </li>
                  <li v-if="settings.pricing_mode === 'per_minute' && !specialPriceEnabled">
                    90 menit = Rp {{ formatNumber(settings.price_per_minute * 90) }}
                  </li>
                  <li v-if="settings.pricing_mode === 'per_minute' && specialPriceEnabled">
                    {{ settings.price_threshold || 60 }} menit = Rp {{ formatNumber(settings.price_per_minute * (settings.price_threshold || 60)) }}
                  </li>
                  <li v-if="settings.pricing_mode === 'per_minute' && specialPriceEnabled">
                    {{ (parseInt(settings.price_threshold || 60) + 30) }} menit = Rp {{ formatNumber((settings.price_per_minute * (settings.price_threshold || 60)) + (settings.price_after_first_hour * 30)) }}
                  </li>
                  <li v-if="settings.pricing_mode === 'per_hour' && !specialPriceEnabled">
                    2 jam = Rp {{ formatNumber(settings.price_first_hour * 2) }}
                  </li>
                  <li v-if="settings.pricing_mode === 'per_hour' && !specialPriceEnabled">
                    5 jam = Rp {{ formatNumber(settings.price_first_hour * 5) }}
                  </li>
                  <li v-if="settings.pricing_mode === 'per_hour' && specialPriceEnabled">
                    {{ settings.price_threshold || 1 }} jam = Rp {{ formatNumber(settings.price_first_hour * (settings.price_threshold || 1)) }}
                  </li>
                  <li v-if="settings.pricing_mode === 'per_hour' && specialPriceEnabled">
                    {{ (parseInt(settings.price_threshold || 1) + 2) }} jam = Rp {{ formatNumber((settings.price_first_hour * (settings.price_threshold || 1)) + (settings.price_after_first_hour * 2)) }}
                  </li>
                </ul>
              </div>

            </div>
          </section>

          <!-- Pengaturan Parkir -->
          <section class="settings-section">
            <h2>🅿️ Pengaturan Parkir</h2>
            
            <div class="settings-form">
              <div class="form-group">
                <label>Timeout Idle (menit)</label>
                <input type="number" v-model="settings.idle_timeout" @blur="saveSettings" min="1" max="120" placeholder="20" />
                <p class="form-hint">Pengunjung tidak bergerak selama {{ settings.idle_timeout || 20 }} menit → popup muncul. Tombol "parkir di slot berbeda" muncul di 50% waktu ini.</p>
              </div>

              <div class="form-group">
                <label>Cooldown Keluar (menit)</label>
                <input type="number" v-model="settings.exit_cooldown" @blur="saveSettings" min="0" max="60" placeholder="5" />
                <p class="form-hint">Visitor harus menunggu {{ settings.exit_cooldown || 5 }} menit setelah parkir sebelum bisa menekan tombol keluar</p>
              </div>
            </div>
          </section>

          <!-- Peta & Navigasi -->
          <section class="settings-section">
            <h2>🗺️ Peta & Navigasi</h2>
            
            <div class="settings-form">
              <div class="form-group">
                <label>Map Engine</label>
                <select v-model="settings.map_engine" @change="saveSettings">
                  <option value="maplibre">MapLibre GL (3D, behind-view)</option>
                  <option value="leaflet">Leaflet (2D, top-down)</option>
                </select>
              </div>

              <div class="form-group">
                <label>Warna Garis Navigasi</label>
                <div class="color-picker-row">
                  <input type="color" v-model="settings.nav_line_color" @change="saveSettings" class="color-input" />
                  <span class="color-value">{{ settings.nav_line_color }}</span>
                </div>
              </div>

              <div class="form-group">
                <label>Lokasi Default Peta</label>
                <MapCenterPicker
                  :lat="settings.default_lat"
                  :lng="settings.default_lng"
                  @update:lat="v => { settings.default_lat = v; saveSettings() }"
                  @update:lng="v => { settings.default_lng = v; saveSettings() }"
                />
                <p class="form-hint">Titik tengah peta default. Dipakai saat GPS belum aktif dan posisi awal debug.</p>
              </div>
            </div>
          </section>

          <!-- MQTT Settings -->
          <section class="settings-section">
            <h2>📡 Pengaturan MQTT (IoT Sensor)</h2>
            <p class="section-desc">Konfigurasi koneksi MQTT untuk menerima status slot dari sensor IoT secara real-time</p>
            
            <div class="settings-form">
              <div class="form-group">
                <label>MQTT Broker URL</label>
                <input 
                  type="text" 
                  v-model="settings.mqtt_broker" 
                  @blur="saveSettings"
                  placeholder="ws://broker.example.com:9001" 
                />
                <p class="form-hint">WebSocket URL (ws:// atau wss://)</p>
              </div>

              <div class="form-group">
                <label>Username (opsional)</label>
                <input 
                  type="text" 
                  v-model="settings.mqtt_username" 
                  @blur="saveSettings"
                  placeholder="mqtt_user" 
                />
              </div>

              <div class="form-group">
                <label>Password (opsional)</label>
                <input 
                  type="password" 
                  v-model="settings.mqtt_password" 
                  @blur="saveSettings"
                  placeholder="••••••••" 
                />
              </div>

              <!-- Status Bar -->
              <div class="mqtt-status-bar">
                <div class="mqtt-status-left">
                  <span class="mqtt-led" :class="mqttConnected ? 'mqtt-led-on' : 'mqtt-led-off'"></span>
                  <div class="mqtt-status-info">
                    <span class="mqtt-status-text">{{ mqttConnected ? 'Bridge Online' : 'Bridge Offline' }}</span>
                    <span v-if="mqttConnected" class="mqtt-uptime">Uptime: {{ formatUptime(mqttUptime) }} · {{ mqttMessages }} pesan</span>
                  </div>
                </div>
                <button class="mqtt-log-toggle" @click="showMqttLogs = !showMqttLogs">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                    <polyline points="14 2 14 8 20 8"/>
                  </svg>
                  Log ({{ mqttLogs.length }})
                </button>
              </div>

              <!-- Log Dropdown -->
              <div v-if="showMqttLogs" class="mqtt-log-panel">
                <div v-if="mqttLogs.length === 0" class="mqtt-log-empty">Belum ada log</div>
                <div v-for="(log, i) in mqttLogs" :key="i" class="mqtt-log-item" :class="'mqtt-log-' + log.type">
                  <span class="mqtt-log-time">{{ log.time }}</span>
                  <span class="mqtt-log-msg">{{ log.message }}</span>
                </div>
              </div>

              <!-- Buttons -->
              <div class="mqtt-actions">
                <button v-if="!mqttConnected" class="btn-test-mqtt" @click="startMqttBridge">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                  </svg>
                  Nyalakan Bridge
                </button>
                <button v-else class="btn-disconnect-mqtt" @click="stopMqttBridge">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                  </svg>
                  Matikan Bridge
                </button>
              </div>
            </div>
          </section>

          <!-- ☠️ DANGER ZONE -->
          <section class="danger-zone">
            <div class="danger-zone-header">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
              </svg>
              <div>
                <h2>Danger Zone</h2>
                <p>Aksi berikut bersifat permanen dan tidak dapat dibatalkan.</p>
              </div>
            </div>

            <div class="danger-actions">
              <div class="danger-action-item">
                <div class="danger-action-info">
                  <strong>Manajemen Parkir</strong>
                  <span>Reset: expired tiket aktif. Hapus: hapus permanen data & foto dari DB</span>
                </div>
                <div class="danger-btn-group">
                  <button class="btn-danger" @click="resetParkir" :disabled="dangerLoading" title="Reset status parkir saja">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>
                    </svg>
                    Reset
                  </button>
                  <button class="btn-danger btn-danger-solid" @click="hapusParkir" :disabled="dangerLoading" title="Hapus total ke akar">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                      <line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/>
                    </svg>
                    Hapus
                  </button>
                </div>
              </div>

              <div class="danger-action-item">
                <div class="danger-action-info">
                  <strong>Manajemen Infrastruktur</strong>
                  <span>Reset: kosongkan slot. Hapus: hapus permanen area, slot & gate</span>
                </div>
                <div class="danger-btn-group">
                  <button class="btn-danger" @click="resetSlots" :disabled="dangerLoading" title="Set slot ke available">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 9.9-1"/>
                    </svg>
                    Reset
                  </button>
                  <button class="btn-danger btn-danger-solid" @click="hapusInfrastruktur" :disabled="dangerLoading" title="Hapus area, slot, dan gate">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                      <line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/>
                    </svg>
                    Hapus
                  </button>
                </div>
              </div>

              <div class="danger-action-item">
                <div class="danger-action-info">
                  <strong>Reset Settings</strong>
                  <span>Kembalikan semua pengaturan ke nilai default</span>
                </div>
                <button class="btn-danger" @click="resetSettings" :disabled="dangerLoading">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="3"/><path d="M12 1v4M12 19v4M4.22 4.22l2.83 2.83M16.95 16.95l2.83 2.83M1 12h4M19 12h4M4.22 19.78l2.83-2.83M16.95 7.05l2.83-2.83"/>
                  </svg>
                  Reset Settings
                </button>
              </div>

              <div class="danger-action-item danger-action-full">
                <div class="danger-action-info">
                  <strong>⚠️ Aksi Menyeluruh</strong>
                  <span>Eksekusi ke seluruh sistem (Parkir, Slot, dan Settings)</span>
                </div>
                <div class="danger-btn-group-full">
                  <button class="btn-danger btn-danger-full" @click="resetSemua" :disabled="dangerLoading">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>
                    </svg>
                    {{ dangerLoading ? 'Memproses...' : 'Reset Semua' }}
                  </button>
                  <button class="btn-danger btn-danger-solid btn-danger-full" @click="hapusSemua" :disabled="dangerLoading">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                      <line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/>
                    </svg>
                    {{ dangerLoading ? 'Memproses...' : 'Hapus Semua' }}
                  </button>
                </div>
              </div>
            </div>
          </section>

        </div>

      </div><!-- End Settings Tab -->

    </div><!-- End Tab Content -->

    <!-- Image Modal -->
    <div v-if="selectedImage" class="modal-overlay" @click="selectedImage = null">
      <div class="modal-content" @click.stop>
        <button class="modal-close" @click="selectedImage = null">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </button>
        <img :src="selectedImage" alt="Vehicle Full" />
      </div>
    </div>

    <!-- Area Modal (Add/Edit) -->
    <div v-if="showAreaModal" class="modal-overlay" @click="showAreaModal = false">
      <div class="modal-form" @click.stop>
        <div class="modal-header">
          <h3>{{ editingArea ? 'Edit Area' : 'Tambah Area Baru' }}</h3>
          <button class="modal-close" @click="showAreaModal = false">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
        <form @submit.prevent="saveArea" class="form-content">
          <div class="form-group">
            <label>Nama Area *</label>
            <input type="text" v-model="areaForm.name" placeholder="Contoh: Lantai 1 - Area A" required />
          </div>
          <div class="form-group">
            <label>Lantai/Zona</label>
            <input type="text" v-model="areaForm.floor" placeholder="Contoh: Lantai 1" />
          </div>
          <div class="form-group">
            <label>Deskripsi</label>
            <textarea v-model="areaForm.description" placeholder="Deskripsi area parkir..." rows="2"></textarea>
          </div>
          <div class="form-group">
            <label>MQTT Topic Prefix</label>
            <input type="text" v-model="areaForm.mqtt_prefix" placeholder="smartpark/lantai1/" />
            <p class="form-hint">
              Topic tiap slot = prefix + nama slot.
              <span v-if="areaForm.mqtt_prefix">
                Contoh: <code style="background:rgba(99,102,241,.15);color:#a5b4fc;padding:1px 6px;border-radius:4px;font-family:monospace;">{{ areaForm.mqtt_prefix }}A1</code>
              </span>
            </p>
          </div>
          <div class="form-actions">
            <button type="button" class="btn-cancel" @click="showAreaModal = false">Batal</button>
            <button type="submit" class="btn-save">{{ editingArea ? 'Update' : 'Simpan' }}</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Slot Modal (Add/Edit) -->
    <div v-if="showSlotModal" class="modal-overlay" @click="showSlotModal = false">
      <div class="modal-form" @click.stop>
        <div class="modal-header">
          <h3>{{ editingSlot ? 'Edit Slot' : 'Tambah Slot Baru' }}</h3>
          <button class="modal-close" @click="showSlotModal = false">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
        <form @submit.prevent="saveSlot" class="form-content">
          <div class="form-group">
            <label>Nama Slot *</label>
            <input type="text" v-model="slotForm.name" placeholder="Contoh: A1" required />
          </div>
          <div class="form-group">
            <label>Status</label>
            <select v-model="slotForm.status">
              <option value="available">Tersedia</option>
              <option value="occupied">Terisi</option>
            </select>
          </div>
          <div class="form-group">
            <label>Lokasi & Rotasi Slot</label>
            <SlotMapPicker
              :lat="slotForm.lat"
              :lng="slotForm.lng"
              :rotation="slotForm.rotation || 0"
              :slotWidth="slotForm.slot_width || 3"
              :slotHeight="slotForm.slot_height || 5"
              :existingSlots="otherSlotsForPicker"
              :defaultLat="parseFloat(settings.default_lat || -7.2650876)"
              :defaultLng="parseFloat(settings.default_lng || 112.783217)"
              @update:lat="v => slotForm.lat = v"
              @update:lng="v => slotForm.lng = v"
              @update:rotation="v => slotForm.rotation = v"
              @update:slotWidth="v => slotForm.slot_width = v"
              @update:slotHeight="v => slotForm.slot_height = v"
            />
          </div>
          <div class="form-actions">
            <button type="button" class="btn-cancel" @click="showSlotModal = false">Batal</button>
            <button v-if="editingSlot" type="button" class="btn-delete-slot" @click="deleteSlot">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
              </svg>
              Hapus Slot
            </button>
            <button type="submit" class="btn-save">{{ editingSlot ? 'Update' : 'Simpan' }}</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Gate Modal -->
    <div v-if="showGateModal" class="modal-overlay" @click="showGateModal = false">
      <div class="modal-form" @click.stop>
        <div class="modal-header">
          <h3>{{ editingGate ? 'Edit Gate' : 'Tambah Gate Baru' }}</h3>
          <button class="modal-close" @click="showGateModal = false">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
        <form @submit.prevent="saveGate" class="form-content">
          <div class="form-group">
            <label>Nomor Gate *</label>
            <input type="number" v-model="gateForm.gate_number" placeholder="1" required min="1" />
          </div>
          <div class="form-group">
            <label>Nama Gate *</label>
            <input type="text" v-model="gateForm.name" placeholder="Gate Utara" required />
          </div>
          <div class="form-group">
            <label>Lokasi Gate</label>
            <MapCenterPicker
              :lat="gateForm.lat"
              :lng="gateForm.lng"
              @update:lat="v => gateForm.lat = v"
              @update:lng="v => gateForm.lng = v"
            />
          </div>
          <div class="form-actions">
            <button type="button" class="btn-cancel" @click="showGateModal = false">Batal</button>
            <button type="submit" class="btn-save">{{ editingGate ? 'Update' : 'Simpan' }}</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Gate Account Modal -->
    <div v-if="showGateAccountModal" class="modal-overlay" @click="showGateAccountModal = false">
      <div class="modal-form" @click.stop>
        <div class="modal-header">
          <h3>Tambah Akun Petugas</h3>
          <button class="modal-close" @click="showGateAccountModal = false">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
        <form @submit.prevent="saveGateAccount" class="form-content">
          <div class="form-group">
            <label>Username *</label>
            <input type="text" v-model="gateAccountForm.username" placeholder="petugas1" required />
          </div>
          <div class="form-group">
            <label>Password *</label>
            <input type="password" v-model="gateAccountForm.password" placeholder="••••••••" required />
          </div>
          <div class="form-actions">
            <button type="button" class="btn-cancel" @click="showGateAccountModal = false">Batal</button>
            <button type="submit" class="btn-save">Simpan</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Confirmation Modal -->
    <div v-if="confirmDialog.show" class="modal-overlay confirm-overlay" @click="closeConfirm">
      <div class="modal-form confirm-modal" :class="{ 'confirm-danger': confirmDialog.danger }" @click.stop>
        <div class="modal-header">
          <h3>{{ confirmDialog.title }}</h3>
          <button class="modal-close" @click="closeConfirm">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
        <div class="form-content">
          <p class="confirm-message" v-html="confirmDialog.message"></p>
          <div class="form-actions confirm-actions">
            <button v-if="!confirmDialog.isAlert" type="button" class="btn-cancel" @click="closeConfirm" :disabled="dangerLoading">
              {{ confirmDialog.cancelText }}
            </button>
            <button type="button" :class="confirmDialog.danger ? 'btn-danger btn-danger-solid' : 'btn-save'" @click="executeConfirm" :disabled="dangerLoading">
              {{ dangerLoading ? 'Memproses...' : confirmDialog.confirmText }}
            </button>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, h } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase.js'
import { invalidateBrandingCache } from '../router/index.js'

import SlotMapPicker from '../components/SlotMapPicker.vue'
import MapCenterPicker from '../components/MapCenterPicker.vue'
import AdminSlotMap from '../components/AdminSlotMap.vue'

const router = useRouter()

// Toast Notification - stack support
const toasts = ref([])
let toastIdCounter = 0

function showToast(message, type = 'info') {
  const id = ++toastIdCounter
  toasts.value.push({ id, message, type })
  setTimeout(() => removeToast(id), 3500)
}

function removeToast(id) {
  const idx = toasts.value.findIndex(t => t.id === id)
  if (idx !== -1) toasts.value.splice(idx, 1)
}

// Tabs
const activeTab = ref('dashboard')
const tabs = [
  { 
    id: 'dashboard', 
    label: 'Dashboard',
    icon: () => h('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2 }, [
      h('rect', { x: 3, y: 3, width: 7, height: 7 }),
      h('rect', { x: 14, y: 3, width: 7, height: 7 }),
      h('rect', { x: 14, y: 14, width: 7, height: 7 }),
      h('rect', { x: 3, y: 14, width: 7, height: 7 })
    ])
  },
  { 
    id: 'tickets', 
    label: 'Data Parkir',
    icon: () => h('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2 }, [
      h('path', { d: 'M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2Z' })
    ])
  },
  { 
    id: 'slots', 
    label: 'Slot Parkir',
    icon: () => h('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2 }, [
      h('rect', { x: 3, y: 11, width: 18, height: 11, rx: 2 }),
      h('path', { d: 'M7 11V7a5 5 0 0 1 10 0v4' })
    ])
  },
  { 
    id: 'gates', 
    label: 'Gate Keluar',
    icon: () => h('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2 }, [
      h('path', { d: 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4' }),
      h('polyline', { points: '16 17 21 12 16 7' }),
      h('line', { x1: 21, y1: 12, x2: 9, y2: 12 })
    ])
  },
  { 
    id: 'settings', 
    label: 'Pengaturan',
    icon: () => h('svg', { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2 }, [
      h('circle', { cx: 12, cy: 12, r: 3 }),
      h('path', { d: 'M12 1v6m0 6v6M5.64 5.64l4.24 4.24m4.24 4.24l4.24 4.24M1 12h6m6 0h6M5.64 18.36l4.24-4.24m4.24-4.24l4.24-4.24' })
    ])
  }
]

// State
const debugMode = ref(false)
const tickets = ref([])
const slots = ref([])
const areas = ref([])
const exitGates = ref([])
const gateAccounts = ref([])
const showGateModal = ref(false)
const showGateAccountModal = ref(false)
const editingGate = ref(null)
const editingGateAccount = ref(null)
const gateForm = ref({ gate_number: '', name: '', lat: null, lng: null })
const gateAccountForm = ref({ username: '', password: '' })


const stats = ref({
  todayTickets: 0,
  currentlyParked: 0,
  availableSlots: 0,
  todayRevenue: 0
})

const filterStatus = ref('all')
const searchQuery = ref('')
const currentPage = ref(1)
const perPage = 10
const selectedImage = ref(null)

// Area & Slot Modals
const showAreaModal = ref(false)
const showSlotModal = ref(false)
const editingArea = ref(null)
const editingSlot = ref(null)
const areaForm = ref({ name: '', floor: '', description: '', mqtt_prefix: '' })
const slotForm = ref({ name: '', status: 'available', area_id: null, lat: null, lng: null, rotation: 0, slot_width: 3, slot_height: 5 })

// Settings
const settings = ref({
  pricing_mode: 'per_hour',
  price_per_minute: '500',
  price_first_hour: '5000',
  price_after_first_hour: '3000',
  price_threshold: '1',
  threshold_unit: 'hour',
  free_duration: '0',
  free_duration_unit: 'minute',
  app_name: 'SmartPark',
  app_favicon: '',
  ticket_prefix: 'SP',
  idle_timeout: '20',
  default_lat: '-7.2650876',
  default_lng: '112.783217',
  exit_cooldown: '5',
  map_engine: 'maplibre',
  nav_line_color: '#4285F4',
  app_url: 'http://localhost:5173',
  mqtt_broker: '',
  mqtt_username: '',
  mqtt_password: ''
})
const specialPriceEnabled = ref(false)
const freeParkingEnabled = ref(false)
// MQTT state - dibaca dari Supabase, ditulis oleh mqtt-bridge
const mqttStatus = ref('offline')       // 'online' | 'offline'
const mqttConnectedAt = ref(null)        // ISO string dari settings.mqtt_connected_at
const mqttMessages = ref(0)             // jumlah pesan total
const mqttLogs = ref([])                // dari tabel mqtt_logs
const showMqttLogs = ref(false)
const mqttUptime = ref(0)               // dihitung lokal dari mqttConnectedAt
let mqttUptimeTimer = null
let mqttRealtimeChannel = null
let mqttPollInterval = null             // polling fallback
const mqttConnected = computed(() => mqttStatus.value === 'online')

const statusFilters = [
  { label: 'Semua', value: 'all' },
  { label: 'Aktif', value: 'active' },
  { label: 'Parkir', value: 'parked' },
  { label: 'Keluar', value: 'exiting' },
  { label: 'Selesai', value: 'done' },
  { label: 'Expired', value: 'expired' }
]

// Computed
const filteredTickets = computed(() => {
  let result = tickets.value

  // Filter by status
  if (filterStatus.value !== 'all') {
    result = result.filter(t => t.status === filterStatus.value)
  }

  // Search
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(t => 
      t.ticket_code.toLowerCase().includes(query)
    )
  }

  return result
})

const paginatedTickets = computed(() => {
  const start = (currentPage.value - 1) * perPage
  const end = start + perPage
  return filteredTickets.value.slice(start, end)
})

const totalPages = computed(() => {
  return Math.ceil(filteredTickets.value.length / perPage) || 1
})

// Unassigned slots (slot tanpa area_id)
const unassignedSlots = computed(() => {
  return slots.value.filter(s => !s.area_id)
})

// Methods
async function toggleDebugMode() {
  localStorage.setItem('smartpark_debug', debugMode.value ? '1' : '0')
  // Sync ke database supaya jalan di device/browser lain
  await supabase
    .from('settings')
    .update({ value: debugMode.value ? 'true' : 'false', updated_at: new Date().toISOString() })
    .eq('key', 'debug_mode')
}

async function loadDebugMode() {
  // Load dari DB
  const { data } = await supabase
    .from('settings')
    .select('value')
    .eq('key', 'debug_mode')
    .single()
  
  debugMode.value = data?.value === 'true'
  localStorage.setItem('smartpark_debug', debugMode.value ? '1' : '0')
}

// Settings Methods
async function fetchSettings() {
  try {
    const { data, error } = await supabase
      .from('settings')
      .select('*')
    
    if (error) throw error
    
    // Map settings array to object
    data.forEach(setting => {
      if (setting.key in settings.value) {
        settings.value[setting.key] = setting.value
        if (setting.key === 'app_name') {
          document.title = setting.value + ' — Admin Panel'
        }
        if (setting.key === 'app_favicon' && setting.value) {
          let link = document.querySelector("link[rel~='icon']")
          if (!link) { link = document.createElement('link'); link.rel = 'icon'; document.head.appendChild(link) }
          link.href = setting.value
        }
      }
      if (setting.key === 'special_price_enabled') {
        specialPriceEnabled.value = setting.value === 'true'
      }
      if (setting.key === 'free_parking_enabled') {
        freeParkingEnabled.value = setting.value === 'true'
      }
      if (setting.key === 'price_threshold') {
        settings.value.price_threshold = setting.value
      }
      if (setting.key === 'threshold_unit') {
        settings.value.threshold_unit = setting.value
      }
      if (setting.key === 'free_duration') {
        settings.value.free_duration = setting.value
      }
      if (setting.key === 'free_duration_unit') {
        settings.value.free_duration_unit = setting.value
      }
    })
  } catch (err) {
    console.error('Fetch settings error:', err)
  }
}

async function saveSettings() {
  try {
    const updates = Object.entries(settings.value).map(([key, value]) => ({
      key,
      value: String(value),
      updated_at: new Date().toISOString()
    }))
    
    // Upsert: insert kalau belum ada, update kalau udah ada
    const { error } = await supabase
      .from('settings')
      .upsert(updates, { onConflict: 'key' })

    if (error) throw error

    // Reset branding cache supaya title & favicon langsung ikut berubah
    invalidateBrandingCache()

    // Apply branding langsung ke tab ini juga
    const appName = settings.value.app_name || 'SmartPark'
    document.title = appName + ' — Admin Panel'
    if (settings.value.app_favicon) {
      let link = document.querySelector("link[rel~='icon']")
      if (!link) { link = document.createElement('link'); link.rel = 'icon'; document.head.appendChild(link) }
      link.href = settings.value.app_favicon
    }
    
    showToast('Pengaturan berhasil disimpan', 'success')
  } catch (err) {
    console.error('Save settings error:', err)
    showToast('Gagal menyimpan pengaturan', 'error')
  }
}

async function toggleSpecialPrice() {
  try {
    await supabase
      .from('settings')
      .update({ value: specialPriceEnabled.value ? 'true' : 'false' })
      .eq('key', 'special_price_enabled')
    
    saveSettings()
  } catch (err) {
    console.error('Toggle special price error:', err)
  }
}

async function toggleFreeParking() {
  try {
    await supabase
      .from('settings')
      .update({ value: freeParkingEnabled.value ? 'true' : 'false' })
      .eq('key', 'free_parking_enabled')
    
    saveSettings()
  } catch (err) {
    console.error('Toggle free parking error:', err)
  }
}

// ===== MQTT BRIDGE CONTROL (via Supabase settings) =====

async function startMqttBridge() {
  if (!settings.value.mqtt_broker) {
    showToast('Broker URL belum diisi!', 'error')
    return
  }
  await supabase.from('settings').upsert([
    { key: 'mqtt_enabled', value: 'true', updated_at: new Date().toISOString() }
  ], { onConflict: 'key' })
  showToast('Bridge dinyalakan — menunggu koneksi...', 'info')
  
  // Timeout 12 detik. Bridge jalan per 5 detik, jadi butuh waktu agak lama buat sadar & connect.
  setTimeout(async () => {
    // Ambil data terbaru buat mastiin user ga keburu matiin lagi
    const { data } = await supabase.from('settings').select('key, value').in('key', ['mqtt_status', 'mqtt_enabled'])
    if (!data) return
    
    let currentStatus = mqttStatus.value
    let isEnabled = 'true'
    data.forEach(r => {
      if (r.key === 'mqtt_status') currentStatus = r.value || 'offline'
      if (r.key === 'mqtt_enabled') isEnabled = r.value || 'false'
    })

    if (isEnabled === 'true' && currentStatus !== 'online') {
      showConfirm({
        title: 'Koneksi MQTT Gagal',
        message: 'Tidak dapat terhubung ke broker MQTT. Periksa URL Broker, Username, dan Password di Pengaturan.<br><br>Pastikan juga service <b>mqtt-bridge</b> berjalan di latar belakang.',
        confirmText: 'Tutup',
        isAlert: true,
        danger: true
      })
    }
  }, 12000)
}

function stopMqttBridge() {
  showConfirm({
    title: 'Matikan MQTT Bridge',
    message: 'Apakah Anda yakin ingin mematikan MQTT Bridge? Sistem tidak akan menerima data dari sensor parkir secara realtime.',
    confirmText: 'Matikan Bridge',
    danger: true,
    onConfirm: async () => {
      await supabase.from('settings').upsert([
        { key: 'mqtt_enabled', value: 'false', updated_at: new Date().toISOString() }
      ], { onConflict: 'key' })
      showToast('Bridge dimatikan', 'info')
    }
  })
}

async function fetchMqttLogs() {
  const { data } = await supabase
    .from('mqtt_logs')
    .select('type, message, created_at')
    .order('created_at', { ascending: false })
    .limit(100)
  if (data) {
    mqttLogs.value = data.map(l => ({
      type: l.type,
      message: l.message,
      time: new Date(l.created_at).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
    }))
  }
}

function startUptimeCounter() {
  if (mqttUptimeTimer) clearInterval(mqttUptimeTimer)
  mqttUptimeTimer = setInterval(() => {
    if (mqttConnectedAt.value) {
      mqttUptime.value = Math.floor((Date.now() - new Date(mqttConnectedAt.value).getTime()) / 1000)
    } else {
      mqttUptime.value = 0
    }
  }, 1000)
}

function formatUptime(seconds) {
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  const s = seconds % 60
  if (h > 0) return `${h}j ${m}m ${s}d`
  if (m > 0) return `${m}m ${s}d`
  return `${s}d`
}

function subscribeMqttStatus() {
  mqttRealtimeChannel = supabase
    .channel('mqtt-status')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'settings' }, (payload) => {
      const row = payload.new
      if (!row) return
      if (row.key === 'mqtt_status') mqttStatus.value = row.value
      if (row.key === 'mqtt_connected_at') {
        mqttConnectedAt.value = row.value
        if (row.value && mqttStatus.value === 'online') startUptimeCounter()
        else { if (mqttUptimeTimer) clearInterval(mqttUptimeTimer); mqttUptime.value = 0 }
      }
      if (row.key === 'mqtt_messages') mqttMessages.value = parseInt(row.value) || 0
    })
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'mqtt_logs' }, (payload) => {
      const row = payload.new
      if (!row) return
      mqttLogs.value.unshift({
        type: row.type,
        message: row.message,
        time: new Date(row.created_at).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
      })
      if (mqttLogs.value.length > 100) mqttLogs.value.pop()
    })
    .subscribe()
}

// Polling fallback - jalan tiap 3 detik, antisipasi realtime settings ga aktif
async function pollMqttState() {
  const { data } = await supabase
    .from('settings')
    .select('key, value')
    .in('key', ['mqtt_status', 'mqtt_connected_at', 'mqtt_messages'])
  if (!data) return

  let newStatus = mqttStatus.value
  data.forEach(r => {
    if (r.key === 'mqtt_status') newStatus = r.value || 'offline'
    if (r.key === 'mqtt_connected_at') mqttConnectedAt.value = r.value || null
    if (r.key === 'mqtt_messages') mqttMessages.value = parseInt(r.value) || 0
  })

  // Trigger uptime counter kalau status baru jadi online
  if (newStatus !== mqttStatus.value) {
    mqttStatus.value = newStatus
    if (newStatus === 'online' && mqttConnectedAt.value) {
      startUptimeCounter()
    } else if (newStatus === 'offline') {
      if (mqttUptimeTimer) clearInterval(mqttUptimeTimer)
      mqttUptime.value = 0
    }
  }

  // Fetch log baru kalau ada yang masuk
  await fetchMqttLogs()
}

// ===== DANGER ZONE & CONFIRM MODAL =====
const dangerLoading = ref(false)

const confirmDialog = ref({
  show: false,
  title: '',
  message: '',
  confirmText: 'Lanjutkan',
  cancelText: 'Batal',
  danger: false,
  isAlert: false,
  onConfirm: null
})

function showConfirm(options) {
  confirmDialog.value = {
    show: true,
    title: options.title || 'Konfirmasi',
    message: (options.message || '').replace(/\n/g, '<br>'),
    confirmText: options.confirmText || 'Lanjutkan',
    cancelText: options.cancelText || 'Batal',
    danger: options.danger || false,
    isAlert: options.isAlert || false,
    onConfirm: options.onConfirm || null
  }
}

function closeConfirm() {
  if (dangerLoading.value) return
  confirmDialog.value.show = false
  confirmDialog.value.onConfirm = null
}

async function executeConfirm() {
  if (confirmDialog.value.onConfirm) {
    await confirmDialog.value.onConfirm()
  }
  closeConfirm()
}

function resetParkir() {
  showConfirm({
    title: 'Reset Parkir',
    message: 'Set semua tiket aktif jadi expired dan hapus session aktif?\n\n<b>Aksi ini TIDAK BISA dibatalkan.</b>',
    confirmText: 'Ya, Reset Parkir',
    danger: true,
    onConfirm: async () => {
      dangerLoading.value = true
      try {
        const { error: tErr } = await supabase.from('tickets')
          .update({ status: 'expired', exited_at: new Date().toISOString() })
          .in('status', ['active', 'parked', 'exiting'])
        if (tErr) throw tErr
        
        const { error: sErr } = await supabase.from('sessions').delete().not('id', 'is', null)
        if (sErr) throw sErr
        
        showToast('✅ Semua parkir aktif telah direset', 'success')
        fetchTickets()
      } catch (err) {
        showToast('❌ Gagal: ' + err.message, 'error')
      } finally {
        dangerLoading.value = false
      }
    }
  })
}

function hapusParkir() {
  showConfirm({
    title: 'Hapus Parkir Permanen',
    message: 'HAPUS PERMANEN semua data parkir, session, dan <b>FOTO MEDIA</b> dari database?\n\nSemua riwayat akan hilang tanpa sisa!\n<b>Lanjutkan?</b>',
    confirmText: 'Hapus Permanen',
    danger: true,
    onConfirm: async () => {
      dangerLoading.value = true
      try {
        // 1. Kosongkan bucket foto
        const { data: files } = await supabase.storage.from('vehicle-images').list()
        if (files && files.length > 0) {
          const fileNames = files.map(f => f.name).filter(n => n !== '.emptyFolderPlaceholder')
          if (fileNames.length > 0) {
            await supabase.storage.from('vehicle-images').remove(fileNames)
          }
        }
        
        // 2. Hapus tiket dan session
        const { error: tErr } = await supabase.from('tickets').delete().not('id', 'is', null)
        if (tErr) throw tErr
        const { error: sErr } = await supabase.from('sessions').delete().not('id', 'is', null)
        if (sErr) throw sErr
        
        showToast('✅ Seluruh data & foto parkir telah DIBERSIHKAN!', 'success')
        fetchTickets()
      } catch (err) {
        showToast('❌ Gagal hapus parkir: ' + err.message, 'error')
      } finally {
        dangerLoading.value = false
      }
    }
  })
}

function resetSlots() {
  showConfirm({
    title: 'Reset Slot',
    message: 'Set semua slot ke available dan hapus semua lock?\n\n<b>Aksi ini TIDAK BISA dibatalkan.</b>',
    confirmText: 'Ya, Reset Slot',
    danger: true,
    onConfirm: async () => {
      dangerLoading.value = true
      try {
        const { error } = await supabase.from('parking_slots')
          .update({ status: 'available', locked_by: null, updated_at: new Date().toISOString() })
          .not('id', 'is', null)
        if (error) throw error
        
        showToast('✅ Semua slot telah direset ke available', 'success')
        fetchSlots()
      } catch (err) {
        showToast('❌ Gagal: ' + err.message, 'error')
      } finally {
        dangerLoading.value = false
      }
    }
  })
}

function hapusInfrastruktur() {
  showConfirm({
    title: 'Hapus Infrastruktur',
    message: 'HAPUS PERMANEN semua Area, Slot Parkir, dan Data Gate (Gate Out & Akun)?\n\nAnda harus membuat ulang dari awal!\n<b>Lanjutkan?</b>',
    confirmText: 'Hapus Infrastruktur',
    danger: true,
    onConfirm: async () => {
      dangerLoading.value = true
      try {
        const { error: slotErr } = await supabase.from('parking_slots').delete().not('id', 'is', null)
        if (slotErr) throw slotErr
        
        const { error: areaErr } = await supabase.from('areas').delete().not('id', 'is', null)
        if (areaErr) throw areaErr

        const { error: gateErr } = await supabase.from('exit_gates').delete().not('id', 'is', null)
        if (gateErr) throw gateErr

        const { error: accErr } = await supabase.from('gate_accounts').delete().not('id', 'is', null)
        if (accErr) throw accErr

        showToast('✅ Semua Area, Slot, dan Gate telah DIBERSIHKAN!', 'success')
        fetchSlots()
        fetchAreas()
        fetchGates()
        fetchGateAccounts()
      } catch (err) {
        showToast('❌ Gagal hapus infrastruktur: ' + err.message, 'error')
      } finally {
        dangerLoading.value = false
      }
    }
  })
}

function resetSettings() {
  showConfirm({
    title: 'Reset Pengaturan',
    message: 'Kembalikan semua pengaturan ke nilai default?\n\n<b>Aksi ini TIDAK BISA dibatalkan.</b>',
    confirmText: 'Ya, Reset',
    danger: true,
    onConfirm: async () => {
      dangerLoading.value = true
      try {
        const defaults = [
          { key: 'pricing_mode', value: 'per_hour' },
          { key: 'price_first_hour', value: '5000' },
          { key: 'price_per_minute', value: '100' },
          { key: 'price_after_first_hour', value: '3000' },
          { key: 'special_price_enabled', value: 'false' },
          { key: 'free_parking_enabled', value: 'false' },
          { key: 'free_duration', value: '0' },
          { key: 'free_duration_unit', value: 'minute' },
          { key: 'price_threshold', value: '1' },
          { key: 'threshold_unit', value: 'hour' },
          { key: 'idle_timeout', value: '20' },
          { key: 'exit_cooldown', value: '5' },
          { key: 'ticket_prefix', value: 'SP' },
          { key: 'app_name', value: 'SmartPark' },
          { key: 'app_favicon', value: '' },
          { key: 'map_engine', value: 'maplibre' },
          { key: 'nav_line_color', value: '#4285F4' },
        ]
        const { error } = await supabase.from('settings')
          .upsert(defaults.map(d => ({ ...d, updated_at: new Date().toISOString() })), { onConflict: 'key' })
        if (error) throw error
        
        showToast('✅ Settings direset ke default', 'success')
        await fetchSettings()
      } catch (err) {
        showToast('❌ Gagal: ' + err.message, 'error')
      } finally {
        dangerLoading.value = false
      }
    }
  })
}

function resetSemua() {
  showConfirm({
    title: 'Reset Semua',
    message: '⚠️ <b>RESET SEMUA</b><br><br>Ini akan mereset:<br>- Semua parkir aktif → expired<br>- Semua slot → available<br>- Semua settings → default<br><br><b>Aksi ini TIDAK BISA dibatalkan!</b>',
    confirmText: 'Ya, Reset Semua',
    danger: true,
    onConfirm: async () => {
      dangerLoading.value = true
      try {
        // Reset parkir langsung tanpa confirm lagi
        const { error: tErr } = await supabase.from('tickets')
          .update({ status: 'expired', exited_at: new Date().toISOString() })
          .in('status', ['active', 'parked', 'exiting'])
        if (tErr) throw tErr

        const { error: sErr } = await supabase.from('sessions').delete().not('id', 'is', null)
        if (sErr) throw sErr

        // Reset slots
        const { error: slotErr } = await supabase.from('parking_slots')
          .update({ status: 'available', locked_by: null, updated_at: new Date().toISOString() })
          .not('id', 'is', null)
        if (slotErr) throw slotErr
        // Reset settings
        const defaults = [
          { key: 'pricing_mode', value: 'per_hour' },
          { key: 'price_first_hour', value: '5000' },
          { key: 'price_per_minute', value: '100' },
          { key: 'price_after_first_hour', value: '3000' },
          { key: 'special_price_enabled', value: 'false' },
          { key: 'free_parking_enabled', value: 'false' },
          { key: 'free_duration', value: '0' },
          { key: 'free_duration_unit', value: 'minute' },
          { key: 'price_threshold', value: '1' },
          { key: 'threshold_unit', value: 'hour' },
          { key: 'idle_timeout', value: '20' },
          { key: 'exit_cooldown', value: '5' },
          { key: 'ticket_prefix', value: 'SP' },
          { key: 'app_name', value: 'SmartPark' },
          { key: 'app_favicon', value: '' },
          { key: 'map_engine', value: 'maplibre' },
          { key: 'nav_line_color', value: '#4285F4' },
        ]
        const { error: setErr } = await supabase.from('settings')
          .upsert(defaults.map(d => ({ ...d, updated_at: new Date().toISOString() })), { onConflict: 'key' })
        if (setErr) throw setErr
        
        showToast('✅ Reset semua selesai!', 'success')
        fetchTickets()
        fetchSlots()
        await fetchSettings()
      } catch (err) {
        showToast('❌ Gagal reset semua: ' + err.message, 'error')
      } finally {
        dangerLoading.value = false
      }
    }
  })
}

function hapusSemua() {
  showConfirm({
    title: 'Hapus Semua Ke Akar',
    message: '⚠️ <b>HAPUS SEMUA KE AKAR</b><br><br>Ini akan:<br>- HAPUS SEMUA data parkir & media foto<br>- Hapus SEMUA Area, Slot, & Gate<br>- Reset settings ke default<br><br><b>TIDAK BISA DIBATALKAN. LANJUTKAN?</b>',
    confirmText: 'Ya, Hapus Semua',
    danger: true,
    onConfirm: async () => {
      dangerLoading.value = true
      try {
        // Kosongkan bucket foto
        const { data: files } = await supabase.storage.from('vehicle-images').list()
        if (files && files.length > 0) {
          const fileNames = files.map(f => f.name).filter(n => n !== '.emptyFolderPlaceholder')
          if (fileNames.length > 0) {
            await supabase.storage.from('vehicle-images').remove(fileNames)
          }
        }
        
        // Hapus tiket dan session
        const { error: tErr } = await supabase.from('tickets').delete().not('id', 'is', null)
        if (tErr) throw tErr
        const { error: sErr } = await supabase.from('sessions').delete().not('id', 'is', null)
        if (sErr) throw sErr

        // Hapus infrastruktur (slot, area, gate, gate accounts)
        const { error: slotErr } = await supabase.from('parking_slots').delete().not('id', 'is', null)
        if (slotErr) throw slotErr
        const { error: areaErr } = await supabase.from('areas').delete().not('id', 'is', null)
        if (areaErr) throw areaErr
        const { error: gateErr } = await supabase.from('exit_gates').delete().not('id', 'is', null)
        if (gateErr) throw gateErr
        const { error: accErr } = await supabase.from('gate_accounts').delete().not('id', 'is', null)
        if (accErr) throw accErr
        
        // Reset settings
        const defaults = [
          { key: 'pricing_mode', value: 'per_hour' },
          { key: 'price_first_hour', value: '5000' },
          { key: 'price_per_minute', value: '100' },
          { key: 'price_after_first_hour', value: '3000' },
          { key: 'special_price_enabled', value: 'false' },
          { key: 'free_parking_enabled', value: 'false' },
          { key: 'free_duration', value: '0' },
          { key: 'free_duration_unit', value: 'minute' },
          { key: 'price_threshold', value: '1' },
          { key: 'threshold_unit', value: 'hour' },
          { key: 'idle_timeout', value: '20' },
          { key: 'exit_cooldown', value: '5' },
          { key: 'ticket_prefix', value: 'SP' },
          { key: 'app_name', value: 'SmartPark' },
          { key: 'app_favicon', value: '' },
          { key: 'map_engine', value: 'maplibre' },
          { key: 'nav_line_color', value: '#4285F4' },
        ]
        const { error: setErr } = await supabase.from('settings')
          .upsert(defaults.map(d => ({ ...d, updated_at: new Date().toISOString() })), { onConflict: 'key' })
        if (setErr) throw setErr
        
        showToast('✅ Pembersihan total berhasil dieksekusi!', 'success')
        fetchTickets()
        fetchSlots()
        fetchAreas()
        fetchGates()
        fetchGateAccounts()
        await fetchSettings()
      } catch (err) {
        showToast('❌ Gagal hapus semua: ' + err.message, 'error')
      } finally {
        dangerLoading.value = false
      }
    }
  })
}

async function updateSlotTopic(slot, topic) {
  try {
    await supabase
      .from('parking_slots')
      .update({ mqtt_topic: topic, updated_at: new Date().toISOString() })
      .eq('id', slot.id)
    
    slot.mqtt_topic = topic
    console.log(`Slot ${slot.name} topic updated:`, topic)
  } catch (err) {
    console.error('Update slot topic error:', err)
  }
}

async function fetchTickets() {
  try {
    const { data, error } = await supabase
      .from('tickets')
      .select(`
        *,
        sessions (
          slot_id,
          duration_minutes,
          cost_rupiah,
          parking_slots (name)
        )
      `)
      .order('created_at', { ascending: false })

    if (error) throw error

    tickets.value = data.map(t => ({
      ...t,
      slot_name: t.sessions?.[0]?.parking_slots?.name,
      duration: t.sessions?.[0]?.duration_minutes ? `${t.sessions[0].duration_minutes} menit` : null,
      cost: t.sessions?.[0]?.cost_rupiah || null
    }))

    calculateStats()

  } catch (err) {
    console.error('Fetch tickets error:', err)
  }
}

async function fetchSlots() {
  try {
    const { data, error } = await supabase
      .from('parking_slots')
      .select('*')
      .order('name')

    if (error) throw error
    slots.value = data || []
  } catch (err) {
    console.error('Fetch slots error:', err)
  }
}

async function fetchAreas() {
  try {
    const { data, error } = await supabase
      .from('parking_areas')
      .select('*')
      .order('floor', { ascending: true })

    if (error) throw error
    areas.value = data || []
  } catch (err) {
    console.error('Fetch areas error:', err)
  }
}

function getSlotsByArea(areaId) {
  return slots.value.filter(s => s.area_id === areaId)
}

function getAreaSlotCount(areaId) {
  return getSlotsByArea(areaId).length
}

function getMqttAddress(area, slot) {
  const prefix = area.mqtt_prefix || ''
  return prefix ? `${prefix}${slot.name}` : 'prefix belum diset'
}

async function updateAreaMqttPrefix(area, prefix) {
  try {
    const { error } = await supabase
      .from('parking_areas')
      .update({ mqtt_prefix: prefix, updated_at: new Date().toISOString() })
      .eq('id', area.id)

    if (error) throw error

    area.mqtt_prefix = prefix

    // Auto-update mqtt_topic semua slot di area ini
    const areaSlots = getSlotsByArea(area.id)
    for (const slot of areaSlots) {
      const newTopic = prefix ? `${prefix}${slot.name}` : ''
      await supabase
        .from('parking_slots')
        .update({ mqtt_topic: newTopic, updated_at: new Date().toISOString() })
        .eq('id', slot.id)
      slot.mqtt_topic = newTopic
    }

    showToast(`✅ Prefix MQTT area "${area.name}" disimpan`, 'success')
  } catch (err) {
    console.error('Update area mqtt prefix error:', err)
    showToast('❌ Gagal menyimpan prefix MQTT', 'error')
  }
}

// Area Management
function openAddArea() {
  editingArea.value = null
  areaForm.value = { name: '', floor: '', description: '', mqtt_prefix: '' }
  showAreaModal.value = true
}

function editArea(area) {
  editingArea.value = area
  areaForm.value = { ...area }
  showAreaModal.value = true
}

async function saveArea() {
  try {
    const isEdit = !!editingArea.value
    
    // Cek kalau prefix berubah dan MQTT masih connected
    if (isEdit && mqttConnected.value) {
      const oldPrefix = editingArea.value.mqtt_prefix || ''
      const newPrefix = areaForm.value.mqtt_prefix || ''
      if (oldPrefix !== newPrefix) {
        showToast('⚠️ Disconnect MQTT dulu sebelum ganti prefix, lalu connect lagi', 'error')
        return
      }
    }

    const payload = {
      name: areaForm.value.name,
      floor: areaForm.value.floor,
      description: areaForm.value.description,
      mqtt_prefix: areaForm.value.mqtt_prefix || '',
      updated_at: new Date().toISOString()
    }

    if (isEdit) {
      const { error } = await supabase
        .from('parking_areas')
        .update(payload)
        .eq('id', editingArea.value.id)

      if (error) throw error

      // Kalau prefix berubah, auto-update semua topic slot di area ini
      const oldPrefix = editingArea.value.mqtt_prefix || ''
      const newPrefix = areaForm.value.mqtt_prefix || ''
      if (oldPrefix !== newPrefix) {
        const areaSlots = getSlotsByArea(editingArea.value.id)
        for (const slot of areaSlots) {
          const newTopic = newPrefix ? `${newPrefix}${slot.name}` : ''
          await supabase
            .from('parking_slots')
            .update({ mqtt_topic: newTopic, updated_at: new Date().toISOString() })
            .eq('id', slot.id)
          slot.mqtt_topic = newTopic
        }
      }
    } else {
      const { error } = await supabase
        .from('parking_areas')
        .insert([payload])

      if (error) throw error
    }

    showAreaModal.value = false
    showToast(`✅ Area berhasil ${isEdit ? 'diupdate' : 'ditambahkan'}`, 'success')
    editingArea.value = null
    areaForm.value = { name: '', floor: '', description: '', mqtt_prefix: '' }
    fetchAreas()
    fetchSlots()
  } catch (err) {
    console.error('Save area error:', err)
    showToast('❌ Gagal menyimpan area: ' + err.message, 'error')
  }
}

function deleteArea(area) {
  showConfirm({
    title: `Hapus Area "${area.name}"`,
    message: `Hapus permanen area <b>${area.name}</b>?<br><br>Semua slot di area ini juga akan ikut terhapus.`,
    confirmText: 'Hapus Area',
    danger: true,
    onConfirm: async () => {
      try {
        const { error } = await supabase
          .from('parking_areas')
          .delete()
          .eq('id', area.id)
        if (error) throw error
        showToast(`✅ Area "${area.name}" berhasil dihapus`, 'success')
        fetchAreas()
        fetchSlots()
      } catch (err) {
        console.error('Delete area error:', err)
        showToast('❌ Gagal menghapus area: ' + err.message, 'error')
      }
    }
  })
}

// Slot Management
// Other slots for map picker (show all except current editing)
const otherSlotsForPicker = computed(() => {
  if (editingSlot.value) {
    return slots.value.filter(s => s.id !== editingSlot.value.id)
  }
  return slots.value
})

function addSlotToArea(area) {
  editingSlot.value = null
  slotForm.value = { name: '', status: 'available', area_id: area.id, lat: null, lng: null, rotation: 0 }
  showSlotModal.value = true
}

function editSlot(slot) {
  editingSlot.value = slot
  slotForm.value = { ...slot }
  showSlotModal.value = true
}

async function saveSlot() {
  try {
    // Build mqtt_topic from area prefix + slot name
    let mqttTopic = ''
    if (slotForm.value.area_id) {
      const area = areas.value.find(a => a.id === slotForm.value.area_id)
      if (area?.mqtt_prefix) {
        mqttTopic = `${area.mqtt_prefix}${slotForm.value.name}`
      }
    }

    const payload = {
      name: slotForm.value.name,
      status: slotForm.value.status,
      lat: slotForm.value.lat ? parseFloat(slotForm.value.lat) : null,
      lng: slotForm.value.lng ? parseFloat(slotForm.value.lng) : null,
      rotation: parseInt(slotForm.value.rotation || 0),
      slot_width: parseFloat(slotForm.value.slot_width || 3),
      slot_height: parseFloat(slotForm.value.slot_height || 5),
      mqtt_topic: mqttTopic,
      updated_at: new Date().toISOString()
    }

    if (editingSlot.value) {
      const { error } = await supabase
        .from('parking_slots')
        .update(payload)
        .eq('id', editingSlot.value.id)

      if (error) throw error
    } else {
      payload.area_id = slotForm.value.area_id
      const { error } = await supabase
        .from('parking_slots')
        .insert([payload])

      if (error) throw error
    }

    showSlotModal.value = false
    editingSlot.value = null
    slotForm.value = { name: '', status: 'available', area_id: null, lat: null, lng: null, rotation: 0, slot_width: 3, slot_height: 5 }
    showToast('✅ Slot berhasil disimpan', 'success')
    fetchSlots()
    calculateStats()
  } catch (err) {
    console.error('Save slot error:', err)
    showToast('❌ Gagal menyimpan slot: ' + err.message, 'error')
  }
}

async function deleteSlot() {
  if (!editingSlot.value) return
  const slotName = editingSlot.value.name
  showSlotModal.value = false
  showConfirm({
    title: `Hapus Slot ${slotName}`,
    message: `Hapus permanen slot <b>${slotName}</b>?<br><br>Data GPS, MQTT topic, dan semua konfigurasi slot ini akan hilang.`,
    confirmText: 'Hapus',
    danger: true,
    onConfirm: async () => {
      try {
        const { error } = await supabase
          .from('parking_slots')
          .delete()
          .eq('id', editingSlot.value.id)
        if (error) throw error
        editingSlot.value = null
        slotForm.value = { name: '', status: 'available', area_id: null, lat: null, lng: null, rotation: 0, slot_width: 3, slot_height: 5 }
        showToast(`✅ Slot ${slotName} berhasil dihapus`, 'success')
        fetchSlots()
        calculateStats()
      } catch (err) {
        showToast('❌ Gagal hapus slot: ' + err.message, 'error')
      }
    }
  })
}

// Debug mode: toggle slot status manual
async function debugToggleSlot(slot) {
  if (!debugMode.value) return
  
  const newStatus = slot.status === 'available' ? 'occupied' : 'available'
  
  try {
    const { error } = await supabase
      .from('parking_slots')
      .update({ status: newStatus, updated_at: new Date().toISOString() })
      .eq('id', slot.id)

    if (error) throw error
    
    slot.status = newStatus
    calculateStats()
    showToast(`🐛 Slot ${slot.name} → ${newStatus}`, 'info')
  } catch (err) {
    console.error('Debug toggle slot error:', err)
    showToast('❌ Gagal toggle slot', 'error')
  }
}

function calculateStats() {
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  stats.value.todayTickets = tickets.value.filter(t => 
    new Date(t.created_at) >= today
  ).length

  stats.value.currentlyParked = slots.value.filter(s => 
    s.status === 'occupied'
  ).length

  stats.value.availableSlots = slots.value.filter(s => 
    s.status === 'available'
  ).length

  // Pendapatan: dari tiket done yang DIBAYAR hari ini (pakai exited_at)
  stats.value.todayRevenue = tickets.value
    .filter(t => t.status === 'done' && t.exited_at && new Date(t.exited_at) >= today)
    .reduce((sum, t) => sum + (t.cost || 0), 0)
}

function calculatePrice(durationMinutes) {
  // Check free parking first
  if (freeParkingEnabled.value) {
    let freeMinutes = parseInt(settings.value.free_duration || 0)
    const freeUnit = settings.value.free_duration_unit || 'minute'
    
    if (freeUnit === 'hour') freeMinutes *= 60
    else if (freeUnit === 'second') freeMinutes /= 60
    
    if (durationMinutes <= freeMinutes) {
      return 0 // Free!
    }
    
    // Subtract free duration from total
    durationMinutes -= freeMinutes
  }
  
  const mode = settings.value.pricing_mode
  
  if (mode === 'per_minute') {
    const pricePerMin = parseInt(settings.value.price_per_minute || 0)
    
    if (specialPriceEnabled.value) {
      // Convert threshold to minutes based on unit
      let thresholdMinutes = parseInt(settings.value.price_threshold || 60)
      const unit = settings.value.threshold_unit || 'minute'
      
      if (unit === 'hour') thresholdMinutes *= 60
      else if (unit === 'second') thresholdMinutes /= 60
      
      if (durationMinutes > thresholdMinutes) {
        const beforeThreshold = thresholdMinutes * pricePerMin
        const afterMinutes = durationMinutes - thresholdMinutes
        const afterPrice = afterMinutes * parseInt(settings.value.price_after_first_hour || 0)
        return beforeThreshold + afterPrice
      } else {
        return durationMinutes * pricePerMin
      }
    } else {
      return durationMinutes * pricePerMin
    }
  }
  
  if (mode === 'per_hour') {
    const hours = Math.ceil(durationMinutes / 60)
    const pricePerHour = parseInt(settings.value.price_first_hour || 0)
    
    if (specialPriceEnabled.value) {
      // Convert threshold to hours based on unit
      let thresholdHours = parseInt(settings.value.price_threshold || 1)
      const unit = settings.value.threshold_unit || 'hour'
      
      if (unit === 'minute') thresholdHours /= 60
      else if (unit === 'second') thresholdHours /= 3600
      
      const thresholdHoursCeil = Math.ceil(thresholdHours)
      
      if (hours > thresholdHoursCeil) {
        const beforeThreshold = thresholdHoursCeil * pricePerHour
        const afterHours = hours - thresholdHoursCeil
        const afterPrice = afterHours * parseInt(settings.value.price_after_first_hour || 0)
        return beforeThreshold + afterPrice
      } else {
        return hours * pricePerHour
      }
    } else {
      return hours * pricePerHour
    }
  }
  
  return 0
}

function getStatusLabel(status) {
  const labels = {
    active: 'Aktif',
    parked: 'Parkir',
    exiting: 'Keluar',
    done: 'Selesai',
    expired: 'Expired'
  }
  return labels[status] || status
}

function formatDateTime(isoStr) {
  if (!isoStr) return '—'
  const date = new Date(isoStr)
  return date.toLocaleString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

function formatNumber(num) {
  return new Intl.NumberFormat('id-ID').format(num)
}

function getUnitLabel(unit) {
  const labels = {
    second: 'detik',
    minute: 'menit',
    hour: 'jam'
  }
  return labels[unit] || 'jam'
}

function viewImage(url) {
  if (url) selectedImage.value = url
}

async function handleLogout() {
  try {
    await supabase.auth.signOut()
    const adminPath = import.meta.env.VITE_ADMIN_PATH || '/admin'
    router.push(`${adminPath}/login`)
  } catch (err) {
    console.error('Logout error:', err)
  }
}

// Realtime subscription
let realtimeChannel = null

function setupRealtime() {
  realtimeChannel = supabase
    .channel('admin-tickets')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'tickets' }, () => {
      fetchTickets()
    })
    .on('postgres_changes', { event: '*', schema: 'public', table: 'parking_slots' }, () => {
      fetchSlots()
    })
    .subscribe()
}

// ===== GATE MANAGEMENT =====

async function fetchGates() {
  const { data } = await supabase.from('exit_gates').select('*').order('gate_number')
  exitGates.value = data || []
}

async function fetchGateAccounts() {
  const { data } = await supabase.from('gate_accounts').select('*').order('username')
  gateAccounts.value = data || []
}

function openAddGate() {
  editingGate.value = null
  gateForm.value = { gate_number: '', name: '', lat: null, lng: null }
  showGateModal.value = true
}

function editGate(gate) {
  editingGate.value = gate
  gateForm.value = { ...gate }
  showGateModal.value = true
}

async function saveGate() {
  try {
    const payload = {
      gate_number: parseInt(gateForm.value.gate_number),
      name: gateForm.value.name,
      lat: gateForm.value.lat ? parseFloat(gateForm.value.lat) : null,
      lng: gateForm.value.lng ? parseFloat(gateForm.value.lng) : null
    }

    if (editingGate.value) {
      const { error } = await supabase.from('exit_gates').update(payload).eq('id', editingGate.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('exit_gates').insert([payload])
      if (error) throw error
    }

    showGateModal.value = false
    showToast('Gate berhasil disimpan', 'success')
    fetchGates()
  } catch (err) {
    showToast('Gagal: ' + err.message, 'error')
  }
}

function deleteGate(gate) {
  showConfirm({
    title: `Hapus Gate ${gate.gate_number}`,
    message: `Hapus permanen gate <b>${gate.gate_number} - ${gate.name}</b>?`,
    confirmText: 'Hapus Gate',
    danger: true,
    onConfirm: async () => {
      const { error } = await supabase.from('exit_gates').delete().eq('id', gate.id)
      if (error) { showToast('❌ Gagal hapus gate: ' + error.message, 'error'); return }
      fetchGates()
      showToast('✅ Gate dihapus', 'success')
    }
  })
}

function openAddGateAccount() {
  gateAccountForm.value = { username: '', password: '' }
  showGateAccountModal.value = true
}

async function saveGateAccount() {
  try {
    const { error } = await supabase.from('gate_accounts').insert([{
      username: gateAccountForm.value.username,
      password: gateAccountForm.value.password
    }])
    if (error) throw error
    showGateAccountModal.value = false
    showToast('Akun berhasil dibuat', 'success')
    fetchGateAccounts()
  } catch (err) {
    showToast('Gagal: ' + err.message, 'error')
  }
}

function deleteGateAccount(acc) {
  showConfirm({
    title: `Hapus Akun "${acc.username}"`,
    message: `Hapus permanen akun petugas <b>${acc.username}</b>? Akun ini tidak bisa login lagi.`,
    confirmText: 'Hapus Akun',
    danger: true,
    onConfirm: async () => {
      const { error } = await supabase.from('gate_accounts').delete().eq('id', acc.id)
      if (error) { showToast('❌ Gagal hapus akun: ' + error.message, 'error'); return }
      fetchGateAccounts()
      showToast('✅ Akun dihapus', 'success')
    }
  })
}

// ===== LIFECYCLE =====

onMounted(async () => {
  loadDebugMode()
  fetchTickets()
  fetchSlots()
  fetchAreas()
  fetchGates()
  fetchGateAccounts()
  setupRealtime()
  subscribeMqttStatus()
  startUptimeCounter()

  // Load initial MQTT state dari settings
  await fetchSettings()
  const { data: mqttRows } = await supabase
    .from('settings')
    .select('key, value')
    .in('key', ['mqtt_status', 'mqtt_connected_at', 'mqtt_messages'])
  if (mqttRows) {
    mqttRows.forEach(r => {
      if (r.key === 'mqtt_status') mqttStatus.value = r.value || 'offline'
      if (r.key === 'mqtt_connected_at') mqttConnectedAt.value = r.value || null
      if (r.key === 'mqtt_messages') mqttMessages.value = parseInt(r.value) || 0
    })
  }
  await fetchMqttLogs()

  // Polling fallback tiap 3 detik - handle kasus realtime settings ga aktif
  mqttPollInterval = setInterval(pollMqttState, 500)
})

onUnmounted(() => {
  if (realtimeChannel) supabase.removeChannel(realtimeChannel)
  if (mqttRealtimeChannel) supabase.removeChannel(mqttRealtimeChannel)
  if (mqttUptimeTimer) clearInterval(mqttUptimeTimer)
  if (mqttPollInterval) clearInterval(mqttPollInterval)
})
</script>

<style scoped>
.admin-page {
  min-height: 100vh;
  background: #0a0f1e;
  color: #f1f5f9;
  font-family: var(--font);
  padding: 24px;
}

/* Header */
.admin-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
  padding-bottom: 20px;
  border-bottom: 1px solid rgba(255,255,255,0.08);
}

.admin-logo {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 20px;
  font-weight: 800;
  color: #a5b4fc;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

/* Debug Toggle */
.debug-toggle {
  display: flex;
  align-items: center;
  gap: 12px;
}

.toggle-label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  user-select: none;
}

.toggle-label input[type="checkbox"] {
  display: none;
}

.toggle-slider {
  position: relative;
  width: 48px;
  height: 26px;
  background: rgba(255,255,255,0.1);
  border-radius: 100px;
  transition: background 0.3s;
}

.toggle-slider::before {
  content: '';
  position: absolute;
  top: 3px;
  left: 3px;
  width: 20px;
  height: 20px;
  background: white;
  border-radius: 50%;
  transition: transform 0.3s;
}

.toggle-label input:checked + .toggle-slider {
  background: #6366f1;
}

.toggle-label input:checked + .toggle-slider::before {
  transform: translateX(22px);
}

.toggle-text {
  font-size: 14px;
  font-weight: 600;
  color: #94a3b8;
}

/* Logout Button */
.btn-logout {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  background: rgba(239,68,68,0.1);
  border: 1px solid rgba(239,68,68,0.3);
  border-radius: 10px;
  color: #f87171;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-logout:hover {
  background: rgba(239,68,68,0.15);
  border-color: rgba(239,68,68,0.4);
}

/* Tabs Navigation */
.tabs-nav {
  display: flex;
  gap: 8px;
  margin-bottom: 24px;
  border-bottom: 1px solid rgba(255,255,255,0.08);
  padding-bottom: 0;
}

.tab-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  color: #64748b;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
  bottom: -1px;
}

.tab-btn:hover {
  color: #94a3b8;
  background: rgba(255,255,255,0.02);
}

.tab-btn.active {
  color: #6366f1;
  border-bottom-color: #6366f1;
}

.tab-content {
  animation: fadeIn 0.3s ease;
}

.tab-panel {
  animation: slideIn 0.3s ease;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Stats Section */
.stats-section {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 20px;
  margin-bottom: 32px;
}

.stat-card {
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.stat-icon.stat-blue { background: rgba(59,130,246,0.15); color: #3b82f6; }
.stat-icon.stat-yellow { background: rgba(245,158,11,0.15); color: #f59e0b; }
.stat-icon.stat-green { background: rgba(16,185,129,0.15); color: #10b981; }
.stat-icon.stat-purple { background: rgba(139,92,246,0.15); color: #8b5cf6; }

.stat-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-label {
  font-size: 13px;
  color: #64748b;
  font-weight: 500;
}

.stat-value {
  font-size: 24px;
  font-weight: 800;
  color: #f1f5f9;
  font-family: var(--font-mono);
}

/* Filters */
.filters-section {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 24px;
  flex-wrap: wrap;
}

.filter-group {
  display: flex;
  gap: 8px;
}

.filter-btn {
  padding: 8px 16px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 10px;
  color: #94a3b8;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.filter-btn:hover {
  background: rgba(255,255,255,0.08);
  color: #f1f5f9;
}

.filter-btn.active {
  background: #6366f1;
  border-color: #6366f1;
  color: white;
}

.search-input {
  flex: 1;
  min-width: 240px;
  padding: 10px 16px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 10px;
  color: #f1f5f9;
  font-size: 14px;
  outline: none;
  transition: border-color 0.2s;
}

.search-input:focus {
  border-color: #6366f1;
}

.search-input::placeholder {
  color: #475569;
}

/* Table Section */
.table-section {
  background: rgba(255,255,255,0.02);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 32px;
}

.table-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.table-header h2 {
  font-size: 18px;
  font-weight: 700;
  color: #f1f5f9;
}

.btn-refresh {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 8px;
  color: #94a3b8;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-refresh:hover {
  background: rgba(255,255,255,0.08);
  color: #f1f5f9;
}

.table-wrap {
  overflow-x: auto;
  border-radius: 12px;
  border: 1px solid rgba(255,255,255,0.08);
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.data-table th {
  padding: 12px 16px;
  background: rgba(255,255,255,0.04);
  color: #64748b;
  font-weight: 600;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  text-align: left;
  border-bottom: 1px solid rgba(255,255,255,0.08);
}

.data-table td {
  padding: 14px 16px;
  border-bottom: 1px solid rgba(255,255,255,0.05);
  color: #f1f5f9;
}

.data-table tbody tr {
  transition: background 0.2s;
}

.data-table tbody tr:hover {
  background: rgba(255,255,255,0.02);
}

.ticket-image {
  width: 60px;
  height: 40px;
  border-radius: 6px;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.2s;
}

.ticket-image:hover {
  transform: scale(1.05);
}

.ticket-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.no-image {
  color: #475569;
}

.ticket-code {
  font-family: var(--font-mono);
  color: #a5b4fc;
  font-weight: 600;
}

.ticket-cost {
  font-family: var(--font-mono);
  color: #10b981;
  font-weight: 700;
  font-size: 12px;
}

.status-badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 100px;
  font-size: 11px;
  font-weight: 600;
}

.status-badge.status-active { background: rgba(59,130,246,0.15); color: #3b82f6; }
.status-badge.status-parked { background: rgba(245,158,11,0.15); color: #f59e0b; }
.status-badge.status-exiting { background: rgba(139,92,246,0.15); color: #8b5cf6; }
.status-badge.status-done { background: rgba(16,185,129,0.15); color: #10b981; }
.status-badge.status-expired { background: rgba(239,68,68,0.15); color: #ef4444; }

/* Pagination */
.pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin-top: 20px;
}

.page-btn {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 8px;
  color: #94a3b8;
  cursor: pointer;
  transition: all 0.2s;
}

.page-btn:hover:not(:disabled) {
  background: rgba(255,255,255,0.08);
  color: #f1f5f9;
}

.page-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.page-info {
  font-size: 13px;
  color: #64748b;
}

/* Slots Section */
.slots-section {
  background: rgba(255,255,255,0.02);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px;
  padding: 24px;
}

.slots-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}

.slots-header h2 {
  font-size: 18px;
  font-weight: 700;
  color: #f1f5f9;
}

.btn-add-area {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  border: none;
  border-radius: 10px;
  color: white;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-add-area:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(99,102,241,0.3);
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #64748b;
}

.empty-state svg {
  margin: 0 auto 16px;
  opacity: 0.3;
}

.empty-state p {
  font-size: 15px;
  margin-bottom: 16px;
}

.btn-primary-sm {
  padding: 10px 20px;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  border: none;
  border-radius: 10px;
  color: white;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}

/* Areas List */
.areas-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.area-card {
  background: rgba(255,255,255,0.02);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 14px;
  padding: 20px;
}

.area-card.unassigned-area {
  background: rgba(245,158,11,0.05);
  border-color: rgba(245,158,11,0.3);
}

.area-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 12px;
  padding-bottom: 12px;
  border-bottom: 1px solid rgba(255,255,255,0.05);
}

/* MQTT Prefix per Area */
.area-mqtt-prefix {
  margin-bottom: 16px;
  padding: 12px 14px;
  background: rgba(99,102,241,0.05);
  border: 1px solid rgba(99,102,241,0.15);
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.mqtt-prefix-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  font-weight: 700;
  color: #6366f1;
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

.mqtt-prefix-input-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}

.mqtt-prefix-input {
  flex: 1;
  padding: 8px 12px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 8px;
  color: #f1f5f9;
  font-size: 13px;
  font-family: var(--font-mono);
  outline: none;
  transition: border-color 0.2s;
}

.mqtt-prefix-input:focus {
  border-color: #6366f1;
}

.mqtt-prefix-hint {
  font-size: 11px;
  color: #475569;
  white-space: nowrap;
}

.mqtt-prefix-example {
  font-size: 11px;
  color: #64748b;
}

.mqtt-prefix-example code {
  background: rgba(99,102,241,0.15);
  color: #a5b4fc;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: var(--font-mono);
  font-size: 11px;
}

/* Slot Tooltip */
.slot-coords {
  font-size: 8px;
  color: #64748b;
  font-family: var(--font-mono);
  margin-top: 4px;
}

.slot-no-coords {
  color: #ef4444;
  opacity: 0.6;
}

.slot-tooltip {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 3px;
  margin-top: 4px;
  padding-top: 4px;
  border-top: 1px solid rgba(255,255,255,0.06);
  position: relative;
  cursor: default;
}

.slot-tooltip svg {
  color: #475569;
  flex-shrink: 0;
}

.slot-tooltip-text {
  font-size: 9px;
  color: #475569;
  font-family: var(--font-mono);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 80px;
}

.slot-card:hover .slot-tooltip-text {
  position: absolute;
  bottom: calc(100% + 8px);
  left: 50%;
  transform: translateX(-50%);
  background: #1e293b;
  border: 1px solid rgba(99,102,241,0.4);
  color: #a5b4fc;
  padding: 5px 10px;
  border-radius: 6px;
  font-size: 11px;
  max-width: 200px;
  white-space: nowrap;
  overflow: visible;
  text-overflow: unset;
  z-index: 10;
  box-shadow: 0 4px 12px rgba(0,0,0,0.4);
}

.slot-card:hover .slot-tooltip-text::after {
  content: '';
  position: absolute;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  border: 5px solid transparent;
  border-top-color: rgba(99,102,241,0.4);
}

.area-info h3 {
  font-size: 16px;
  font-weight: 700;
  color: #f1f5f9;
  margin-bottom: 4px;
}

.area-desc {
  font-size: 13px;
  color: #64748b;
  margin-bottom: 6px;
}

.area-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  margin-top: 6px;
}

.area-stats {
  display: inline-flex;
  align-items: center;
  padding: 3px 10px;
  background: rgba(99,102,241,0.15);
  border-radius: 100px;
  font-size: 11px;
  color: #a5b4fc;
  font-weight: 600;
}

.area-mqtt-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 10px;
  background: rgba(16,185,129,0.1);
  border: 1px solid rgba(16,185,129,0.2);
  border-radius: 100px;
  font-size: 11px;
  color: #34d399;
  font-weight: 600;
  font-family: var(--font-mono);
}

.area-mqtt-empty {
  background: rgba(255,255,255,0.04);
  border-color: rgba(255,255,255,0.08);
  color: #475569;
}

.area-actions {
  display: flex;
  gap: 6px;
}

.btn-icon {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 8px;
  color: #94a3b8;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-icon:hover {
  background: rgba(255,255,255,0.08);
  color: #f1f5f9;
}

.btn-icon.btn-add-slot {
  color: #10b981;
  border-color: rgba(16,185,129,0.3);
}

.btn-icon.btn-add-slot:hover {
  background: rgba(16,185,129,0.1);
}

.btn-icon.btn-delete {
  color: #f87171;
  border-color: rgba(239,68,68,0.3);
}

.btn-icon.btn-delete:hover {
  background: rgba(239,68,68,0.1);
}

.slots-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(110px, 1fr));
  gap: 10px;
}

.slot-card {
  background: rgba(16,185,129,0.08);
  border: 1px solid rgba(16,185,129,0.25);
  border-radius: 12px;
  padding: 14px 10px 10px;
  text-align: center;
  transition: all 0.2s;
  position: relative;
  cursor: pointer;
}

.slot-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(16,185,129,0.15);
  border-color: rgba(16,185,129,0.5);
}

.slot-card.occupied {
  background: rgba(239,68,68,0.08);
  border-color: rgba(239,68,68,0.25);
}

.slot-card.occupied:hover {
  box-shadow: 0 6px 16px rgba(239,68,68,0.15);
  border-color: rgba(239,68,68,0.5);
}

.slot-card.slot-debug {
  border-style: dashed;
}

.slot-top {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-bottom: 4px;
}

.slot-led {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.led-green {
  background: #10b981;
  box-shadow: 0 0 6px #10b981, 0 0 12px rgba(16,185,129,0.4);
  animation: glow-green 2s ease infinite;
}

.led-red {
  background: #ef4444;
  box-shadow: 0 0 6px #ef4444, 0 0 12px rgba(239,68,68,0.4);
  animation: glow-red 2s ease infinite;
}

@keyframes glow-green {
  0%, 100% { box-shadow: 0 0 6px #10b981, 0 0 12px rgba(16,185,129,0.4); }
  50% { box-shadow: 0 0 3px #10b981, 0 0 6px rgba(16,185,129,0.2); }
}

@keyframes glow-red {
  0%, 100% { box-shadow: 0 0 6px #ef4444, 0 0 12px rgba(239,68,68,0.4); }
  50% { box-shadow: 0 0 3px #ef4444, 0 0 6px rgba(239,68,68,0.2); }
}

.slot-name {
  font-size: 20px;
  font-weight: 800;
  color: #f1f5f9;
  font-family: var(--font-mono);
}

.slot-status-text {
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 8px;
}

.text-green { color: #34d399; }
.text-red { color: #f87171; }

.slot-meta {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding-top: 8px;
  border-top: 1px solid rgba(255,255,255,0.06);
}

.slot-coord-badge,
.slot-mqtt-badge {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 9px;
  font-weight: 600;
}

.slot-coord-badge {
  background: rgba(16,185,129,0.15);
  color: #34d399;
}

.slot-coord-badge.no-gps {
  background: rgba(239,68,68,0.1);
  color: #f87171;
}

.slot-mqtt-badge {
  background: rgba(99,102,241,0.15);
  color: #a5b4fc;
  padding: 2px 5px;
}

.slot-debug-badge {
  position: absolute;
  top: 4px;
  right: 4px;
  font-size: 7px;
  font-weight: 800;
  color: #f59e0b;
  background: rgba(245,158,11,0.2);
  padding: 1px 5px;
  border-radius: 3px;
  letter-spacing: 0.04em;
}

/* Modal */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.85);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 24px;
  animation: fadeIn 0.2s;
}

.modal-content {
  position: relative;
  max-width: 90vw;
  max-height: 90vh;
  background: #111827;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 32px 80px rgba(0,0,0,0.8);
}

.modal-content img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.modal-close {
  position: absolute;
  top: 16px;
  right: 16px;
  width: 40px;
  height: 40px;
  background: rgba(0,0,0,0.6);
  border: none;
  border-radius: 50%;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
  z-index: 1;
}

.modal-close:hover {
  background: rgba(0,0,0,0.8);
}

/* Form Modal */
.modal-form {
  background: rgba(17,24,39,0.95);
  border: 1px solid rgba(99,102,241,0.3);
  border-radius: 16px;
  max-width: 600px;
  width: 100%;
  box-shadow: 0 32px 80px rgba(0,0,0,0.8);
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid rgba(255,255,255,0.08);
}

.modal-header h3 {
  font-size: 18px;
  font-weight: 700;
  color: #f1f5f9;
}

.modal-header .modal-close {
  position: static;
  width: 32px;
  height: 32px;
  background: rgba(255,255,255,0.04);
  border-radius: 8px;
}

.form-content {
  padding: 24px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: #94a3b8;
  margin-bottom: 8px;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 10px 14px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 10px;
  color: #f1f5f9;
  font-size: 14px;
  outline: none;
  transition: all 0.2s;
  font-family: var(--font);
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  border-color: #6366f1;
  box-shadow: 0 0 0 3px rgba(99,102,241,0.15);
}

.form-group input::placeholder,
.form-group textarea::placeholder {
  color: #475569;
}

.form-group textarea {
  resize: vertical;
}

.form-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  margin-top: 24px;
}

/* Tombol hapus slot digeser ke kiri */
.form-actions .btn-delete-slot {
  margin-right: auto;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 16px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  border: 1.5px solid rgba(239,68,68,0.4);
  background: rgba(239,68,68,0.08);
  color: #f87171;
  transition: all 0.2s;
}

.form-actions .btn-delete-slot:hover {
  background: rgba(239,68,68,0.18);
  border-color: #ef4444;
  color: #fca5a5;
}


.btn-cancel,
.btn-save {
  padding: 10px 20px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  border: none;
}

.btn-cancel {
  background: rgba(255,255,255,0.04);
  color: #94a3b8;
}

.btn-cancel:hover {
  background: rgba(255,255,255,0.08);
  color: #f1f5f9;
}

.btn-save {
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  color: white;
}

.btn-save:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(99,102,241,0.3);
}

/* Settings Tab */
.settings-container {
  max-width: 900px;
  margin: 0 auto;
}

.settings-section {
  background: rgba(255,255,255,0.02);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
}

.settings-section h2 {
  font-size: 18px;
  font-weight: 700;
  color: #f1f5f9;
  margin-bottom: 20px;
}

.section-desc {
  font-size: 13px;
  color: #64748b;
  margin-bottom: 16px;
}

.settings-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.input-with-prefix {
  display: flex;
  align-items: center;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 10px;
  overflow: hidden;
}

.input-with-prefix .prefix {
  padding: 10px 14px;
  background: rgba(255,255,255,0.04);
  color: #94a3b8;
  font-weight: 600;
  font-size: 14px;
  border-right: 1px solid rgba(255,255,255,0.08);
}

.input-with-prefix input {
  flex: 1;
  padding: 10px 14px;
  background: transparent;
  border: none;
  color: #f1f5f9;
  font-size: 14px;
  outline: none;
}

.input-group-inline {
  display: flex;
  align-items: center;
  gap: 8px;
}

.input-group-inline input,
.input-group-inline select {
  padding: 10px 14px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 10px;
  color: #f1f5f9;
  font-size: 14px;
  outline: none;
  font-family: var(--font);
}

.input-group-inline input:focus,
.input-group-inline select:focus {
  border-color: #6366f1;
  box-shadow: 0 0 0 3px rgba(99,102,241,0.1);
}

/* Toggle Switch */
.toggle-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px;
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 10px;
}

.toggle-row-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.toggle-row-title {
  font-size: 14px;
  font-weight: 600;
  color: #f1f5f9;
}

.toggle-row-desc {
  font-size: 12px;
  color: #64748b;
}

.toggle-switch {
  position: relative;
  width: 44px;
  height: 24px;
  background: rgba(255,255,255,0.1);
  border: none;
  border-radius: 100px;
  cursor: pointer;
  transition: background 0.25s ease;
  flex-shrink: 0;
}

.toggle-switch.active {
  background: #6366f1;
}

.toggle-knob {
  position: absolute;
  top: 3px;
  left: 3px;
  width: 18px;
  height: 18px;
  background: white;
  border-radius: 50%;
  transition: transform 0.25s ease;
  box-shadow: 0 1px 4px rgba(0,0,0,0.3);
}

.toggle-switch.active .toggle-knob {
  transform: translateX(20px);
}

.toggle-content {
  padding: 16px;
  background: rgba(99,102,241,0.05);
  border: 1px solid rgba(99,102,241,0.15);
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.input-with-prefix .suffix {
  padding: 10px 14px;
  background: rgba(255,255,255,0.04);
  color: #64748b;
  font-size: 13px;
  border-left: 1px solid rgba(255,255,255,0.08);
  white-space: nowrap;
}

.btn-save-settings {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px 24px;
  background: linear-gradient(135deg, #10b981, #059669);
  border: none;
  border-radius: 8px;
  color: white;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 2px 8px rgba(16,185,129,0.3);
}

.btn-save-settings:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(16,185,129,0.4);
}

.btn-save-settings:active {
  transform: translateY(0);
}

.color-picker-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.color-input {
  width: 44px;
  height: 36px;
  padding: 2px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 8px;
  cursor: pointer;
}

.color-value {
  font-size: 13px;
  font-family: var(--font-mono);
  color: #a5b4fc;
}

.form-hint {
  font-size: 12px;
  color: #64748b;
  margin-top: 4px;
}

.pricing-preview {
  background: rgba(99,102,241,0.1);
  border: 1px solid rgba(99,102,241,0.3);
  border-radius: 12px;
  padding: 16px;
  margin-top: 8px;
}

.pricing-preview h4 {
  font-size: 14px;
  font-weight: 700;
  color: #a5b4fc;
  margin-bottom: 10px;
}

.pricing-preview ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.pricing-preview li {
  font-size: 13px;
  color: #e0e7ff;
  padding: 4px 0;
}

/* MQTT Status Bar */
.mqtt-status-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 10px;
}

.mqtt-status-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.mqtt-led {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}

.mqtt-led-on {
  background: #10b981;
  box-shadow: 0 0 8px #10b981;
  animation: pulse 2s ease infinite;
}

.mqtt-led-off {
  background: #ef4444;
  box-shadow: 0 0 4px rgba(239,68,68,0.4);
}

.mqtt-status-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.mqtt-status-text {
  font-size: 13px;
  font-weight: 600;
  color: #f1f5f9;
}

.mqtt-uptime {
  font-size: 11px;
  color: #10b981;
  font-family: var(--font-mono);
}

.mqtt-log-toggle {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 5px 10px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 6px;
  color: #94a3b8;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}

.mqtt-log-toggle:hover {
  background: rgba(255,255,255,0.08);
  color: #f1f5f9;
}

/* Log Panel */
.mqtt-log-panel {
  max-height: 200px;
  overflow-y: auto;
  margin-top: 10px;
  padding: 8px;
  background: rgba(0,0,0,0.3);
  border-radius: 8px;
  border: 1px solid rgba(255,255,255,0.06);
}

.mqtt-log-empty {
  font-size: 12px;
  color: #475569;
  text-align: center;
  padding: 12px;
}

.mqtt-log-item {
  display: flex;
  gap: 8px;
  padding: 4px 6px;
  font-size: 11px;
  border-radius: 4px;
}

.mqtt-log-item:hover {
  background: rgba(255,255,255,0.03);
}

.mqtt-log-time {
  color: #475569;
  font-family: var(--font-mono);
  flex-shrink: 0;
}

.mqtt-log-msg {
  color: #94a3b8;
  word-break: break-all;
}

.mqtt-log-success .mqtt-log-msg { color: #34d399; }
.mqtt-log-error .mqtt-log-msg { color: #f87171; }
.mqtt-log-message .mqtt-log-msg { color: #a5b4fc; }

/* MQTT Actions */
.mqtt-actions {
  display: flex;
  gap: 10px;
  margin-top: 14px;
}

.btn-test-mqtt {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 10px 18px;
  background: rgba(99,102,241,0.15);
  border: 1px solid rgba(99,102,241,0.3);
  border-radius: 10px;
  color: #a5b4fc;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  flex: 1;
}

.btn-test-mqtt:hover {
  background: rgba(99,102,241,0.25);
}

.btn-disconnect-mqtt {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 10px 18px;
  background: rgba(239,68,68,0.15);
  border: 1px solid rgba(239,68,68,0.3);
  border-radius: 10px;
  color: #f87171;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  flex: 1;
}

.btn-disconnect-mqtt:hover {
  background: rgba(239,68,68,0.25);
}

.btn-save-settings {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 10px 20px;
  background: linear-gradient(135deg, #10b981, #059669);
  border: none;
  border-radius: 10px;
  color: white;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 4px 12px rgba(16,185,129,0.3);
}

.btn-save-settings:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 16px rgba(16,185,129,0.4);
}

.btn-save-settings:active {
  transform: translateY(0);
}

.mqtt-slots-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.mqtt-area-group h4 {
  font-size: 15px;
  font-weight: 700;
  color: #f1f5f9;
  margin-bottom: 12px;
}

.mqtt-slot-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 12px;
}

.mqtt-slot-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.mqtt-slot-item label {
  font-size: 12px;
  font-weight: 600;
  color: #94a3b8;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.mqtt-slot-item input {
  padding: 8px 12px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 8px;
  color: #f1f5f9;
  font-size: 13px;
  font-family: var(--font-mono);
  outline: none;
  transition: all 0.2s;
}

.mqtt-slot-item input:focus {
  border-color: #6366f1;
  box-shadow: 0 0 0 3px rgba(99,102,241,0.15);
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* Toast Notification */
.toast-container {
  position: fixed;
  top: 24px;
  right: 24px;
  z-index: 99999;
  pointer-events: none;
}

.toast-stack {
  display: flex;
  flex-direction: column;
  gap: 10px;
  align-items: flex-end;
}

.toast {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 13px 16px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  box-shadow: 0 8px 32px rgba(0,0,0,0.5);
  min-width: 260px;
  max-width: 380px;
  pointer-events: all;
}

.toast.success { background: linear-gradient(135deg, #10b981, #059669); color: white; }
.toast.error   { background: linear-gradient(135deg, #ef4444, #dc2626); color: white; }
.toast.info    { background: linear-gradient(135deg, #6366f1, #4f46e5); color: white; }

.toast span {
  flex: 1;
}

.toast-close {
  background: none;
  border: none;
  color: rgba(255,255,255,0.7);
  cursor: pointer;
  padding: 2px;
  display: flex;
  align-items: center;
  flex-shrink: 0;
  transition: color 0.15s;
}

.toast-close:hover {
  color: white;
}

.toast-slide-enter-active { transition: all 0.3s ease; }
.toast-slide-leave-active { transition: all 0.25s ease; }
.toast-slide-enter-from   { opacity: 0; transform: translateX(80px); }
.toast-slide-leave-to     { opacity: 0; transform: translateX(80px); }
.toast-slide-move         { transition: transform 0.3s ease; }

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* Gate List */
.gate-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.gate-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px;
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 10px;
}

.gate-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.gate-number {
  font-size: 15px;
  font-weight: 700;
  color: #f1f5f9;
}

.gate-name {
  font-size: 13px;
  color: #94a3b8;
}

.gate-coords {
  font-size: 11px;
  color: #64748b;
  font-family: var(--font-mono);
}

.online-dot, .offline-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 4px;
}
.online-dot { background: #10b981; }
.offline-dot { background: #ef4444; }

/* Danger Zone */
.danger-zone {
  background: rgba(239,68,68,0.04);
  border: 1.5px solid rgba(239,68,68,0.35);
  border-radius: 16px;
  padding: 24px;
  margin-top: 8px;
}

.danger-zone-header {
  display: flex;
  align-items: flex-start;
  gap: 14px;
  margin-bottom: 20px;
  color: #ef4444;
}

.danger-zone-header svg {
  flex-shrink: 0;
  margin-top: 2px;
}

.danger-zone-header h2 {
  font-size: 16px;
  font-weight: 700;
  color: #ef4444;
  margin: 0 0 4px;
}

.danger-zone-header p {
  font-size: 13px;
  color: #f87171;
  margin: 0;
  opacity: 0.8;
}

.danger-actions {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.danger-action-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px 16px;
  background: rgba(239,68,68,0.06);
  border: 1px solid rgba(239,68,68,0.15);
  border-radius: 10px;
}

.danger-action-full {
  background: rgba(239,68,68,0.1);
  border-color: rgba(239,68,68,0.3);
}

.danger-action-info {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.danger-action-info strong {
  font-size: 14px;
  font-weight: 600;
  color: #fca5a5;
}

.danger-action-info span {
  font-size: 12px;
  color: #94a3b8;
}

.btn-danger {
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 9px 16px;
  background: rgba(239,68,68,0.12);
  border: 1px solid rgba(239,68,68,0.4);
  border-radius: 8px;
  color: #fca5a5;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s;
  flex-shrink: 0;
}

.btn-danger:hover:not(:disabled) {
  background: rgba(239,68,68,0.25);
  border-color: #ef4444;
  color: #fff;
}

.btn-danger:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.btn-danger-full {
  background: rgba(239,68,68,0.2);
  border-color: #ef4444;
  color: #fff;
  font-size: 14px;
  padding: 10px 20px;
}

.btn-danger-full:hover:not(:disabled) {
  background: #ef4444;
  box-shadow: 0 4px 16px rgba(239,68,68,0.4);
}

.danger-btn-group {
  display: flex;
  gap: 8px;
}

.danger-btn-group-full {
  display: flex;
  gap: 12px;
  width: 100%;
}
.danger-btn-group-full .btn-danger {
  flex: 1;
  justify-content: center;
}

.btn-danger-solid {
  background: rgba(220, 38, 38, 0.9);
  color: white;
  border-color: #dc2626;
  box-shadow: 0 2px 8px rgba(220, 38, 38, 0.3);
}

.btn-danger-solid:hover:not(:disabled) {
  background: #b91c1c;
  border-color: #991b1b;
  box-shadow: 0 4px 12px rgba(220, 38, 38, 0.5);
}

/* Custom Confirm Modal */
.confirm-overlay {
  z-index: 9999; /* di atas modal lain kalau bertumpuk */
}

.confirm-modal {
  max-width: 450px !important;
}

.confirm-message {
  font-size: 15px;
  line-height: 1.5;
  color: #e2e8f0;
  margin-bottom: 24px;
}

.confirm-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

.confirm-danger .modal-header h3 {
  color: #ef4444;
}

.confirm-danger .modal-header {
  border-bottom-color: rgba(239,68,68,0.2);
}
</style>
