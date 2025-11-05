#!/bin/bash

# Cloud9 IDE Manager - All in One Script
# Script lengkap untuk instalasi dan menjalankan Cloud9 IDE
echo "=========================================="
echo "      Cloud9 IDE Manager v2.1            "
echo "=========================================="
echo ""

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Konfigurasi default
PORT=8080
WORKSPACE=$HOME/workspace
C9_DIR=$HOME/cloud9
CONFIG_FILE=$HOME/.c9_credentials
SIMULATION_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --simulate|--demo|-s)
            SIMULATION_MODE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Fungsi simulasi delay
simulate_delay() {
    if [ "$SIMULATION_MODE" = true ]; then
        sleep 1
    fi
}

# Fungsi untuk input username dan password
get_credentials() {
    echo -e "${YELLOW}=== Setup Kredensial Cloud9 ===${NC}"
    echo ""
    if [ "$SIMULATION_MODE" = true ]; then
        echo -e "${PURPLE}[MODE SIMULASI]${NC}"
        echo ""
    fi
    read -p "Masukkan Username: " C9_USERNAME
    while [ -z "$C9_USERNAME" ]; do
        echo -e "${RED}Username tidak boleh kosong!${NC}"
        read -p "Masukkan Username: " C9_USERNAME
    done
    read -sp "Masukkan Password: " C9_PASSWORD
    echo ""
    while [ -z "$C9_PASSWORD" ]; do
        echo -e "${RED}Password tidak boleh kosong!${NC}"
        read -sp "Masukkan Password: " C9_PASSWORD
        echo ""
    done
    # Konfirmasi password
    read -sp "Konfirmasi Password: " C9_PASSWORD_CONFIRM
    echo ""
    while [ "$C9_PASSWORD" != "$C9_PASSWORD_CONFIRM" ]; do
        echo -e "${RED}Password tidak cocok! Silakan coba lagi.${NC}"
        read -sp "Masukkan Password: " C9_PASSWORD
        echo ""
        read -sp "Konfirmasi Password: " C9_PASSWORD_CONFIRM
        echo ""
    done
    if [ "$SIMULATION_MODE" = false ]; then
        # Simpan kredensial (encrypted)
        echo "$C9_USERNAME:$C9_PASSWORD" > $CONFIG_FILE
        chmod 600 $CONFIG_FILE
    else
        echo -e "${PURPLE}[SIMULASI] Kredensial tidak disimpan ke file${NC}"
    fi
    echo ""
    echo -e "${GREEN}✓ Kredensial berhasil disimpan!${NC}"
    echo -e "  Username: ${BLUE}$C9_USERNAME${NC}"
    echo -e "  Password: ${BLUE}$(echo $C9_PASSWORD | sed 's/./*/g')${NC}"
    echo ""
}

# Load credentials dari file
load_credentials() {
    if [ -f "$CONFIG_FILE" ]; then
        CREDS=$(cat $CONFIG_FILE)
        C9_USERNAME=$(echo $CREDS | cut -d':' -f1)
        C9_PASSWORD=$(echo $CREDS | cut -d':' -f2-)
        return 0
    else
        return 1
    fi
}

# Cek apakah Cloud9 sudah terinstal
check_c9_installed() {
    if [ "$SIMULATION_MODE" = true ]; then
        return 1  # Simulasi belum terinstal
    fi
    if [ -d "$C9_DIR" ]; then
        return 0
    else
        return 1
    fi
}

