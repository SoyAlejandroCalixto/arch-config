# update system
sudo pacman -Syu --noconfirm

# remove unused packages
sudo pacman -Rns --noconfirm dolphin vim kitty

# install AUR helper (paru)
git clone https://aur.archlinux.org/paru-git.git ~/paru-git
cd ~/paru-git
makepkg -si
cd ~/
sudo rm -rf ~/paru-git

# install packages
sudo pacman -S --needed --noconfirm git neovim hyprland hyprpaper zsh noto-fonts-emoji adobe-source-han-sans-jp-fonts ttf-cascadia-code-nerd inter-font vlc eog waybar polkit-kde-agent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk python-gobject gnome-themes-extra fastfetch wl-clipboard wtype ranger ripgrep zoxide atuin wezterm discord dunst fontconfig zip unzip p7zip lsd bat fzf pyenv bitwarden
paru -S --needed --noconfirm brave-bin rofi-wayland rofimoji clipton hyprshot spotify adwaita-qt5-git adwaita-qt6-git fnm visual-studio-code-bin

# zsh plugins
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/hlissner/zsh-autopair ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autopair

# install kernel zen
sudo pacman -S --needed --noconfirm linux-zen linux-zen-headers
paru -S --needed --noconfirm update-grub
sudo update-grub

# nvidia stuff
sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings opencl-nvidia cuda lib32-nvidia-utils vulkan-icd-loader egl-wayland
sudo nvidia-xconfig

KERNEL_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
sudo sed -i "s/MODULES=()/MODULES=(${KERNEL_MODULES})/" /etc/mkinitcpio.conf

echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf &> /dev/null
sudo mkinitcpio -P

# disable nouveau if you are using it
if lsmod | grep nouveau &> /dev/null; then
    echo "blacklist nouveau" | sudo tee /etc/modprobe.d/nouveau.conf &> /dev/null
fi

# clone desktop dotfiles
git clone https://github.com/SoyAlejandroCalixto/arch4devs ~/arch4devs
cp -r ~/arch4devs/. ~/
# clean repo trash
sudo rm -rf ~/arch4devs && sudo rm -rf ~/.git && sudo rm -rf ~/README.md && sudo rm -rf ~/LICENSE && sudo rm -rf ~/.gitignore

# clone neovim config
git clone https://github.com/SoyAlejandroCalixto/nvim-config ~/.config/nvim

# add fnm to path
echo -e "\neval \"\$(fnm env --use-on-cd --shell zsh)\"" >> $HOME/.zshrc

# monitors settings
cat << EOF > ~/.config/hypr/monitors.conf
monitor=HDMI-1,1920x1080@75,0x0,1
monitor=DP-1,1920x1080@60,1920x0,1
EOF

# ranger config and plugins
git clone https://github.com/alexanderjeurissen/ranger_devicons ~/.config/ranger/plugins/ranger_devicons
echo "default_linemode devicons" >> ~/.config/ranger/rc.conf
git clone https://github.com/maximtrp/ranger-archives.git ~/.config/ranger/plugins/ranger-archives
echo "set preview_images true" >> ~/.config/ranger/rc.conf
echo "set preview_images_method iterm2" >> ~/.config/ranger/rc.conf

echo -e "\e[32mFinished.\e[0m\n"
