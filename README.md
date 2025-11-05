# 🚀 Cara Install Cloud9 IDE dengan Password Authentication

## ⚡ Quick Install (Recommended)

### 1. c9.sh Auto Installation
- Clone the repository:
```bash
git clone https://github.com/YourUser/yourRepo.git
```

- Run the auto installation script:
```bash
bash c9.sh
```

### 2. Usage Instructions
- After installation, you can start Cloud9 with:
```bash
node server.js -l 0.0.0.0:8080 -w yourworkspace
```

### 3. Simulation Mode
- You can run in simulation mode using:
```bash
node server.js -s
```

### 4. Re-running Instructions
- If you need to re-run the installation, simply execute:
```bash
bash c9.sh
```

### 5. Default Configuration
- The default configuration will start the server on `localhost:8080`.

---

## 🐳 Manual Installation (Docker Method)

### Prerequisites
- Ensure you have Docker installed on your machine.

### Installation Steps
1. Pull the Cloud9 image:
    ```bash
docker pull c9/core
    ```
2. Run Cloud9 container:
    ```bash
docker run -d -p 8080:8080 -e C9_PORT=8080 -e C9_IP=0.0.0.0 c9/core
    ```
3. Access Cloud9: Open your browser and navigate to `http://your-ip:8080`.
4. Set up your workspace in the Cloud9 editor.
5. Make sure to save your workspace regularly.
6. Log out when finished.

### Akses Cloud9
- Buka browser dan akses URL di atas untuk masuk ke Cloud9 IDE.

### Keamanan Tambahan
- Untuk menjaga keamanan, pastikan untuk mengatur password.

### Troubleshooting
- Jika terjadi masalah, periksa log dengan:
```bash
docker logs <container-id>
```

### Perintah Berguna
- Untuk melihat semua kontainer yang berjalan:
```bash
docker ps
```

### Update Cloud9
- Untuk memperbarui Cloud9, cukup jalankan perintah pembaruan sesuai dengan versi yang Anda gunakan.

### Install Python 3
- Gunakan perintah berikut untuk instalasi Python 3 dalam Docker:
```bash
docker exec -it <container-id> bash
apt-get update && apt-get install -y python3
```

### Referensi
- [Link Dokumentasi Cloud9](http://example.com)

### Disclaimer
- Cloud9 IDE disediakan "apa adanya" tanpa jaminan apa pun.

### License
- Cloud9 IDE dilisensikan di bawah MIT License.