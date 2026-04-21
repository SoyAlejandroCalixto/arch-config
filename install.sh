# Clone my desktop config
git clone https://github.com/SoyAlejandroCalixto/arch4devs $HOME/arch4devs
cd $HOME/arch4devs
./install.sh
sudo rm -rf $HOME/arch4devs && sudo rm -rf $HOME/.git && sudo rm -rf $HOME/README.md && sudo rm -rf $HOME/LICENSE && sudo rm -rf $HOME/.gitignore # Clean repo trash

# Monitors settings
cat << EOF > $HOME/.config/hypr/monitors.conf
monitor=HDMI-A-1,1920x1080@75,0x0,1
monitor=DP-2,1920x1080@60,1920x0,1
EOF

# Git config
cat << EOF > $HOME/.gitconfig
[credential "https://github.com"]
	helper = 
	helper = !/usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
	helper = 
	helper = !/usr/bin/gh auth git-credential
[user]
	email = soyalejandrocalixto@gmail.com
	name = soyalejandrocalixto
[core]
	editor = antigravity --wait
	autocrlf = input
EOF

echo -e "\e[32mFinished.\e[0m\n"
