# Arch Linux Setup Guide for Huawei Matebook X Pro

This guide explains the setup process implemented by the installation script in the Arch-Matebook-X-Pro repository. The script configures Arch Linux specifically for the Huawei Matebook X Pro laptop, optimizing for battery life, and functionality.

```bash
curl -O https://raw.githubusercontent.com/Aatrick/Arch-Matebook-X-Pro/main/install_script.sh
chmod +x install_script.sh
./install_script.sh
```

## What the script does

### 1. System Update and Pacman Optimization

```bash
sudo pacman -Syu --noconfirm
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sudo echo "ILoveCandy" >> /etc/pacman.conf
```

* Update the system packages
* Configures pacman for better performance:
    * Enables colored output
    * Enables parallel downloads
    * Adds ILoveCandy to pacman

### 2. Mirror Configuration

```bash
sudo pacman -S --noconfirm reflector
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sudo reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

* Install reflector
* Backs up the current mirrorlist
* Configures the fastest HTTPS mirrors for improved download speeds

### 3. AUR Helper Installation

```bash
sudo pacman -S --needed --noconfirm base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

* Installs base-devel packages required for building packages
* Clones and installs paru AUR helper
* Uses paru for installing AUR packages later in the script

### 4. Desktop Environment Setup

```bash
sudo pacman -S --noconfirm xorg
sudo pacman -S --noconfirm gnome-shell gdm gnome-console gnome-control-center gnome-keyring gnome-menus gnome-session gnome-settings-daemon gnome-shell-extensions gnome-text-editor nautilus
sudo systemctl enable gdm.service
```

* Installs Xorg display server
* Sets up GNOME desktop environment with essential components
* Enables GDM display manager

### 5. Power Management Optimization

```bash
sudo pacman -S --noconfirm cpupower acpi acpid intel-ucode
# Creates power-management.sh script
sudo systemctl enable power-management.service
sudo pacman -S --noconfirm tlp tlp-rdw smartmontools ethtool
sudo systemctl enable tlp
```

* Installs CPU frequency management tools
* Creates custom power management script that:
    * Limits CPU frequency to save battery
    * Disables CPU Turbo Boost
    * Disables half of the CPU cores when on battery
    * Limits GPU frequency
* Configures the script to run at system startup
* Installs and configures TLP for additional power savings

### 6. CPU Undervolting

```bash
sudo pacman -S intel-undervolt
# Configures intel-undervolt.conf
sudo systemctl enable intel-undervolt
```

* Installs intel-undervolt
* Configures safe undervolting settings to reduce heat and power consumption:
    * CPU: -115mV
    * GPU: -90mV
    * Cache: -115mV
    * System components: -30mV
* Sets power limits and temperature offset
* Enables the service to apply settings at boot

### 7. Graphics Configuration

```bash
paru -S --noconfirm xf86-video-intel libvdpau-va-gl intel-media-driver sof-firmware nvidia-dkms nvidia-utils nvidia-settings
paru -S --noconfirm envycontrol
sudo envycontrol -s integrated
```

* Installs Intel and NVIDIA drivers
* Sets up video acceleration with VA-API
* Configures envycontrol for GPU switching capabilities
* Sets integrated graphics mode to maximize battery life

### 8. Additional Software Installation

```bash
sudo pacman -S --noconfirm timeshift htop
# Downloads wallpaper
paru -S visual-studio-code-bin google-chrome legcord-bin vlc
curl -LsSf https://astral.sh/uv/install.sh | sh
```

* Installs timeshift for system backups
* Sets up a default wallpaper
* Installs common applications:
    * Visual Studio Code
    * Google Chrome
    * Discord (legcord-bin)
    * VLC media player
* Installs uv Python package installer

### 9. Final System Configuration

```bash
sudo systemctl enable bluetooth
sudo systemctl reboot
```

* Enables Bluetooth service
* Reboots the system to apply all changes
