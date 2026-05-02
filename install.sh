#!/bin/bash

# Warna untuk output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}    🚀 SmartPark Deployment Script 🚀    ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# 1. Cek Node.js & NPM
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}[!] Node.js tidak ditemukan. Mencoba menginstall Node.js v20...${NC}"
    if command -v apt-get &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        echo -e "${RED}[X] OS tidak dikenali atau apt-get tidak tersedia. Silakan install Node.js secara manual.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}[✓] Node.js sudah terinstall: $(node -v)${NC}"
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}[X] NPM tidak ditemukan. Harap install NPM terlebih dahulu.${NC}"
    exit 1
else
    echo -e "${GREEN}[✓] NPM sudah terinstall: $(npm -v)${NC}"
fi

# 2. Cek & Install PM2
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}[!] PM2 tidak ditemukan. Menginstall PM2 secara global...${NC}"
    sudo npm install -g pm2
else
    echo -e "${GREEN}[✓] PM2 sudah terinstall.${NC}"
fi

# 3. Install Dependencies Web & Bridge
echo -e "\n${YELLOW}[!] Menginstall dependencies project...${NC}"
npm install

# 4. Setup File .env
echo -e "\n${YELLOW}[!] Mengecek file konfigurasi (.env)...${NC}"
if [ ! -f .env ]; then
    echo -e "${RED}[!] File .env belum ada!${NC}"
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}[✓] Berhasil membuat file .env dari .env.example.${NC}"
    else
        echo -e "${RED}[X] File .env.example juga tidak ditemukan!${NC}"
        exit 1
    fi
    echo -e "\n${RED}====================================================${NC}"
    echo -e "${RED}⚠️  PENTING: Konfigurasi Dibutuhkan! ⚠️${NC}"
    echo -e "${RED}====================================================${NC}"
    echo -e "Silakan buka file ${YELLOW}.env${NC} dan isi variabel yang dibutuhkan:"
    echo -e "1. ${YELLOW}VITE_SUPABASE_URL${NC}"
    echo -e "2. ${YELLOW}VITE_SUPABASE_ANON_KEY${NC}"
    echo -e "3. ${YELLOW}SUPABASE_SERVICE_KEY${NC} (Wajib untuk bridge)"
    echo -e ""
    echo -e "Setelah diisi, jalankan ulang script ini: ${GREEN}./install.sh${NC}"
    exit 0
else
    echo -e "${GREEN}[✓] File .env sudah ada.${NC}"
fi

# 5. Build Web Frontend (Opsional, biasa untuk VPS production)
# 5. Build & Serve Web Frontend
echo -e "\n${YELLOW}Apakah Anda ingin meng-host Web Frontend (UI) pakai PM2 di server ini? (y/n)${NC}"
read -p "> " SERVE_WEB
if [[ "$SERVE_WEB" == "y" || "$SERVE_WEB" == "Y" ]]; then
    echo -e "${YELLOW}[!] Mem-build web frontend...${NC}"
    npm run build
    
    echo -e "${YELLOW}Masukkan PORT untuk Web Frontend (default: 8080):${NC}"
    read -p "> " WEB_PORT
    WEB_PORT=${WEB_PORT:-8080}

    echo -e "${YELLOW}[!] Menjalankan Web Frontend di port ${WEB_PORT} via PM2...${NC}"
    if pm2 status | grep -q "smartpark-web"; then
        pm2 delete smartpark-web
    fi
    pm2 serve dist $WEB_PORT --name "smartpark-web" --spa
    echo -e "${GREEN}[✓] Web Frontend berjalan di port ${WEB_PORT}.${NC}"
fi

# 6. Jalankan/Restart MQTT Bridge pakai PM2
echo -e "\n${YELLOW}[!] Menjalankan service MQTT Bridge (Background) via PM2...${NC}"
if pm2 status | grep -q "smartpark-bridge"; then
    echo -e "${YELLOW}[!] Service 'smartpark-bridge' sudah berjalan. Me-restart service...${NC}"
    pm2 restart smartpark-bridge
else
    echo -e "${GREEN}[!] Memulai service 'smartpark-bridge' baru...${NC}"
    pm2 start mqtt-bridge/bridge.cjs --name "smartpark-bridge"
fi

# 7. Simpan PM2 agar otomatis jalan saat server restart
pm2 save

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN}🎉 DEPLOYMENT SELESAI! 🎉${NC}"
echo -e "${GREEN}==========================================${NC}"
echo -e "Cek status service: ${YELLOW}pm2 status${NC}"
if [[ "$SERVE_WEB" == "y" || "$SERVE_WEB" == "Y" ]]; then
    echo -e "Akses Web Frontend: ${YELLOW}http://<IP_VPS>:${WEB_PORT}${NC}"
fi
echo -e "Lihat log bridge  : ${YELLOW}pm2 logs smartpark-bridge${NC}"
echo ""
