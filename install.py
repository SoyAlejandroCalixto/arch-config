from subprocess import run

def runeach(commands):
    for command in commands:
        run(command, shell=True);

runeach([
    # update system
    'sudo pacman -Syu --noconfirm',

    # remove unused packages
    'sudo pacman -Rns --noconfirm dolphin vim kitty',
    'git clone https://aur.archlinux.org/paru-git.git $HOME/paru-git',

    # install AUR helper (paru)
    'git clone https://aur.archlinux.org/paru-git.git $HOME/paru-git',
    'cd $HOME/paru-git && makepkg -si',
    'sudo rm -rf $HOME/paru-git',

    # install system packages
    'sudo pacman -S --needed --noconfirm git neovim pyenv hyprland hyprpaper zsh noto-fonts-emoji adobe-source-han-sans-jp-fonts vlc eog waybar polkit-kde-agent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk gnome-themes-extra fastfetch wl-clipboard wtype ranger wezterm discord dunst fontconfig zip unzip p7zip lsd bat fzf',
    'paru -S --noconfirm --needed brave-bin rofi-wayland rofimoji clipse hyprshot spotify adwaita-qt5-git adwaita-qt6-git fnm',

    # zsh plugins
    'chsh -s $(which zsh)',
    'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"',
    'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k',
    'git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions',
    'git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting',

    # install kernel zen
    'sudo pacman -S --needed --noconfirm linux-zen linux-zen-headers',
    'paru -S --needed --noconfirm update-grub',
    'sudo update-grub',

    # Nvidia packages
    'sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings opencl-nvidia cuda lib32-nvidia-utils vulkan-icd-loader egl-wayland',
    'sudo nvidia-xconfig'
])

# disable nouveau if you are using it
out = run('lsmod', capture_output=True, text=True)
if 'nouveau' in out.stdout.lower():
    runeach([
        'sudo echo "blacklist nouveau" > /etc/modprobe.d/nouveau.conf'
    ]) 

# kernel modules setting
KERNEL_MODULES = "nvidia nvidia_modeset nvidia_uvm nvidia_drm"
runeach([
    f'sudo sed -i "s/MODULES=()/MODULES=({KERNEL_MODULES})/" /etc/mkinitcpio.conf'
])

runeach([
    # nvidia options
    'sudo echo "options nvidia_drm modeset=1 fbdev=1" > /etc/modprobe.d/nvidia.conf',

    # rebuild initramfs
    'sudo mkinitcpio -P',

    # clone desktop dotfiles
    'git clone https://github.com/SoyAlejandroCalixto/arch4devs $HOME/arch4devs',
    'sudo cp $HOME/arch4devs/. $HOME',
    # clean repo trash
    'sudo rm -rf $HOME/arch4devs && sudo rm -rf $HOME/.git && sudo rm -rf $HOME/README.md && sudo rm -rf $HOME/LICENSE && sudo rm -rf $HOME/.gitignore',

    # clone neovim config
    'git clone https://github.com/SoyAlejandroCalixto/nvim-config $HOME/.config/nvim'

    # add fnm to path
    'echo -e "\\neval \\"\\$(fnm env --use-on-cd --shell zsh)\\"" >> $HOME/.zshrc'
])

