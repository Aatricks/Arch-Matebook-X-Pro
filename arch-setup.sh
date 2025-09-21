#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------
# Arch Linux Post-Install Setup (Refactored)
# ------------------------------------------

LOG() { echo -e "\033[1;34m[*]\033[0m $*"; }
WARN() { echo -e "\033[1;33m[!]\033[0m $*"; }
ERR() { echo -e "\033[1;31m[✗]\033[0m $*"; }

# --- Prepare environment (tidy home dirs, optional) ---
prepare_environment() {
    LOG "Preparing environment..."
    # Remove GNOME default folders the user might not want
    rm -rf "$HOME/Templates" "$HOME/Music" "$HOME/Public" "$HOME/Videos" "$HOME/Desktop" || true
}

# --- Configure pacman (color, parallel downloads, candy) ---
configure_pacman() {
    LOG "Configuring pacman and updating system..."

    # Enable Color
    if grep -q "^#Color" /etc/pacman.conf; then
        sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    elif ! grep -q "^Color" /etc/pacman.conf; then
        echo "Color" | sudo tee -a /etc/pacman.conf >/dev/null
    fi

    # Enable ParallelDownloads = 5
    if grep -q "^#ParallelDownloads =" /etc/pacman.conf; then
        sudo sed -i 's/^#ParallelDownloads = .*/ParallelDownloads = 5/' /etc/pacman.conf
    elif grep -q "^ParallelDownloads =" /etc/pacman.conf; then
        sudo sed -i 's/^ParallelDownloads = .*/ParallelDownloads = 5/' /etc/pacman.conf
    else
        echo "ParallelDownloads = 5" | sudo tee -a /etc/pacman.conf >/dev/null
    fi

    # Enable Multilib
    if ! grep -q '^#\[multilib\]' /etc/pacman.conf; then
        if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
            echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
        fi
    else
        sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf
    fi

    # Add ILoveCandy once
    # if ! grep -q '^ILoveCandy$' /etc/pacman.conf; then
    #     echo "ILoveCandy" | sudo tee -a /etc/pacman.conf >/dev/null
    # fi

    sudo pacman -Syu --noconfirm
}

# --- Base tools and mirrors ---
install_base_tools_and_mirrors() {
    LOG "Installing base tools and refreshing mirrors..."
    sudo pacman -S --noconfirm --needed reflector git curl base-devel nano htop

    # Backup and refresh mirrorlist with reflector
    if command -v reflector >/dev/null 2>&1; then
        if [[ -f /etc/pacman.d/mirrorlist ]]; then
            sudo cp /etc/pacman.d/mirrorlist "/etc/pacman.d/mirrorlist.bak.$(date +%s)"
        fi
        sudo reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || WARN "reflector failed; keeping current mirrorlist"
    else
        WARN "reflector not installed; skipping mirror refresh"
    fi
}

# --- AUR helper (paru) ---
install_paru() {
    if command -v paru >/dev/null 2>&1; then
        LOG "paru already installed."
        return
    fi
    LOG "Installing paru (AUR helper)..."
    sudo pacman -S --noconfirm --needed base-devel git
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    pushd "$tmpdir/paru" >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null
}

# --- GNOME Desktop ---
install_gnome() {
    LOG "Installing Xorg and GNOME..."
    sudo pacman -S --noconfirm --needed xorg
    sudo pacman -S --noconfirm --needed \
        gnome-shell gdm gnome-console gnome-control-center gnome-keyring gnome-menus \
        gnome-session gnome-settings-daemon gnome-shell-extensions gnome-text-editor \
        nautilus gnome-weather gnome-tweaks
    sudo systemctl enable gdm.service
}

