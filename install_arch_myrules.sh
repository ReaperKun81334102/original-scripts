#!/usr/bin/env bash
# ArchLinux カスタムオリジナル全自動インストールスクリプト (UEFIのみ対応)
# 注意: このスクリプトは途中で中断すると再起動しないと再び使用できません。

# config
TARGET_UEFI="true"
BOOT_PART="1"
SWAP_PART="2"
ROOT_PART="3"

# ask target dev
printf "Enter target device (/dev/sdX) : "
read TARGET_DEV

printf "\n
NOTICE: Do not touch the keyboard during installation until instructed to do so. \n"
printf "Installation will begin in 5 seconds "
sleep 5
echo "Starting installation ..."


# setup locales
export LOCALE='ja_JP.UTF-8'
localectl set-locale "LANG=$LOCALE"

# setup keymaps
export KEYMAP='jp106'
localectl set-keymap --no-convert "$KEYMAP"
loadkeys "$KEYMAP"


# setup and format disks
BOOT_PART="${TARGET_DEV}${BOOT_PART}"
SWAP_PART="${TARGET_DEV}${SWAP_PART}"
ROOT_PART="${TARGET_DEV}${ROOT_PART}"

echo "Formatting /boot"
if [ "$TARGET_UEFI" = "true" ]; then
    mkfs.vfat -F 32 ${BOOT_PART}
else
    mkfs.ext4 -F ${BOOT_PART}
fi

echo "Formatting root"
mkfs.ext4 -F ${ROOT_PART}

echo "Creating swap"
mkswap ${SWAP_PART}


# mount disks
echo "Mounting disks"

mount ${ROOT_PART} /mnt
mkdir -p /mnt/boot
mount ${BOOT_PART} /mnt/boot

swapon ${SWAP_PART}


# setup pacman
echo "setting up pacman"

sed -i "s/#ParallelDownloads/ParallelDownloads/" "/etc/pacman.conf"
sed -i 's/^#Color/Color/' "/etc/pacman.conf"
  if [ "$(uname -m)" = "x86_64" ]
  then
    printf "\n\n"
    if grep -q "#\[multilib\]" "/etc/pacman.conf"
    then
      # it exists but commented
      sed -i '/\[multilib\]/{ s/^#//; n; s/^#//; }' "/etc/pacman.conf"
    elif ! grep -q "\[multilib\]" "/etc/pacman.conf"
    then
      # it does not exist at all
      printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" \
        >> "/etc/pacman.conf"
    fi
  fi

printf 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
pacman -Sy --noconfirm --needed archlinux-keyring
  pacman -S --needed --noconfirm reflector
  yes | pacman -Scc
  reflector --verbose --latest 5 --country "Japan" --protocol https --sort rate \
    --save /etc/pacman.d/mirrorlist
pacman -Syy --noconfirm


# install base packages
echo "Installing ArchLinux base packages"

mkdir -p "/mnt/etc/" 
cp -L /etc/resolv.conf "/mnt/etc/resolv.conf" 
pacstrap /mnt base base-devel btrfs-progs linux linux-firmware \
  terminus-font zsh-completions grml-zsh-config


# setup base system
echo "setting up base systems"

mkdir -p "/mnt/etc/" 
cp -L /etc/resolv.conf "/mnt/etc/resolv.conf" 

echo "setup fstab"
genfstab -U /mnt >> "/mnt/etc/fstab"
sed 's/relatime/noatime/g' -i "/mnt/etc/fstab"

echo "setup system folder"
mkdir -p "/mnt/"{proc,sys,dev} 
mount -t proc proc "/mnt/proc" 
mount --rbind /sys "/mnt/sys" 
mount --make-rslave "/mnt/sys" 
mount --rbind /dev "/mnt/dev" 
mount --make-rslave "/mnt/dev"

# setup locales
sed -i "s/^#$LOCALE/$LOCALE/" "/mnt/etc/locale.gen"
chroot /mnt locale-gen 
echo "LANG=$LOCALE" > "/mnt/etc/locale.conf"
echo "KEYMAP=$KEYMAP" > "/mnt/etc/vconsole.conf"
chroot /mnt ln -sf "/usr/share/zoneinfo/Asia/Tokyo" /etc/localtime

# setup chroot env pacman
cp -rvf /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
sed -i "s/#ParallelDownloads/ParallelDownloads/" "/mnt/etc/pacman.conf"
sed -i 's/^#Color/Color/' "/mnt/etc/pacman.conf"
  if [ "$(uname -m)" = "x86_64" ]
  then
    printf "\n\n"
    if grep -q "#\[multilib\]" "/mnt/etc/pacman.conf"
    then
      # it exists but commented
      sed -i '/\[multilib\]/{ s/^#//; n; s/^#//; }' "/mnt/etc/pacman.conf"
    elif ! grep -q "\[multilib\]" "/mnt/etc/pacman.conf"
    then
      # it does not exist at all
      printf "[multilib]\nInclude = /mnt/etc/pacman.d/mirrorlist\n" \
        >> "/etc/pacman.conf"
    fi
  fi
  chroot /mnt pacman -Syy --noconfirm


# setup initramfs
echo 'FONT=ter-114n' >> "/mnt/etc/vconsole.conf"
chroot /mnt mkinitcpio -P