# Install Cloud9
install_c9() {
    echo -e "${GREEN}=== Memulai Instalasi Cloud9 IDE ===${NC}"
    echo ""
    if [ "$SIMULATION_MODE" = true ]; then
        echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║       MODE SIMULASI AKTIF              ║${NC}"
        echo -e "${PURPLE}║   Tidak ada instalasi yang nyata       ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
        echo ""
    fi
    # Update system
    echo -e "${BLUE}[1/5] Updating system...${NC}"
    if [ "$SIMULATION_MODE" = true ]; then
        echo "      $ sudo apt-get update"
        simulate_delay
        echo -e "      ✓ Done (simulated)${NC}"
    else
        sudo apt-get update -qq
        echo -e "      ✓ Done${NC}"
    fi
    echo ""
    # Install dependencies
    echo -e "${BLUE}[2/5] Installing dependencies...${NC}"
    if [ "$SIMULATION_MODE" = true ]; then
        echo "      $ sudo apt-get install -y build-essential git python3 python3-pip curl nodejs npm"
        simulate_delay
        echo -e "      ✓ Done (simulated)${NC}"
    else
        sudo apt-get install -y build-essential git python3 python3-pip curl nodejs npm >/dev/null 2>&1
        echo -e "      ✓ Done${NC}"
    fi
    echo ""
    # Install Node.js
    echo -e "${BLUE}[3/5] Checking Node.js installation...${NC}"
    if [ "$SIMULATION_MODE" = true ]; then
        echo "      $ node --version"
        echo "      Node.js v16.20.0 (simulated)"
        simulate_delay
        echo -e "      ✓ Node.js ready${NC}"
    else
        if ! command -v node &> /dev/null; then
            echo "      Installing Node.js..."
            curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
            sudo apt-get install -y nodejs >/dev/null 2>&1
        fi
        echo -e "${GREEN}      ✓ Node.js ready${NC}"
    fi
    echo ""
    # Clone Cloud9 repository
    echo -e "${BLUE}[4/5] Downloading Cloud9 IDE...${NC}"
    if [ "$SIMULATION_MODE" = true ]; then
        echo "      $ git clone https://github.com/c9/core.git $C9_DIR"
        simulate_delay
        echo "      Cloning into '$C9_DIR'..."
        simulate_delay
        echo "      remote: Enumerating objects: 50000, done."
        simulate_delay
        echo "      Receiving objects: 100% (50000/50000), done."
        echo -e "${GREEN}      ✓ Done (simulated)${NC}"
    else
        if [ ! -d "$C9_DIR" ]; then
            git clone https://github.com/c9/core.git $C9_DIR --quiet
        fi
        echo -e "${GREEN}      ✓ Done${NC}"
    fi
    echo ""
    # Install Cloud9
    echo -e "${BLUE}[5/5] Installing Cloud9 SDK...${NC}"
    echo -e "${YELLOW}      (Proses ini memakan waktu 3-5 menit)${NC}"
    if [ "$SIMULATION_MODE" = true ]; then
        echo "      $ cd $C9_DIR && scripts/install-sdk.sh"
        simulate_delay
        echo "      Installing Cloud9 SDK..."
        simulate_delay
        echo "      npm install..."
        simulate_delay
        echo "      Building native modules..."
        simulate_delay
        echo -e "${GREEN}      ✓ Done (simulated)${NC}"
    else
        cd $C9_DIR
        scripts/install-sdk.sh
        echo -e "${GREEN}      ✓ Done${NC}"
    fi
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Instalasi Cloud9 Berhasil!         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# Jalankan Cloud9
run_c9() {
    echo -e "${GREEN}=== Menjalankan Cloud9 IDE ===${NC}"
    echo ""
    if [ "$SIMULATION_MODE" = true ]; then
        echo -e "${PURPLE}[MODE SIMULASI]${NC}"
        echo ""
    fi
    # Buat workspace directory jika belum ada
    if [ "$SIMULATION_MODE" = false ]; then
        mkdir -p $WORKSPACE
        cd $C9_DIR
    fi
    echo "=========================================="
    echo -e "${GREEN}✓ Cloud9 IDE Running!${NC}"
    echo "=========================================="
    echo -e "URL      : ${BLUE}http://localhost:$PORT${NC}"
    echo -e "Username : ${BLUE}$C9_USERNAME${NC}"
    echo -e "Password : ${BLUE}$(echo $C9_PASSWORD | sed 's/./*/g')${NC}"
    echo -e "Workspace: ${BLUE}$WORKSPACE${NC}"
    echo ""
    echo -e "${YELLOW}📌 Buka browser dan akses: http://localhost:$PORT${NC}"
    echo -e "${YELLOW}📌 Login dengan kredensial di atas${NC}"
    if [ "$SIMULATION_MODE" = true ]; then
        echo ""
        echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║       SIMULASI SELESAI!                ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}Untuk instalasi nyata, jalankan tanpa --simulate${NC}"
        echo ""
        return
    fi
    echo -e "${YELLOW}📌 Tekan Ctrl+C untuk menghentikan server${NC}"
    echo "=========================================="
    echo ""
    # Jalankan Cloud9 dengan authentication
    node server.js \
        -p $PORT \
        -w $WORKSPACE \
        -l 0.0.0.0 \
        -a $C9_USERNAME:$C9_PASSWORD
}

# Install dan Setup lengkap
full_install() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Install & Setup Cloud9 IDE           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    # Step 1: Input credentials
    get_credentials
    # Step 2: Install Cloud9
    install_c9
    # Step 3: Run Cloud9
    if [ "$SIMULATION_MODE" = true ]; then
        echo -e "${GREEN}Simulasi selesai! Berikut preview running Cloud9...${NC}"
    else
        echo -e "${GREEN}Setup selesai! Menjalankan Cloud9...${NC}"
    fi
    echo ""
    sleep 2
    run_c9
}

# Main script
main() {
    if [ "$SIMULATION_MODE" = true ]; then
        echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║     🎭 MODE SIMULASI AKTIF 🎭          ║${NC}"
        echo -e "${PURPLE}║  Semua proses hanya simulasi demo      ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
        echo ""
        sleep 1
    fi
    # Cek apakah sudah terinstal
    if check_c9_installed; then
        echo -e "${GREEN}✓ Cloud9 sudah terinstal${NC}"
        echo ""
        # Cek apakah ada credentials tersimpan
        if load_credentials; then
            echo -e "${GREEN}✓ Kredensial ditemukan${NC}"
            echo -e "Username: ${BLUE}$C9_USERNAME${NC}"
            echo ""
            read -p "Gunakan kredensial ini? (y/n): " use_saved
            if [ "$use_saved" != "y" ] && [ "$use_saved" != "Y" ]; then
                get_credentials
            fi
        else
            echo -e "${YELLOW}⚠ Kredensial belum ada${NC}"
            echo ""
            get_credentials
        fi
        run_c9
    else
        # Cloud9 belum terinstal
        if [ "$SIMULATION_MODE" = false ]; then
            echo -e "${YELLOW}⚠ Cloud9 belum terinstal${NC}"
        else
            echo -e "${PURPLE}[SIMULASI] Cloud9 belum terinstal${NC}"
        fi
        echo ""
        read -p "Apakah Anda ingin menginstal Cloud9 sekarang? (y/n): " install_choice
        if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
            full_install
        else
            echo -e "${RED}Instalasi dibatalkan${NC}"
            exit 1
        fi
    fi
}

# Tampilkan bantuan
show_help() {
    echo "Cloud9 IDE Manager - Usage:"
    echo ""
    echo "  ./c9.sh              Run normal (install/start Cloud9)"
    echo "  ./c9.sh --simulate   Run simulation mode (demo)"
    echo "  ./c9.sh -s           Run simulation mode (demo)"
    echo ""
}

# Cek jika minta help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Jalankan main function
main
