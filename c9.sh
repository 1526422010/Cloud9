#!/usr/bin/env bash
# c9-setup.sh — auto setup LinuxServer Cloud9 + nginx (basic auth, tanpa SSL)
# Usage:
#   sudo ./c9-setup.sh                          # interaktif (domain, user, pass, port nginx, port cloud9)
#   sudo ./c9-setup.sh DOMAIN USER PASS [NGINX_PORT]
#   ./c9-setup.sh --dry-run                     # deteksi OS + rekomendasi jalur, tanpa eksekusi
set -euo pipefail

GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; CYAN=$'\e[36m'; NC=$'\e[0m'
ok()  { echo "${GREEN}✔${NC} $*"; }
warn(){ echo "${YELLOW}⚠${NC} $*"; }
fail(){ echo "${RED}✘${NC} $*"; }

DRY_RUN=0
DOMAIN="${1:-}"; AUTH_USER="${2:-}"; AUTH_PASS="${3:-}"; NGINX_PORT="${4:-}"
C9_PORT_ARG="${C9_PORT:-}"   # env override, misal: C9_PORT=8300 sudo bash c9.sh
C9_PORT=""
if [ "${DOMAIN:-}" = "--dry-run" ]; then DRY_RUN=1; DOMAIN=""; fi

# ---------- 1. deteksi OS ----------
detect_os() {
  [ -r /etc/os-release ] || { fail "Tidak bisa baca /etc/os-release (OS tidak dikenal)"; exit 1; }
  . /etc/os-release
  DISTRO="${PRETTY_NAME:-$NAME}"
  case "${ID:-}" in
    ubuntu|debian|linuxmint|pop) SYS=apt ;;
    fedora|rhel|centos|rocky|almalinux) SYS=dnf ;;
    alpine) SYS=apk ;;
    arch|manjaro) SYS=pacman ;;
    *) fail "Distro '$ID' belum didukung. Edit SYS di baris atas script."; exit 1 ;;
  esac
}
detect_os

echo "── ${CYAN}Deteksi OS${NC} ──────────────────────────────"
ok "${DISTRO}"
case $SYS in
  apt)    echo "  jalur: ${CYAN}apt${NC} (docker-ce repo resmi + compose plugin)" ;;
  dnf)    echo "  jalur: ${CYAN}dnf${NC} (docker-ce repo resmi + compose plugin)" ;;
  apk)    echo "  jalur: ${CYAN}apk${NC} (docker + docker-cli-compose)" ;;
  pacman) echo "  jalur: ${CYAN}pacman${NC} (docker + docker-compose)" ;;
esac
has() { command -v "$1" >/dev/null 2>&1; }
echo "  docker:      $(command -v docker >/dev/null && echo ADA || echo BELUM)"
echo "  nginx:       $(command -v nginx >/dev/null && echo ADA || echo BELUM)"

if [ "$DRY_RUN" = 1 ]; then
  echo
  echo "── ${CYAN}Rencana (dry-run)${NC} ────────────────────────"
  echo "1. Install yang belum ada: docker, nginx, htpasswd tool (tanpa certbot/SSL)"
  echo "2. /opt/cloud9/  -> Dockerfile (python3+pip) + compose (cloud9 bind 127.0.0.1:${C9_PORT:-8000})"
  echo "3. nginx vhost: listen port ${NGINX_PORT:-80} -> 127.0.0.1:${C9_PORT:-8000} + basic auth /etc/nginx/.htpasswd-cloud9"
  echo "4. Verifikasi: curl http://DOMAIN[:${NGINX_PORT:-80}] -> HTTP 401 (auth aktif)"
  echo
  echo "Akses: ${GREEN}http://DOMAIN[:${NGINX_PORT:-80}]${NC} — tanpa SSL (certbot sengaja dimatikan)"
  exit 0
fi

# ---------- 2. root ----------
if [ "$(id -u)" -ne 0 ]; then
  if has sudo; then exec sudo -E "$0" "$@"; else fail "Jalankan sebagai root: sudo $0 $*"; exit 1; fi
fi

# ---------- 3. input ----------
if [ -z "$DOMAIN" ]; then
  read -rp "Domain/subdomain (contoh: c9.example.com): " DOMAIN
  [ -z "$DOMAIN" ] && { fail "Domain wajib diisi"; exit 1; }
