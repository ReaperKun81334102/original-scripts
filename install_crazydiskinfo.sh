#!/bin/bash
ARGV="$1"
UNINSTALL_TARGET='/usr/sbin/crazy'
if [ "${ARGV}" = "uninstall" ]; then
    echo "Uninstalling..."
    rm -rvf "${UNINSTALL_TARGET}"
    exit 0
fi

# TARGETS
TARGET_VERSION="1.1.0"
TARGET_SOURCE_URL="https://github.com/otakuto/crazydiskinfo/archive/refs/tags/${TARGET_VERSION}.tar.gz"
TARGET_SOURCE="${TARGET_VERSION}.tar.gz"
TARGET_DIRECTORY="crazydiskinfo-${TARGET_VERSION}"
TARGET_BUILDDIR="builddir"

echo "[+] Installing depend"
sudo apt-get update -y
sudo apt-get install -y \
    libatasmart-dev \
    libncurses5-dev \
    libncursesw5-dev \
    ninja-build \
    cmake \
    wget

echo "[+] Downloading target source"
wget "${TARGET_SOURCE_URL}" -O "${TARGET_SOURCE}"

echo "[+] Removing old entries"
rm -rvf "${TARGET_DIRECTORY}"
rm -rvf "${TARGET_BUILDDIR}"

echo "[+] Extracting target"
tar -xzvf "${TARGET_SOURCE}"
echo "Patching cmakelists.txt ..."
sed -i 's/tinfow/tinfo/g' ${TARGET_DIRECTORY}/CMakeLists.txt
sed -i 's/ncursesw/ncurses/g' ${TARGET_DIRECTORY}/CMakeLists.txt

echo "[+] Building target"
cmake -S "${TARGET_DIRECTORY}" \
    -B "${TARGET_BUILDDIR}" \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX=/usr 
cmake --build "${TARGET_BUILDDIR}"

echo "[+] Installing targets"
sudo cmake --install "${TARGET_BUILDDIR}"

echo "[+] Clean up ..."
rm -rvf "${TARGET_DIRECTORY}"
rm -rvf "${TARGET_BUILDDIR}"
rm -rvf "${TARGET_SOURCE}"

echo "[+] Done!"
exit 0
