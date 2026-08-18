# Cloud9 IDE Setup - Docker + Nginx (Basic Auth + SSL)

Auto installer Cloud9 IDE berbasis Docker dengan reverse-proxy Nginx (basic auth + Let's Encrypt SSL).

Status: **v3.0** - full rewrite dari script v2.1 yang lama (mati karena repo `c9/core` sudah dihapus oleh AWS - Cloud9 SDK tidak lagi di-maintain).

## Fitur

- Container `linuxserver/cloud9` (port internal 8000, bind `127.0.0.1` - tidak terekspos publik)
- Basic Auth via Nginx (user:pass yang lo set)
- SSL Let's Encrypt otomatis (certbot) - akses via `https://domain` bukan `domain:port`
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

Lalu ikuti prompt: **domain/subdomain, username, password, port (default 8000), email (opsional)**.

Atau non-interaktif:

```bash
sudo bash c9.sh c9.example.com admin 'passwordku' you@email.com
```

Cek dulu tanpa eksekusi:

```bash
bash c9.sh --dry-run
```

## Port

Prompt interaktif nanya port host. Isi sesuai port yang lo buka di firewall (misal 80/443 buat nginx, plus 1 port buat Cloud9). Kosongkan = default `8000`.

Atau set via env tanpa prompt:

```bash
C9_PORT=8300 sudo bash c9.sh
```

Port yang lo pilih otomatis kepake di compose (bind `127.0.0.1`) dan di proxy nginx - nggak perlu ubah manual file apa pun. Yang penting tetap akses lewat `https://domain`, bukan `domain:port`.

## Yang Dilakukan Script

| Tahap | Aksi |
|---|---|
| 1 | Deteksi OS + pilih package manager (apt/dnf/apk/pacman) |
| 2 | Install Docker, Nginx, Certbot, htpasswd (kalau belum ada) |
| 3 | Build `/opt/cloud9/` - Dockerfile (tambah python3+pip) + docker-compose.yml |
| 4 | Cloud9 jalan di `127.0.0.1:<port>` dengan USERNAME/PASSWORD env |
| 5 | Nginx vhost: `https://domain` -> `127.0.0.1:<port>`, di depan basic auth |
| 6 | Certbot SSL otomatis (gagal - tetap bisa akses via http, auth tetap jalan) |
| 7 | Verifikasi: `curl` cek HTTP 401 (auth aktif = benar) |

## Verifikasi

```bash
# cek container
docker ps | grep cloud9

# cek python di dalam cloud9
docker exec cloud9 python3 -V && docker exec cloud9 pip3 -V

# cek auth nginx
curl -sI https://domain            # -> HTTP 401
curl -su user:pass https://domain  # -> HTTP 200
```

## Catatan

- Image `linuxserver/cloud9` sudah deprecated oleh maintainernya (tidak diupdate lagi). Alternatif yang direkomendasikan: `linuxserver/code-server` - tinggal ganti nama image di `Dockerfile` + `docker-compose.yml`, sisanya identik.
- TZ default `Asia/Jakarta` - ubah di `/opt/cloud9/docker-compose.yml` kalau beda zona.
- Mau akses Docker dari dalam Cloud9? Tambah volume `/var/run/docker.sock` di compose.
- Uninstall: `docker compose -f /opt/cloud9/docker-compose.yml down && rm -rf /opt/cloud9 && rm /etc/nginx/sites-available/cloud9 /etc/nginx/.htpasswd-cloud9 && certbot delete --cert-name <domain>`

## Troubleshooting

- **Certbot gagal** - pastikan DNS domain mengarah ke IP server & port 80/443 terbuka di firewall.
- **Port bentrok** - pakai `C9_PORT=<port lain>` atau ketik  port-nya.
- **Workspace ilang** - jangan hapus `/opt/cloud9/code`, itu folder data lo.
