sudo pacman -Syu

sudo echo "Color" >> /etc/pacman.conf
sudo echo "ParallelDownloads = 5" >> /etc/pacman.conf
sudo echo "ILoveCandy" >> /etc/pacman.conf

sudo pacman -S --noconfirm reflector git nano

sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

sudo reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

sudo pacman -S --needed --noconfirm base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

sudo pacman -S --noconfirm gnome-shell gdm gnome-console gnome-control-center gnome-keyring gnome-menus gnome-session gnome-settings-daemon gnome-shell-extensions gnome-text-editor nautilus 

sudo systemctl enable gdm.service

sudo pacman -S --noconfirm cpupower acpi acpid intel-ucode 

# Create the power management script
sudo tee /usr/local/bin/power-management.sh << 'EOF'
#! /bin/bash
cpupower frequency-set -g powersave -d 0.8G -u 1.8G
echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
echo 0 > /sys/devices/system/cpu/cpu7/online
echo 0 > /sys/devices/system/cpu/cpu6/online
echo 0 > /sys/devices/system/cpu/cpu5/online
echo 0 > /sys/devices/system/cpu/cpu4/online
echo "400" > /sys/class/drm/card*/gt_max_freq_mhz
echo "400" > /sys/class/drm/card*/gt_boost_freq_mhz
EOF

# Make the script executable
sudo chmod +x /usr/local/bin/power-management.sh

# Create systemd service
sudo tee /etc/systemd/system/power-management.service << EOF
[Unit]
Description=Power Management Settings
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/power-management.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl enable power-management.service

paru -S --noconfirm xf86-video-intel libvdpau-va-gl intel-media-driver sof-firmware nvidia nvidia-utils nvidia-settings

# adjust /etc/environment by adding the following line
# LIBVA_DRIVER_NAME=iHD
# VDPAU_DRIVER=va_gl

sudo echo "LIBVA_DRIVER_NAME=iHD" >> /etc/environment
sudo echo "VDPAU_DRIVER=va_gl" >> /etc/environment


sudo pacman -S --noconfirm timeshift htop

paru -S visual-studio-code-bin google-chrome legcord-bin vlc envycontrol

sudo envycontrol -s integrated

sudo systemctl reboot