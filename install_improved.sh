#!/bin/bash

# Arch Linux Installation Script - Improved Version
# This script sets up a complete Arch Linux desktop environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handling function
handle_error() {
    log_error "Script failed at line $1"
    cleanup
    exit 1
}

# Cleanup function
cleanup() {
    # Kill sudo refresh process if it exists
    if [[ -n "$SUDO_PID" ]] && kill -0 "$SUDO_PID" 2>/dev/null; then
        kill "$SUDO_PID" 2>/dev/null
        log "Stopped sudo refresh process"
    fi
}

# Set up error handling
trap 'handle_error $LINENO' ERR
trap 'cleanup' EXIT

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "This script should not be run as root"
    exit 1
fi

log "Starting Arch Linux installation script..."

# Setup sudo to not ask for password during installation
log "Setting up sudo authentication..."
sudo -v
if [[ $? -ne 0 ]]; then
    log_error "Failed to authenticate with sudo"
    exit 1
fi

# Keep sudo alive in background
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_PID=$!

# Update system
log "Updating system packages..."
sudo pacman -Syu --noconfirm

# Set up best mirrors
log "Setting up best mirrors..."
if ! pacman -Qi reflector &>/dev/null; then
    sudo pacman -S --needed --noconfirm reflector
fi
sudo reflector --latest 10 --age 1 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Remove unwanted packages (optional - comment out if you want to keep them)
log "Removing unwanted default packages..."
PACKAGES_TO_REMOVE="dolphin vim kitty"
for package in $PACKAGES_TO_REMOVE; do
    if pacman -Qi "$package" &>/dev/null; then
        sudo pacman -Rns --noconfirm "$package" || log_warning "Failed to remove $package"
    fi
done

# Clone desktop configuration
log "Cloning desktop configuration..."
ARCH4DEVS_DIR="$HOME/arch4devs"
if [[ -d "$ARCH4DEVS_DIR" ]]; then
    log_warning "arch4devs directory already exists, removing it..."
    rm -rf "$ARCH4DEVS_DIR"
fi

if ! git clone https://github.com/SoyAlejandroCalixto/arch4devs "$ARCH4DEVS_DIR"; then
    log_error "Failed to clone arch4devs repository"
    exit 1
fi

# Install desktop environment
log "Installing desktop environment from arch4devs..."
cd "$ARCH4DEVS_DIR"
if [[ -f "./install.sh" ]]; then
    chmod +x ./install.sh
    ./install.sh
else
    log_error "install.sh not found in arch4devs repository"
    exit 1
fi

# Clean up arch4devs repository files safely
log "Cleaning up repository files..."
cd "$HOME"
if [[ -d "$ARCH4DEVS_DIR" ]]; then
    rm -rf "$ARCH4DEVS_DIR"
fi

# Remove only the specific files from arch4devs, not all files with these names
REPO_FILES=(".git" "README.md" "LICENSE" ".gitignore" "install.sh")
for file in "${REPO_FILES[@]}"; do
    if [[ -e "$HOME/$file" ]]; then
        # Double check we're not removing important user files
        if [[ "$file" == ".git" && -f "$HOME/.git/config" ]]; then
            # Check if this is likely the arch4devs git repo
            if grep -q "arch4devs" "$HOME/.git/config" 2>/dev/null; then
                rm -rf "$HOME/$file"
            else
                log_warning "Skipping removal of $file - appears to be a user repository"
            fi
        else
            rm -rf "$HOME/$file"
        fi
    fi
done

# Install additional packages
log "Installing additional packages..."
EXTRA_PACKAGES="fzf bitwarden"
sudo pacman -S --needed --noconfirm $EXTRA_PACKAGES

# Check if paru is installed (should be installed by arch4devs)
if ! command -v paru &> /dev/null; then
    log_error "paru is not installed. arch4devs installation may have failed."
    exit 1
fi

AUR_PACKAGES="fnm cloudflare-warp-bin"
paru -S --noconfirm --needed $AUR_PACKAGES

# Install zen kernel
log "Installing zen kernel..."
sudo pacman -S --needed --noconfirm linux-zen linux-zen-headers

if ! command -v update-grub &> /dev/null; then
    paru -S --needed --noconfirm update-grub
fi

# GPU drivers installation
log "Detecting and installing GPU drivers..."
if lspci | grep -i "nvidia" &> /dev/null; then
    log "NVIDIA GPU detected, installing NVIDIA drivers..."
    
    NVIDIA_PACKAGES="nvidia-dkms nvidia-utils nvidia-settings opencl-nvidia cuda lib32-nvidia-utils vulkan-icd-loader egl-wayland"
    sudo pacman -S --needed --noconfirm $NVIDIA_PACKAGES
    
    # Configure NVIDIA
    sudo nvidia-xconfig
    
    # Update mkinitcpio
    KERNEL_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
    sudo sed -i "s/MODULES=()/MODULES=(${KERNEL_MODULES})/" /etc/mkinitcpio.conf
    
    # Configure nvidia-drm
    echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf &> /dev/null
    
    # Rebuild initramfs
    sudo mkinitcpio -P
    
    # Blacklist nouveau if loaded
    if lsmod | grep nouveau &> /dev/null; then
        echo "blacklist nouveau" | sudo tee /etc/modprobe.d/nouveau.conf &> /dev/null
        log_warning "Nouveau driver blacklisted. Reboot required."
    fi
    