# --- Power management (TLP) ---
configure_tlp() {
    LOG "Installing and configuring TLP..."
    sudo pacman -S --noconfirm --needed tlp tlp-rdw smartmontools ethtool thermald

    # Prefer drop-in under /etc/tlp.d instead of overwriting /etc/tlp.conf
    sudo mkdir -p /etc/tlp.d
    sudo tee /etc/tlp.d/99-custom.conf >/dev/null <<'EOF'
# TLP custom config
CPU_DRIVER_OPMODE_ON_AC="active"
CPU_DRIVER_OPMODE_ON_BAT="active"
CPU_SCALING_GOVERNOR_ON_AC="performance"
CPU_SCALING_GOVERNOR_ON_BAT="powersave"
CPU_ENERGY_PERF_POLICY_ON_AC="default"
CPU_ENERGY_PERF_POLICY_ON_BAT="power"
PLATFORM_PROFILE_ON_AC="performance"
PLATFORM_PROFILE_ON_BAT="low-power"
WIFI_PWR_ON_AC="on"
WIFI_PWR_ON_BAT="on"
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=1
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=1
# CPU_SCALING_MIN_FREQ_ON_AC=400000
# CPU_SCALING_MAX_FREQ_ON_AC=3400000
# CPU_SCALING_MIN_FREQ_ON_BAT=400000
# CPU_SCALING_MAX_FREQ_ON_BAT=2700000
# INTEL_GPU_MIN_FREQ_ON_AC=300
# INTEL_GPU_MIN_FREQ_ON_BAT=300
# INTEL_GPU_MAX_FREQ_ON_AC=1100
# INTEL_GPU_MAX_FREQ_ON_BAT=600
# INTEL_GPU_BOOST_FREQ_ON_AC=1100
# INTEL_GPU_BOOST_FREQ_ON_BAT=600
PCIE_ASPM_ON_BAT="powersupersave"
USB_AUTOSUSPEND=1
RUNTIME_PM_ON_AC="auto"
RUNTIME_PM_ON_BAT="auto"
RESTORE_DEVICE_STATE_ON_STARTUP=1
START_CHARGE_THRESH_BAT0=65
STOP_CHARGE_THRESH_BAT0=80
TLP_DEFAULT_MODE="BAT"
EOF

    sudo systemctl enable tlp
    sudo systemctl mask systemd-rfkill.service || true
    sudo systemctl mask systemd-rfkill.socket || true
    sudo systemctl enable NetworkManager-dispatcher.service || true
    sudo tlp start || true
}

# --- CPU microcode and tools ---
install_cpu_tools() {
    LOG "Installing CPU tools and microcode..."
    sudo pacman -S --noconfirm --needed cpupower acpi acpid intel-ucode
}

# --- Intel undervolt (AUR) ---
configure_undervolt() {
    read -rp "Install and apply intel-undervolt settings? (y/N): " REPLY || REPLY="n"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! command -v paru >/dev/null 2>&1; then install_paru; fi
        LOG "Installing intel-undervolt (AUR)..."
        paru -S --noconfirm --needed intel-undervolt || WARN "Failed to install intel-undervolt"

        LOG "Writing undervolt configuration..."
        # Correct path for Arch package is /etc/intel-undervolt.conf
        sudo tee /etc/intel-undervolt.conf >/dev/null <<'EOF'
# Enable or Disable Triggers (elogind)
enable no

# CPU Undervolting
undervolt 0 'CPU' -95
undervolt 1 'GPU' -80
undervolt 2 'CPU Cache' -95
undervolt 3 'System Agent' -30
undervolt 4 'Analog I/O' -30

power package 18/5 15/60

# Energy Versus Performance Preference Switch
#hwphint switch load:single:0.9 balance_power power

# Daemon interval
interval 5000

# Actions
daemon undervolt:once
daemon power
daemon tjoffset
EOF
        sudo systemctl enable intel-undervolt.service || true
    else
        LOG "Skipping intel-undervolt."
    fi
}

# --- GPU drivers ---
install_video_drivers() {
    LOG "Installing video drivers (Intel + optional NVIDIA)..."
    # Always install Intel stack for iGPU systems
    sudo pacman -S --noconfirm --needed libvdpau-va-gl intel-media-driver sof-firmware

    if lspci | grep -qi nvidia; then
        LOG "NVIDIA GPU detected. Installing drivers..."
        sudo pacman -S --noconfirm --needed linux-headers
        sudo pacman -S --noconfirm --needed nvidia nvidia-utils nvidia-settings
    else
        LOG "No NVIDIA GPU detected; skipping NVIDIA drivers."
    fi
}

