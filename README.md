# 🚀 Cara Install Cloud9 IDE dengan Password Authentication

Panduan lengkap instalasi Cloud9 IDE menggunakan Docker dan Nginx sebagai reverse proxy dengan basic authentication untuk keamanan.

## 📋 Prerequisites

- VPS/Server dengan Ubuntu 20.04+ atau Debian 10+
- Docker sudah terinstall
- Akses root atau sudo privileges
- Port 80 dan 8000 tersedia

## 🔧 Instalasi

### Step 1: Install Nginx & Apache Utils

```bash
sudo apt update
sudo apt install nginx apache2-utils -y
```

### Step 2: Buat Username & Password

Buat credential untuk login Cloud9:

```bash
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

- Ketik password yang diinginkan (contoh: `Makan1321@`)
- Tekan Enter
- Ketik ulang password
- Tekan Enter

> **Note:** Username default adalah `admin`, bisa diganti sesuai kebutuhan.

### Step 3: Konfigurasi Nginx sebagai Reverse Proxy

Buat file konfigurasi baru:

```bash
sudo nano /etc/nginx/sites-available/cloud9
```

Paste konfigurasi berikut:

```nginx
server {
    listen 80;
    server_name _;

    location / {
        auth_basic "Cloud9 Login";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_buffering off;
        proxy_read_timeout 86400;
    }
}
```

**Save file:**
- Tekan `Ctrl+X`
- Tekan `Y`
- Tekan `Enter`

### Step 4: Aktifkan Konfigurasi Nginx

```bash
# Aktifkan site cloud9
sudo ln -s /etc/nginx/sites-available/cloud9 /etc/nginx/sites-enabled/

# Hapus default site
sudo rm /etc/nginx/sites-enabled/default

# Test konfigurasi
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx

# Enable nginx on boot
sudo systemctl enable nginx
```

### Step 5: Jalankan Cloud9 Container

Stop container lama jika ada:

```bash
docker stop cloud9 2>/dev/null
docker rm cloud9 2>/dev/null
```

Jalankan Cloud9 dengan akses root:

```bash
docker run -d \
  --name=cloud9 \
  -e PUID=0 \
  -e PGID=0 \
  -e TZ=Asia/Jakarta \
  -p 127.0.0.1:8000:8000 \
  -v /root/cloud9-workspace:/code \
  --restart unless-stopped \
  linuxserver/cloud9:latest
```

**Parameter penjelasan:**
- `PUID=0` & `PGID=0` - Menjalankan sebagai root
- `TZ=Asia/Jakarta` - Set timezone (sesuaikan dengan lokasi Anda)
- `127.0.0.1:8000:8000` - Bind ke localhost saja (keamanan)
- `/root/cloud9-workspace:/code` - Direktori workspace
- `--restart unless-stopped` - Auto-restart container

### Step 6: Verifikasi Instalasi

Cek status services:

```bash
# Cek nginx
sudo systemctl status nginx

# Cek container cloud9
docker ps | grep cloud9

# Cek log cloud9
docker logs cloud9

# Cek port listening
sudo netstat -tlnp | grep -E '80|8000'
```

## 🌐 Akses Cloud9

1. Buka browser (Chrome/Firefox/Safari)
2. Akses: `http://IP_SERVER_ANDA`
3. Akan muncul popup login
4. Masukkan credentials:
   - **Username:** `admin`
   - **Password:** `Makan1321@` (atau password yang Anda buat)

> **Tip:** Jika tidak muncul popup login, coba akses dengan Incognito/Private Window

## 🔒 Keamanan Tambahan

### 1. Firewall Configuration

```bash
# Install UFW
sudo apt install ufw -y

# Allow SSH (PENTING!)
sudo ufw allow 22

# Allow HTTP
sudo ufw allow 80

# Enable firewall
sudo ufw enable

# Cek status
sudo ufw status
```

### 2. Ganti Password

```bash
# Hapus password lama
sudo htpasswd -D /etc/nginx/.htpasswd admin

# Buat password baru
sudo htpasswd /etc/nginx/.htpasswd admin
```

### 3. Tambah User Baru

```bash
# Tambah user tanpa menghapus yang lama
sudo htpasswd /etc/nginx/.htpasswd username_baru
```

## 🛠️ Troubleshooting

### Cloud9 Stuck di Loading

```bash
# Restart container
docker restart cloud9

# Clear browser cache atau gunakan Incognito mode
```

### Nginx Error

```bash
# Cek log error
sudo tail -f /var/log/nginx/error.log

# Test konfigurasi
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

### Container Tidak Jalan

```bash
# Cek log error
docker logs cloud9

# Hapus dan buat ulang container
docker stop cloud9
docker rm cloud9
# Jalankan ulang perintah docker run di Step 5
```

### Port Already in Use

```bash
# Cek process yang menggunakan port
sudo netstat -tlnp | grep 8000
sudo netstat -tlnp | grep 80

# Kill process jika perlu
sudo kill -9 PID_NUMBER
```

## 📝 Perintah Berguna

### Docker Commands

```bash
# Start container
docker start cloud9

# Stop container
docker stop cloud9

# Restart container
docker restart cloud9

# Lihat log real-time
docker logs -f cloud9

# Hapus container
docker rm cloud9

# Update image
docker pull linuxserver/cloud9:latest
```

### Nginx Commands

```bash
# Start nginx
sudo systemctl start nginx

# Stop nginx
sudo systemctl stop nginx

# Restart nginx
sudo systemctl restart nginx

# Reload config tanpa downtime
sudo systemctl reload nginx

# Test konfigurasi
sudo nginx -t
```

## 🔄 Update Cloud9

```bash
# Stop container lama
docker stop cloud9
docker rm cloud9

# Pull image terbaru
docker pull linuxserver/cloud9:latest

# Jalankan ulang dengan perintah di Step 5
```
## 🔄 INSTALL PYTHON 3

```bash
apt update
apt install python3 -y
sudo apt install python3-pip

```
## 📚 Referensi

- [LinuxServer Cloud9 Docker Hub](https://hub.docker.com/r/linuxserver/cloud9)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Documentation](https://docs.docker.com/)

## ⚠️ Disclaimer

- Menjalankan Cloud9 sebagai root memiliki risiko keamanan
- Pastikan selalu menggunakan password yang kuat
- Jangan expose ke internet publik tanpa proteksi
- Backup data workspace secara berkala

## 📄 License

MIT License - Free to use and modify

---

**Dibuat dengan ❤️ untuk kemudahan deployment Cloud9 IDE**