elif lspci | grep -i "amd" &> /dev/null; then
    log "AMD GPU detected, installing AMD drivers..."
    AMD_PACKAGES="linux-firmware mesa lib32-mesa opencl-mesa rocm-opencl-runtime vulkan-radeon lib32-vulkan-radeon amdvlk lib32-amdvlk"
    sudo pacman -S --noconfirm --needed $AMD_PACKAGES
else
    log_warning "No dedicated GPU detected, skipping GPU driver installation"
fi

# Update GRUB after kernel and driver installation
log "Updating GRUB configuration..."
sudo update-grub

# Clone neovim configuration
log "Setting up Neovim configuration..."
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [[ -d "$NVIM_CONFIG_DIR" ]]; then
    log_warning "Neovim config already exists, backing up..."
    mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.backup.$(date +%s)"
fi
git clone https://github.com/SoyAlejandroCalixto/nvim-config "$NVIM_CONFIG_DIR"

# Add fnm to shell configuration
log "Configuring fnm for Node.js version management..."
if ! grep -q "fnm env" "$HOME/.zshrc" 2>/dev/null; then
    echo -e "\n# fnm (Node.js version manager)" >> "$HOME/.zshrc"
    echo 'eval "$(fnm env --use-on-cd --shell zsh)"' >> "$HOME/.zshrc"
fi

# Monitor configuration (optional)
read -p "Do you want to configure dual monitors? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Setting up monitor configuration..."
    mkdir -p "$HOME/.config/hypr"
    
    echo "Available monitors:"
    hyprctl monitors 2>/dev/null || log_warning "Hyprland not running, using default configuration"
    
    read -p "Enter primary monitor name (default: HDMI-A-1): " PRIMARY_MONITOR
    PRIMARY_MONITOR=${PRIMARY_MONITOR:-HDMI-A-1}
    
    read -p "Enter secondary monitor name (default: DP-2): " SECONDARY_MONITOR
    SECONDARY_MONITOR=${SECONDARY_MONITOR:-DP-2}
    
    cat << EOF > "$HOME/.config/hypr/monitors.conf"
monitor=${PRIMARY_MONITOR},1920x1080@75,0x0,1
monitor=${SECONDARY_MONITOR},1920x1080@60,1920x0,1
EOF
    log_success "Monitor configuration saved to ~/.config/hypr/monitors.conf"
fi

# Ranger configuration
log "Setting up Ranger file manager..."
RANGER_CONFIG_DIR="$HOME/.config/ranger"
mkdir -p "$RANGER_CONFIG_DIR/plugins"

# Install ranger plugins
if [[ ! -d "$RANGER_CONFIG_DIR/plugins/ranger_devicons" ]]; then
    git clone https://github.com/alexanderjeurissen/ranger_devicons "$RANGER_CONFIG_DIR/plugins/ranger_devicons"
fi

if [[ ! -d "$RANGER_CONFIG_DIR/plugins/ranger-archives" ]]; then
    git clone https://github.com/maximtrp/ranger-archives.git "$RANGER_CONFIG_DIR/plugins/ranger-archives"
fi

# Configure ranger
RANGER_RC="$RANGER_CONFIG_DIR/rc.conf"
if [[ ! -f "$RANGER_RC" ]]; then
    touch "$RANGER_RC"
fi

# Add configurations if they don't exist
if ! grep -q "default_linemode devicons" "$RANGER_RC" 2>/dev/null; then
    echo "default_linemode devicons" >> "$RANGER_RC"
fi

if ! grep -q "set preview_images true" "$RANGER_RC" 2>/dev/null; then
    echo "set preview_images true" >> "$RANGER_RC"
    echo "set preview_images_method iterm2" >> "$RANGER_RC"
fi

# Cloudflare WARP setup
log "Setting up Cloudflare WARP..."
sudo systemctl enable warp-svc
sudo systemctl start warp-svc

# Register WARP (this might require user interaction)
if command -v warp-cli &> /dev/null; then
    warp-cli registration new || log_warning "WARP registration failed or already registered"
else
    log_warning "warp-cli not found, skipping WARP registration"
fi

log_success "Installation completed successfully!"
echo
log "Please reboot your system to ensure all changes take effect:"
log "sudo reboot"
echo
log "After reboot, you may need to:"
log "1. Log into WARP: warp-cli connect"
log "2. Configure any additional settings in your desktop environment"
log "3. Install additional Node.js versions with fnm: fnm install <version>"

exit 0