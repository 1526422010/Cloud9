# Cloud9 IDE Setup - Docker + Nginx (Basic Auth, Tanpa SSL)

Auto installer Cloud9 IDE berbasis Docker dengan reverse-proxy Nginx (basic auth). **Tanpa Let's Encrypt / certbot** — akses via HTTP.

Status: **v4.0** - full rewrite dari script v2.1 yang lama (mati karena repo `c9/core` sudah dihapus oleh AWS - Cloud9 SDK tidak lagi di-maintain). v4.0 menghapus SSL/certbot dan menambah custom port nginx.

## Fitur

- Container `linuxserver/cloud9` (port internal 8000, bind `127.0.0.1` - tidak terekspos publik)
- Basic Auth via Nginx (user:pass yang lo set)
- **Custom port nginx** - bisa pakai port selain 80 (misal 8080) kalau 80 udah kepake
- **Tanpa SSL/certbot** - murni HTTP, nggak ada proses Let's Encrypt yang gagal atau cron renew
- Python3 + pip otomatis terinstall di dalam Cloud9 (lewat Dockerfile custom)
- Auto-detect OS: Ubuntu/Debian, Fedora/RHEL/CentOS/Rocky, Alpine, Arch
- `--dry-run` untuk lihat rencana & deteksi OS tanpa eksekusi
- Workspace persist di `/opt/cloud9/code` (bind mount, aman dari reset container)

## Cara Pakai

```bash
git clone https://github.com/1526422010/Cloud9.git
cd Cloud9
sudo bash c9.sh
```

Lalu ikuti prompt: **domain/subdomain, username, password, port nginx (default 80), port cloud9 (default 8000)**.

Atau non-interaktif:

```bash
# domain, user, pass, port nginx
sudo bash c9.sh c9.example.com admin 'passwordku' 8080
```

Cek dulu tanpa eksekusi:

```bash
bash c9.sh --dry-run
```

## Port

**Port nginx** = port publik buat akses Cloud9 (biasanya 80, tapi bisa diganti kalau 80 dipakai app lain). Contoh: `8080` → akses lewat `http://domain:8080`.

**Port cloud9** = port internal host buat container (bind `127.0.0.1`, nggak perlu dibuka di firewall). Default `8000`, bisa diubah via env:

```bash
C9_PORT=8300 sudo bash c9.sh
```

Keduanya otomatis kepake di compose dan proxy nginx - nggak perlu ubah manual file apa pun.

## Yang Dilakukan Script

| Tahap | Aksi |
|---|---|
| 1 | Deteksi OS + pilih package manager (apt/dnf/apk/pacman) |
| 2 | Install Docker, Nginx, htpasswd (kalau belum ada) - **tanpa certbot** |
| 3 | Build `/opt/cloud9/` - Dockerfile (tambah python3+pip) + docker-compose.yml |
| 4 | Cloud9 jalan di `127.0.0.1:<port>` dengan USERNAME/PASSWORD env |
| 5 | Nginx vhost: `http://domain[:port]` -> `127.0.0.1:<port>`, di depan basic auth |
| 6 | Verifikasi: `curl` cek HTTP 401 (auth aktif = benar) |

## Verifikasi

```bash
# cek container
docker ps | grep cloud9

# cek python di dalam cloud9
docker exec cloud9 python3 -V && docker exec cloud9 pip3 -V

# cek auth nginx
curl -sI http://domain[:port]            # -> HTTP 401
curl -su user:pass http://domain[:port]  # -> HTTP 200
```

## HTTPS (Opsional, Manual)

Script sengaja nggak install certbot. Kalau mau HTTPS nanti:

```bash
sudo apt install certbot python3-certbot-nginx   # atau sesuai distro
sudo certbot --nginx -d domain
```

## Catatan

- Image `linuxserver/cloud9` sudah deprecated oleh maintainernya (tidak diupdate lagi). Alternatif yang direkomendasikan: `linuxserver/code-server` - tinggal ganti nama image di `Dockerfile` + `docker-compose.yml`, sisanya identik.
- TZ default `Asia/Jakarta` - ubah di `/opt/cloud9/docker-compose.yml` kalau beda zona.
- Mau akses Docker dari dalam Cloud9? Tambah volume `/var/run/docker.sock` di compose.
- Uninstall: `docker compose -f /opt/cloud9/docker-compose.yml down && rm -rf /opt/cloud9 && rm /etc/nginx/sites-available/cloud9 /etc/nginx/.htpasswd-cloud9`

## Troubleshooting

- **Akses selalu redirect ke HTTPS / `ERR_SSL_PROTOCOL_ERROR`** - ini terjadi kalau port 80/443 dipegang proxy lain (mis. Caddy/Apache) yang auto-redirect ke HTTPS. **Fix: akses wajib pakai port eksplisit** `http://domain:PORT` (contoh `http://c9.example.com:8080`). Akses `http://domain` tanpa port bakal kena redirect HTTPS oleh proxy 80 tadi, bukan nginx.
- **Port nginx bentrok** - pakai port lain: `sudo bash c9.sh domain user pass 8080`.
- **Port container bentrok** - pakai `C9_PORT=<port lain>`.
- **Workspace ilang** - jangan hapus `/opt/cloud9/code`, itu folder data lo.
- **401 terus walau sudah login** - cek username/password di prompt setup (auth nginx + auth cloud9 pakai credential yang sama).