fi
if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then fail "Format domain tidak valid: $DOMAIN"; exit 1; fi
if [ -z "$AUTH_USER" ]; then read -rp "Username login: " AUTH_USER; [ -z "$AUTH_USER" ] && { fail "Username wajib"; exit 1; }; fi
if [ -z "$AUTH_PASS" ]; then
  read -rsp "Password login: " AUTH_PASS; echo
  read -rsp "Ulangi password: " AUTH_PASS2; echo
  [ "$AUTH_PASS" != "$AUTH_PASS2" ] && { fail "Password tidak sama"; exit 1; }
  [ ${#AUTH_PASS} -lt 6 ] && { fail "Password minimal 6 karakter"; exit 1; }
fi
if [ -z "$NGINX_PORT" ]; then
  read -rp "Port nginx (default 80, misal 8080 kalau 80 dipakai): " NGINX_PORT
  [ -z "$NGINX_PORT" ] && NGINX_PORT=80
fi
[[ "$NGINX_PORT" =~ ^[0-9]+$ ]] && [ "$NGINX_PORT" -ge 1 ] && [ "$NGINX_PORT" -le 65535 ] \
  || { fail "Port nginx tidak valid: $NGINX_PORT"; exit 1; }
if [ -z "$C9_PORT_ARG" ]; then
  read -rp "Port host untuk Cloud9 (default 8000, sesuaikan firewall): " C9_PORT_ARG
  [ -z "$C9_PORT_ARG" ] && C9_PORT_ARG=8000
fi
C9_PORT="$C9_PORT_ARG"
# deteksi port bentrok sebelum lanjut (mis. caddy/apache pegang 80)
if ss -tlnp 2>/dev/null | grep -qE "[:-]${NGINX_PORT} "; then
  OWNER=$(ss -tlnp 2>/dev/null | grep -E "[:-]${NGINX_PORT} " | grep -oE 'users:\(\("[^"]+"' | head -1 | sed 's/users:(("//')
  warn "Port ${NGINX_PORT} sudah dipakai ${OWNER:-proses lain} — nginx nggak bisa listen!"
  warn "Pilih port lain (misal 8080) atau matikan service itu dulu, lalu jalankan ulang script."
  exit 1
fi
# port cloud9 (host) juga dicek — biar nggak bentrok service lain
if ss -tlnp 2>/dev/null | grep -qE "[:-]${C9_PORT} "; then
  warn "Port ${C9_PORT} sudah dipakai host — C9_PORT=<port lain> sudo bash c9.sh ..."
  exit 1
fi

# ---------- 4. install dependensi ----------
echo
echo "── ${CYAN}Install dependensi${NC} ────────────────────────"
if ! has docker; then
  ok "Install docker ($SYS)..."
  case $SYS in
    apt) curl -fsSL https://get.docker.com | sh
         systemctl enable --now docker 2>/dev/null || service docker start ;;
    dnf) curl -fsSL https://get.docker.com | sh
         systemctl enable --now docker ;;
    apk) apk add --no-cache docker docker-cli-compose
         rc-update add docker default; rc-service docker start ;;
    pacman) pacman -Sy --noconfirm docker docker-compose
         systemctl enable --now docker ;;
  esac
else ok "docker sudah ada"; fi

if ! docker compose version >/dev/null 2>&1 && ! has docker-compose; then
  case $SYS in
    apt|dnf) : ;; # get.docker.com sudah bawa plugin compose
    apk) apk add --no-cache docker-cli-compose ;;
    pacman) pacman -Sy --noconfirm docker-compose ;;
  esac
fi

if ! has nginx; then
  ok "Install nginx ($SYS)..."
  case $SYS in
    apt) apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx apache2-utils ;;
    dnf) dnf install -y nginx httpd-tools ;;
    apk) apk add --no-cache nginx apache2-utils ;;
    pacman) pacman -Sy --noconfirm nginx apache ;;
  esac
else ok "nginx sudah ada"; has htpasswd || { warn "htpasswd tidak ada"; case $SYS in
    apt) apt-get install -y -qq apache2-utils ;;
    dnf) dnf install -y httpd-tools ;;
    apk) apk add --no-cache apache2-utils ;;
    pacman) pacman -Sy --noconfirm apache ;; esac; }
fi

# matikan default vhost (listens 80) biar nggak bentrok port custom kita
if [ -e /etc/nginx/sites-enabled/default ]; then rm -f /etc/nginx/sites-enabled/default; fi
# apk: jangan include default conf dari paket
if [ "$SYS" = apk ] && [ -e /etc/nginx/http.d/default.conf ]; then mv /etc/nginx/http.d/default.conf /etc/nginx/http.d/default.conf.bak; fi

# start nginx SEKARANG (baru install atau ulang jalankan), supaya reload nanti valid
systemctl restart nginx 2>/dev/null || service nginx restart 2>/dev/null || { nginx -t && nginx; } \
  || fail "nginx gagal start — cek 'systemctl status nginx'. Kemungkinan port 80 dipakai service lain (caddy/apache)."