# setup hostname
echo "arch" > /mnt/etc/hostname

# setup user
printf "Enter new username: "
read user
echo

chroot /mnt groupadd "$user" 
chroot /mnt useradd -g "$user" -d "/home/$user" -s "/bin/bash" \
    -G "$user,wheel,users,video,audio" -m "$user" 
chroot /mnt chown -R "$user":"$user" "/home/$user" 
echo "$user ALL=(ALL:ALL) ALL" >> /mnt/etc/sudoers 
echo "root ALL=(ALL:ALL) ALL" >> /mnt/etc/sudoers
chroot /mnt passwd $user

# setup extra packages
echo "Reinitializing keyring"
chroot /mnt pacman -S --overwrite='*' --noconfirm archlinux-keyring

echo "installing extra packages"
arch='arch-install-scripts pkgfile'
bluetooth='bluez bluez-hid2hci bluez-tools bluez-utils'
browser='elinks firefox'
editor='hexedit nano vim'
filesystem='cifs-utils dmraid exfat-utils f2fs-tools efibootmgr dosfstools
gpart gptfdisk mtools nilfs-utils ntfs-3g partclone parted grub partimage'
filemanager='thunar ark dolphin'
media='ffmpeg yt-dlp mpv'
audio='alsa-utils pipewire-pulse pavucontrol'
hardware='amd-ucode intel-ucode'
kernel='linux-headers'
misc='acpi git haveged hdparm htop inotify-tools ipython irssi
linux-atm lsof mercurial mesa mlocate moreutils p7zip rsync lsb-release
rtorrent screen scrot smartmontools strace tmux udisks2 unace unrar wget aria2
unzip upower usb_modeswitch usbutils zip fcitx5-im fcitx5-mozc python'
fonts='ttf-dejavu ttf-indic-otf ttf-liberation xorg-fonts-misc unicode-emoji noto-fonts-emoji noto-fonts-cjk noto-fonts-extra noto-fonts'
network='atftp bind-tools bridge-utils darkhttpd dhclient dhcpcd dialog
dnscrypt-proxy dnsmasq dnsutils fwbuilder iw networkmanager
iwd lftp nfs-utils ntp openconnect openssh openvpn ppp pptpclient rfkill
rp-pppoe socat vpnc wireless_tools wpa_supplicant wvdial xl2tpd'
xorg='xorg rxvt-unicode xf86-video-amdgpu xf86-video-ati xorg-xclock
xf86-video-dummy xf86-video-fbdev xf86-video-intel xf86-video-nouveau
xf86-video-sisusb xf86-video-vesa
xf86-video-voodoo xorg-server xorg-xbacklight xorg-xinit xterm xorg-xlsfonts'
desktop="gnome gnome-extra gnome-screenshot gnome-keyring"

all="$arch $bluetooth $browser $editor $filesystem $fonts $hardware $kernel"
all="$all $misc $network $xorg $audio $media $filemanager $desktop"

chroot /mnt pacman -Sy --noconfirm --needed --overwrite="*" $all


# setup systemd
echo "setup network"
chroot /mnt systemctl enable iwd NetworkManager gdm

# setup configs
printf "
GTK_IM_MODULE=fcitx5
QT_IM_MODULE=fcitx5
XMODIFIERS=@im=fcitx5
\n" > /mnt/etc/environment

# setup default font
mkdir -p /mnt/etc/fonts/conf.d
tee /mnt/etc/fonts/conf.d/60-generic-cjk.conf > /dev/null << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>

  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans CJK JP</family>
      <family>Noto Color Emoji</family>
      <family>emoji</family>
    </prefer>
  </alias>

  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif CJK JP</family>
      <family>Noto Color Emoji</family>
    </prefer>
  </alias>

  <alias>
    <family>monospace</family>
    <prefer>
      <family>Noto Sans Mono CJK JP</family>
      <family>Noto Color Emoji</family>
    </prefer>
  </alias>

  <!-- 従来のフォント名にも割り当て（互換性向上） -->
  <match target="pattern">
    <test name="family"><string>sans</string></test>
    <edit name="family" mode="assign" binding="strong">
      <string>Noto Sans CJK JP</string>
    </edit>
  </match>

  <match target="pattern">
    <test name="family"><string>serif</string></test>
    <edit name="family" mode="assign" binding="strong">
      <string>Noto Serif CJK JP</string>
    </edit>
  </match>

</fontconfig>
EOF

echo "updating fontconfig cache"
chroot /mnt fc-cache -fv

# other
chroot /mnt wget https://raw.githubusercontent.com/ReaperKun81334102/original-scripts/refs/heads/main/usr/bin/rescan-ata.sh -O /usr/local/bin/rescan-ata
chroot /mnt chmod +x /usr/local/bin/rescan-ata

# setup boot loader
echo "installing bootloader"

chroot /mnt grub-install --target="x86_64-efi" --efi-directory=/boot --bootloader-id="ArchLinux(x86_64)" --recheck ${TARGET_DEV}
chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg


# finish
echo "updating initramfs"

chroot /mnt mkinitcpio -P
sync

# dones
echo "Install complete!"
exit 0
