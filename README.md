# Cloud9 IDE

Cloud9 IDE is a cloud-based integrated development environment (IDE).

## ⚡ Quick Install (Recommended)

Cara paling mudah untuk install dan menjalankan Cloud9 IDE menggunakan script otomatis:

### 🚀 Auto Installation dengan c9.sh

Script `c9.sh` akan menginstall dan mengkonfigurasi Cloud9 IDE secara otomatis dengan fitur:

✅ **One-command installation** - Install semua dependencies otomatis  
✅ **Interactive setup** - Input username & password saat instalasi  
✅ **Auto-save credentials** - Tidak perlu input ulang di run berikutnya  
✅ **Smart detection** - Deteksi otomatis sudah install atau belum  
✅ **Simulation mode** - Testing tanpa install untuk preview  

### 📦 Cara Menggunakan:

**1. Clone repository:**
```bash
git clone https://github.com/1526422010/Cloud9.git
cd Cloud9
```

**2. Beri permission executable:**
```bash
chmod +x c9.sh
```

**3. Jalankan installer:**
```bash
./c9.sh
```

**4. Follow the prompts:**
- Pilih `y` untuk mulai instalasi
- Masukkan **username** yang Anda inginkan
- Masukkan **password** (dengan konfirmasi)
- Script akan otomatis:
  - Install dependencies (build-essential, git, python3, nodejs, npm)
  - Download Cloud9 IDE dari GitHub
  - Install Cloud9 SDK
  - Menyimpan credentials Anda
  - Menjalankan Cloud9 server

**5. Akses Cloud9:**
```
http://localhost:8080
```
Login dengan username & password yang Anda buat tadi!

### 🎭 Mode Simulasi (Optional)

Testing script tanpa install apapun:
```bash
./c9.sh --simulate
```
atau
```bash
./c9.sh -s
```

### 🔄 Menjalankan Lagi

Setelah instalasi pertama, cukup jalankan:
```bash
./c9.sh
```
Script akan:
- Load credentials yang tersimpan
- Tanya mau pakai credentials lama atau baru
- Langsung jalankan Cloud9 server

### ⚙️ Konfigurasi Default:
- **Port:** 8080
- **Workspace:** `~/workspace`
- **Cloud9 Directory:** `~/cloud9`
- **Credentials File:** `~/.c9_credentials`

---

## 🐳 Manual Installation (Docker Method)

Jika Anda lebih suka menggunakan Docker, ikuti panduan di bawah ini:

## 📋 Prerequisites

Some prerequisites are needed...