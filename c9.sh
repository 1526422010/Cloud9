#!/usr/bin/env bash
# c9-setup.sh — auto setup LinuxServer Cloud9 + nginx (basic auth + SSL)
# Usage:
#   sudo ./c9-setup.sh                    # interaktif (domain, user, pass, email)
#   sudo ./c9-setup.sh DOMAIN USER PASS [EMAIL]
#   ./c9-setup.sh --dry-run               # deteksi OS + rekomendasi jalur, tanpa eksekusi
set -euo pipefail

GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; CYAN=$'\e[36m'; NC=$'\e[0m'
ok()  { echo "${GREEN}✔${NC} $*"; }
warn(){ echo "${YELLOW}⚠${NC} $*"; }
fail(){ echo "${RED}✘${NC} $*"; }

DRY_RUN=0
DOMAIN="${1:-}"; AUTH_USER="${2:-}"; AUTH_PASS="${3:-}"; EMAIL="${4:-}"
C9_PORT="${C9_PORT:-8000}"   # port host (kiri). Ganti kalau 8000 kepake: C9_PORT=8300 sudo bash c9.sh
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
echo "  certbot:     $(command -v certbot >/dev/null && echo ADA || echo BELUM)"

if [ "$DRY_RUN" = 1 ]; then
  echo
  echo "── ${CYAN}Rencana (dry-run)${NC} ────────────────────────"
  echo "1. Install yang belum ada: docker, nginx, certbot(+plugin nginx), htpasswd tool"
  echo "2. /opt/cloud9/  -> Dockerfile (python3+pip) + compose (cloud9 bind 127.0.0.1:${C9_PORT})"
  echo "3. nginx vhost: https://DOMAIN -> 127.0.0.1:${C9_PORT} + basic auth /etc/nginx/.htpasswd-cloud9"
  echo "4. certbot --nginx -> SSL gratis (port 80/443 harus terbuka, DNS sudah mengarah)"
  echo "5. Verifikasi: curl https://DOMAIN -> HTTP 401 (auth aktif)"
  echo
  echo "Akses: ${GREEN}https://DOMAIN${NC} — bukan domain:port"
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
if [ -z "$EMAIL" ]; then
  read -rp "Email untuk Let's Encrypt (kosongkan jika tidak mau): " EMAIL
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
    apt) apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx apache2-utils
         systemctl enable --now nginx ;;
    dnf) dnf install -y nginx httpd-tools; systemctl enable --now nginx ;;
    apk) apk add --no-cache nginx apache2-utils; rc-update add nginx default; rc-service nginx start ;;
    pacman) pacman -Sy --noconfirm nginx apache
         systemctl enable --now nginx ;;
  esac
else ok "nginx sudah ada"; has htpasswd || { warn "htpasswd tidak ada"; case $SYS in
    apt) apt-get install -y -qq apache2-utils ;;
    dnf) dnf install -y httpd-tools ;;
    apk) apk add --no-cache apache2-utils ;;
    pacman) pacman -Sy --noconfirm apache ;; esac; }
fi

if ! has certbot; then
  ok "Install certbot ($SYS)..."
  case $SYS in
    apt) DEBIAN_FRONTEND=noninteractive apt-get install -y -qq certbot python3-certbot-nginx ;;
    dnf) dnf install -y certbot python3-certbot-nginx ;;
    apk) apk add --no-cache certbot certbot-nginx ;;
    pacman) pacman -Sy --noconfirm certbot certbot-nginx ;;
  esac
else ok "certbot sudah ada"; fi

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
    listen 80;
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
nginx -t && systemctl reload nginx || service nginx reload
ok "nginx vhost + basic auth terpasang"

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

# ---------- 7. SSL ----------
echo
echo "── ${CYAN}SSL Let's Encrypt${NC} ─────────────────────────"
CERTBOT_ARGS="certonly --nginx -d $DOMAIN --agree-tos --redirect"
if [ -n "$EMAIL" ]; then CERTBOT_ARGS="$CERTBOT_ARGS -m $EMAIL"; else CERTBOT_ARGS="$CERTBOT_ARGS --register-unsafely-without-email"; fi
if certbot $CERTBOT_ARGS --non-interactive >/dev/null 2>&1; then
  ok "SSL aktif: https://${DOMAIN}"
else
  warn "certbot gagal — cek: DNS sudah diarahkan ke IP server? port 80/443 terbuka?"
  warn "Sementara akses via http://${DOMAIN} (basic auth tetap aktif)"
fi

# ---------- 8. verifikasi akhir ----------
echo
echo "── ${CYAN}Hasil${NC} ─────────────────────────────────────"
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${DOMAIN}" || curl -s -o /dev/null -w "%{http_code}" "http://${DOMAIN}")
case "$HTTP_CODE" in
  401) ok "Akses: https://${DOMAIN}   (401 = auth aktif, benar)" ;;
  200) ok "Akses: https://${DOMAIN}" ;;
  *)   warn "HTTP ${HTTP_CODE} — mungkin DNS/port belum siap" ;;
esac
echo "  Username: $AUTH_USER   |   Password: (yang lo input)"
echo
echo "${YELLOW}Catatan:${NC}"
echo "  • Image linuxserver/cloud9 sudah DEPRECATED (tidak diupdate lagi)."
echo "    Alternatif: linuxserver/code-server — ganti nama image di Dockerfile+compose, sisanya sama."
echo "  • Workspace: $BASE/code (bind mount, aman dari reset container)"
echo "  • Install python/pip tambahan di container: docker exec cloud9 apt-get install -y <paket>"
echo "  • Mau akses docker dari dalam cloud9? tambah volume docker.sock: /var/run/docker.sock"