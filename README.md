# Arch Linux Post-Install Setup Script

This repository contains a comprehensive post-installation script (`arch-setup.sh`) for Arch Linux. While originally tailored for a Huawei Matebook X Pro, it has been refactored to be modular and useful for a wide range of laptops, especially those with Intel CPUs and optional NVIDIA GPUs.

The script automates the setup of a full-featured, optimized, and power-efficient GNOME desktop environment.

## Usage

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Aatricks/Arch-Matebook-X-Pro.git
    cd Arch-Matebook-X-Pro
    ```

2.  **Review the script (Recommended):**
    Open `arch-setup.sh` in a text editor to see what it does. You can easily comment out functions in the `main()` section at the bottom of the script to skip steps you don't want.

3.  **Make the script executable and run it:**
    ```bash
    chmod +x arch-setup.sh
    ./arch-setup.sh
    ```
    The script will prompt for your password when it needs to perform administrative tasks. Some steps are interactive and will ask for your confirmation (e.g., installing undervolting tools).

## Features

The script is broken down into logical functions for clarity and customization.

### 1. System Preparation
*   **Tidy Environment**: Removes default user directories like `~/Music`, `~/Videos`, etc.
*   **Pacman Optimization**:
    *   Enables color output, parallel downloads.
    *   Enables the `multilib` repository for 32-bit software support (essential for Steam).
*   **System Update**: Fully updates the system.
*   **Mirror Refresh**: Installs `reflector` to find and configure the fastest, most up-to-date package mirrors.
*   **Base Tools**: Installs essential packages like `base-devel`, `git`, `curl`, and `htop`.

### 2. AUR Helper
*   **Paru**: Automatically installs the `paru` AUR helper to seamlessly install packages from the Arch User Repository.

### 3. GNOME Desktop
*   **Xorg & GNOME**: Installs the Xorg display server and a curated set of GNOME packages for a clean, functional desktop.
*   **GDM**: Enables the GNOME Display Manager to start automatically.

### 4. Power Management & Performance
*   **TLP**: Installs and configures **TLP** with a detailed custom configuration (`/etc/tlp.d/99-custom.conf`) to significantly improve battery life and manage performance profiles for AC vs. Battery states.
*   **CPU Tools**: Installs `intel-ucode` (CPU microcode updates) and other power management tools.
*   **Undervolting (Optional)**: Prompts the user to install and configure `intel-undervolt` from the AUR, applying safe undervolts to the CPU and GPU to reduce heat and power consumption.

### 5. Graphics Drivers & Configuration
*   **Intel & NVIDIA**: Installs drivers for Intel integrated graphics. It also detects if an NVIDIA GPU is present and installs the appropriate `nvidia-dkms` drivers.
*   **Hardware Acceleration**: Configures environment variables (`/etc/environment`) for VA-API video acceleration.
*   **GPU Switching (Optional)**: On laptops with NVIDIA Optimus, it prompts the user to install `envycontrol` and set the GPU to `integrated` mode to maximize battery life.

### 6. Applications & Shell
*   **Essential Apps**: Installs a wide range of applications from the official repositories, AUR, and Flatpak:
    *   **Dev**: `visual-studio-code-insiders-bin`, `otf-monaspace` (font).
    *   **Web**: `brave-bin`.
    *   **Communication**: `dev.vencord.Vesktop` (Discord client via Flatpak).
    *   **System**: `fish` (and sets it as the default shell), `gnome-tweaks`, `dconf-editor`, `papirus-icon-theme`.
    *   **Gaming**: `steam`, `gamemode`, `proton-ge-custom-bin`.
    *   **Media**: `vlc`, `com.spotify.Client` (Flatpak).
*   **Python Tooling (Optional)**: Prompts to install `uv`, a fast Python package manager from Astral.

### 7. GNOME Customization
*   **Settings Restore**: Applies custom GNOME settings by loading the included `gnome-settings.dconf` file. This configures the dock, theme, and other preferences.
*   **Extensions**: Installs a set of useful GNOME Shell extensions using `gnome-extensions-cli`, including:
    *   Dash to Dock
    *   Caffeine (disable screensaver)
    *   Blur My Shell
    *   AppIndicator Support

### 8. System Services
*   **Bluetooth**: Installs the necessary packages and enables the Bluetooth service.
*   **Laptop Tweaks**: Detects if the machine is a laptop to apply specific configurations like enabling TLP.
*   **NVIDIA Containers (Optional)**: Prompts to set up the NVIDIA Container Toolkit for using the GPU within Podman/Docker containers.

## Post-Installation

After the script completes, it will ask if you want to reboot. A reboot is recommended to ensure all changes, services, and the new default shell take effect.

