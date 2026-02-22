sudo -v # make sudo never ask me for a password
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_PID=$!

# Update system
sudo pacman -Syu --noconfirm

# Set the best mirror
sudo pacman -S --needed --noconfirm reflector
sudo reflector --latest 10 --age 1 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Remove unused packages
sudo pacman -Rns --noconfirm dolphin vim kitty

# Clone my desktop config
git clone https://github.com/SoyAlejandroCalixto/arch4devs $HOME/arch4devs
cd $HOME/arch4devs
./install.sh
sudo rm -rf $HOME/arch4devs && sudo rm -rf $HOME/.git && sudo rm -rf $HOME/README.md && sudo rm -rf $HOME/LICENSE && sudo rm -rf $HOME/.gitignore # Clean repo trash

# Install extra packages
sudo pacman -S --needed --noconfirm fzf bitwarden
paru -S --noconfirm --needed fnm cloudflare-warp-bin

# Install kernel zen
sudo pacman -S --needed --noconfirm linux-zen linux-zen-headers
paru -S --needed --noconfirm update-grub
sudo update-grub

# NVIDIA or AMD drivers
if lspci | grep -i "nvidia" &> /dev/null; then
    # NVIDIA stuff
    sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings opencl-nvidia cuda lib32-nvidia-utils vulkan-icd-loader egl-wayland
    sudo nvidia-xconfig

    KERNEL_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
    sudo sed -i "s/MODULES=()/MODULES=(${KERNEL_MODULES})/" /etc/mkinitcpio.conf

    echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf &> /dev/null
    sudo mkinitcpio -P

    # Disable nouveau if you are using it
    if lsmod | grep nouveau &> /dev/null; then
        echo "blacklist nouveau" | sudo tee /etc/modprobe.d/nouveau.conf &> /dev/null
    fi
else
    # AMD stuff
    sudo pacman -S --noconfirm --needed linux-firmware mesa lib32-mesa opencl-mesa rocm-opencl-runtime vulkan-radeon lib32-vulkan-radeon amdvlk lib32-amdvlk
fi

# Clone neovim config
git clone https://github.com/SoyAlejandroCalixto/nvim-config $HOME/.config/nvim

# Add fnm to path
echo -e "\neval \"\$(fnm env --use-on-cd --shell zsh)\"" >> $HOME/.zshrc

# Monitors settings
cat << EOF > $HOME/.config/hypr/monitors.conf
monitor=HDMI-A-1,1920x1080@75,0x0,1
monitor=DP-2,1920x1080@60,1920x0,1
EOF

# Ranger config and plugins
mkdir -p $HOME/.config/ranger/plugins
git clone https://github.com/alexanderjeurissen/ranger_devicons $HOME/.config/ranger/plugins/ranger_devicons
echo "default_linemode devicons" >> $HOME/.config/ranger/rc.conf
git clone https://github.com/maximtrp/ranger-archives.git $HOME/.config/ranger/plugins/ranger-archives
echo "set preview_images true" >> $HOME/.config/ranger/rc.conf
echo "set preview_images_method iterm2" >> $HOME/.config/ranger/rc.conf

# Cloudflare Warp config
sudo systemctl enable warp-svc
sudo systemctl start warp-svc
warp-cli registration new

# Clone another dots
cp $HOME/arch-config/dots/. $HOME/

echo -e "\e[32mFinished.\e[0m\n"

trap "kill $SUDO_PID 2>/dev/null" EXIT # kill the process that keeps sudo without password
