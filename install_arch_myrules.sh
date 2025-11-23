#!/usr/bin/env bash
# ArchLinux カスタムオリジナル全自動インストールスクリプト

# config
TARGET_UEFI="true"
BOOT_PART="1"
SWAP_PART="5"
ROOT_PART="6"

# ask target dev
printf "Enter target device (/dev/sdX) : "
read TARGET_DEV

printf "\n
    NOTICE: Do not touch the keyboard during the installation. \n"
printf "Installation will begin in 5 seconds "
printf "."
sleep 1
printf "."
sleep 1
printf "."
sleep 1
printf "."
sleep 1
printf "."
sleep 1
echo "Starting installation"


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

pacman -Sy --noconfirm
  pacman -S --needed --noconfirm reflector
  yes | pacman -Scc
  reflector --verbose --latest 5 --country "Japan" --protocol https --sort rate \
    --save /etc/pacman.d/mirrorlist
pacman -Syy --noconfirm


# install base packages
echo "Installing ArchLinux base packages"

pacstrap /mnt base base-devel btrfs-progs linux linux-firmware \
  terminus-font zsh-completions grml-zsh-config wget aria2 git

exit 0