# --- System-wide environment ---
set_environment_vars() {
    LOG "Setting video acceleration environment variables..."
    add_env() {
        local key="$1"; local val="$2"
        if grep -q "^${key}=" /etc/environment; then
            sudo sed -i "s#^${key}=.*#${key}=${val}#" /etc/environment
        else
            echo "${key}=${val}" | sudo tee -a /etc/environment >/dev/null
        fi
    }
    add_env LIBVA_DRIVER_NAME iHD
    add_env VDPAU_DRIVER va_gl
}

# --- GNOME settings restore ---
apply_gnome_settings() {
    LOG "Applying GNOME settings if dump present..."
    if [[ -f ./gnome-settings.dconf ]]; then
        if command -v dconf >/dev/null 2>&1; then
            dconf load / < ./gnome-settings.dconf || WARN "Failed to load gnome-settings.dconf"
        else
            WARN "dconf not available; skipping GNOME settings restore."
        fi
    else
        WARN "No gnome-settings.dconf found. Skipping GNOME config restore."
    fi
}

# --- Applications (pacman/AUR) ---
install_apps() {
    LOG "Installing applications (AUR included)..."
    if ! command -v paru >/dev/null 2>&1; then install_paru; fi
    paru -S --noconfirm --needed \
        visual-studio-code-insiders-bin \
        blackbox-terminal \
        zen-browser-bin \
        vlc \
        envycontrol \
        flatpak \
        fish \
        gnome-extensions-cli \
        arch-update \
        papirus-icon-theme \
        ufw \
        gamemode \
        lib32-gamemode \
        lib32-nvidia-utils \
        proton-ge-custom-bin \
        steam

    systemctl enable ufw

    arch-update --tray --enable
    systemctl --user enable --now arch-update.timer

    sudo usermod -aG gamemode aatricks
}

install_fonts() {
    LOG "Installing additional fonts..."
    if ! command -v paru >/dev/null 2>&1; then install_paru; fi
    paru -S --noconfirm --needed otf-monaspace \
        ttf-ms-fonts \
        ttf-liberation \
        noto-fonts \
        noto-fonts-cjk \
        noto-fonts-emoji
    fc-cache -f
}

install_extensions() {
    LOG "Installing GNOME extensions..."
    if ! command -v gnome-extensions-cli >/dev/null 2>&1; then
        WARN "gnome-extensions-cli not installed; skipping extensions."
        return
    else
        gext install \
            dash-to-dock@micxgx.gmail.com \
            caffeine@patapon.info \
            blur-my-shell@aunetx \
            appindicatorsupport@rgcjonas.gmail.com \
            weatheroclock@CleoMenezesJr.github.io \
            quick-settings-audio-panel@rayzeq.github.io \
            light-style@gnome-shell-extensions.gcampax.github.com 
    fi
}

# --- Flatpak apps ---
install_flatpaks() {
    LOG "Installing Flatpak applications..."
    if ! command -v flatpak >/dev/null 2>&1; then
        WARN "flatpak not installed; skipping Flatpak apps."
        return
    fi
    # Ensure flathub remote exists
    if ! flatpak remotes --columns=name | grep -qx flathub; then
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    flatpak install -y flathub \
        dev.vencord.Vesktop \
        com.mattjakeman.ExtensionManager \
        ca.desrt.dconf-editor \
        page.tesk.Refine \
        io.github.Foldex.AdwSteamGtk \
        org.zealdocs.Zeal \
        com.spotify.Client \
        org.gnome.Extensions || WARN "Some Flatpak installs may have failed"
}