# ---------- 5. file konfigurasi ----------
BASE=/opt/cloud9
mkdir -p "$BASE/code"
ok "Generate konfigurasi di $BASE ..."

cat > "$BASE/Dockerfile" <<'EOF'
FROM lscr.io/linuxserver/cloud9:latest
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 python3-pip python3-venv \
 && apt-get clean && rm -rf /var/lib/apt/lists/*
EOF

COMPOSE_CMD="docker compose"
has docker-compose && ! docker compose version >/dev/null 2>&1 && COMPOSE_CMD="docker-compose"

cat > "$BASE/docker-compose.yml" <<EOF
services:
  cloud9:
    build: .
    container_name: cloud9
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Jakarta
      - USERNAME=${AUTH_USER}
      - PASSWORD=${AUTH_PASS}
    volumes:
      - ${BASE}/code:/code
    ports:
      - "127.0.0.1:${C9_PORT}:8000"
    restart: unless-stopped
EOF

# htpasswd: file dasar auth nginx
htpasswd -bc /etc/nginx/.htpasswd-cloud9 "$AUTH_USER" "$AUTH_PASS" >/dev/null 2>&1 || \
  { echo "$AUTH_PASS" | htpasswd -ci /etc/nginx/.htpasswd-cloud9 "$AUTH_USER" >/dev/null 2>&1; }

cat > /etc/nginx/sites-available/cloud9 <<EOF
server {
    listen ${NGINX_PORT};

    server_name ${DOMAIN};

    location / {
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/.htpasswd-cloud9;
        proxy_pass http://127.0.0.1:${C9_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
case $SYS in apk) install -m644 /etc/nginx/sites-available/cloud9 /etc/nginx/http.d/cloud9.conf ;;
            *) ln -sf ../sites-available/cloud9 /etc/nginx/sites-enabled/cloud9 ;;
esac
nginx -t || { fail \"konfigurasi nginx tidak valid\"; exit 1; }
# reload kalau jalan, start kalau belum
if systemctl is-active --quiet nginx 2>/dev/null; then systemctl reload nginx;
elif service nginx status >/dev/null 2>&1; then service nginx reload;
else systemctl restart nginx 2>/dev/null || service nginx restart 2>/dev/null || nginx; fi
ok "nginx vhost + basic auth terpasang (listen port ${NGINX_PORT})"

# ---------- 6. jalankan container ----------
echo
echo "── ${CYAN}Jalankan Cloud9${NC} ──────────────────────────"
cd "$BASE"
$COMPOSE_CMD up -d --build
for i in $(seq 1 30); do
  curl -s -o /dev/null http://127.0.0.1:${C9_PORT} && break   # exit 0 walau 401 (auth aktif = container sudah jalan)
  sleep 1
done
# auth ganda: cloud9 juga minta login (USERNAME/PASSWORD di env) — konsisten dengan nginx
curl -su "$AUTH_USER:$AUTH_PASS" -o /dev/null http://127.0.0.1:${C9_PORT} \
  && ok "cloud9 running (http://127.0.0.1:${C9_PORT})" || fail "cloud9 tidak merespon"
ok "Verifikasi python di container:"
docker exec cloud9 sh -c 'python3 -V && pip3 -V' || warn "python3 belum bisa diverifikasi"

# ---------- 7. verifikasi akhir ----------
echo
echo "── ${CYAN}Hasil${NC} ─────────────────────────────────────"
URL="http://${DOMAIN}"
[ "$NGINX_PORT" != "80" ] && URL="${URL}:${NGINX_PORT}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
case "$HTTP_CODE" in
  401) ok "Akses: ${URL}   (401 = auth aktif, benar)" ;;
  200) ok "Akses: ${URL}" ;;
  *)   warn "HTTP ${HTTP_CODE} — mungkin DNS/port belum siap" ;;
esac
echo "  Username: $AUTH_USER   |   Password: (yang lo input)"
echo
echo "${YELLOW}Catatan:${NC}"
echo "  • Tanpa SSL (certbot dimatikan) — akses via HTTP. Mau HTTPS nanti: install certbot dan jalankan 'certbot --nginx -d ${DOMAIN}' manual."
echo "  • Workspace: $BASE/code (bind mount, aman dari reset container)"
echo "  • Install python/pip tambahan di container: docker exec cloud9 apt-get install -y <paket>"
echo "  • Mau akses docker dari dalam cloud9? tambah volume docker.sock: /var/run/docker.sock"