# --- Default shell: fish ---
set_fish_default_shell() {
    LOG "Ensuring Fish is set as the default shell..."
    if ! command -v fish >/dev/null 2>&1; then
        LOG "Installing fish..."
        sudo pacman -S --noconfirm --needed fish
    fi

    local FISH_PATH
    FISH_PATH="$(command -v fish || true)"
    if [[ -z "$FISH_PATH" ]]; then
        ERR "Fish binary not found after install. Skipping shell change."
        return
    fi

    local TARGET_USER TARGET_SHELL
    if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        TARGET_USER="${SUDO_USER}"
    else
        TARGET_USER="${USER}"
    fi

    if [[ "$TARGET_USER" == "root" ]]; then
        WARN "Refusing to change default shell for root."
        return
    fi

    if ! grep -q "^${FISH_PATH}$" /etc/shells; then
        LOG "Adding ${FISH_PATH} to /etc/shells..."
        echo "${FISH_PATH}" | sudo tee -a /etc/shells >/dev/null
    fi

    TARGET_SHELL="$(getent passwd "$TARGET_USER" | awk -F: '{print $7}')"
    if [[ "$TARGET_SHELL" == "$FISH_PATH" ]]; then
        LOG "Fish already set as default shell for ${TARGET_USER}."
        return
    fi

    if chsh -s "$FISH_PATH" "$TARGET_USER"; then
        set -U fish_greeting ""
        LOG "Default shell changed to Fish for ${TARGET_USER}. Log out/in to take effect."
    else
        WARN "Could not change default shell automatically. Run: chsh -s ${FISH_PATH} ${TARGET_USER}"
    fi
}

# --- Laptop specifics ---
setup_laptop() {
    LOG "Checking if this is a laptop..."
    if hostnamectl chassis 2>/dev/null | grep -qi laptop; then
        LOG "Laptop detected."

        if lspci | grep -qi nvidia; then
            read -rp "Configure EnvyControl for NVIDIA Optimus (set to integrated)? (y/N): " REPLY || REPLY="n"
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if ! command -v paru >/dev/null 2>&1; then install_paru; fi
                paru -S --noconfirm --needed envycontrol
                sudo envycontrol -s integrated || WARN "envycontrol failed"
            fi
        fi

        LOG "Enabling TLP (power management)..."
        sudo systemctl enable tlp || true
    else
        LOG "Not a laptop; skipping laptop-specific tweaks."
    fi
}

# --- Bluetooth ---
enable_bluetooth() {
    LOG "Enabling Bluetooth service..."
    # Ensure required packages are present
    sudo pacman -S --noconfirm --needed bluez bluez-utils || WARN "Failed to install bluez packages"
    sudo systemctl enable bluetooth || true
}

# --- Optional: NVIDIA in containers (podman/docker) ---
setup_nvidia_containers() {
    if lspci | grep -qi nvidia; then
        read -rp "Install NVIDIA Container Toolkit for Podman/Docker? (y/N): " REPLY || REPLY="n"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo pacman -S --noconfirm --needed podman podman-compose
            if command -v paru >/dev/null 2>&1; then
                paru -S --noconfirm --needed nvidia-container-toolkit || WARN "Failed to install nvidia-container-toolkit"
            else
                sudo pacman -S --noconfirm --needed nvidia-container-toolkit || WARN "Failed to install nvidia-container-toolkit"
            fi
            if command -v nvidia-ctk >/dev/null 2>&1; then
                sudo mkdir -p /etc/cdi
                sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml || WARN "Failed to generate system CDI spec"
                mkdir -p "$HOME/.config/cdi"
                nvidia-ctk cdi generate --output="$HOME/.config/cdi/nvidia.yaml" || WARN "Failed to generate user CDI spec"
                WARN "To test GPU: podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable docker.io/nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi"
            fi
        fi
    fi
}

# --- Optional: uv (Python packaging tool) ---
install_uv() {
    read -rp "Install uv (fast Python package manager) from Astral? (y/N): " REPLY || REPLY="n"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v uv >/dev/null 2>&1; then
            LOG "uv already installed."
            return
        fi
        LOG "Installing uv..."
        curl -fsSL https://astral.sh/uv/install.sh | sh || WARN "uv install failed"
    else
        LOG "Skipping uv installation."
    fi
}

main() {
    prepare_environment
    configure_pacman
    install_base_tools_and_mirrors
    install_paru
    install_gnome
    install_cpu_tools
    configure_tlp
    install_video_drivers
    set_environment_vars
    install_apps
    install_flatpaks
    apply_gnome_settings
    set_fish_default_shell
    setup_laptop
    enable_bluetooth
    setup_nvidia_containers
    install_uv
    install_extensions
    install_fonts

    LOG "Setup complete."
    read -rp "Reboot now? (y/N): " REPLY || REPLY="n"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl reboot
    else
        LOG "Please reboot later to ensure all changes take effect."
    fi
}

# Only run main if the script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]-}" == "$0" ]]; then
    main "$@"
fi
