#!/usr/bin/bash

OUTDIR=/nfs/archlinux

pkgs=(
    "base"
    "base-devel"
    "linux"
    "linux-firmware"
    "git"
    "zsh"
    #
    "act"
    "adwaita-icon-theme"
    "adwaita-icon-theme-legacy"
    "alacritty"
    "amd-ucode"
    "arandr"
    "base-devel"
    "blas-openblas"
    "blueman"
    "bluez"
    "bluez-utils"
    "brightnessctl"
    "clamav"
    "clamtk"
    "cmake"
    "coin-or-cbc"
    "colordiff"
    "cronie"
    "curl"
    "dex"
    "discord"
    "docker"
    "dunst"
    "evince"
    "fd"
    "feh"
    "gcc"
    "gcc-fortran"
    "git-lfs"
    "glibc"
    "glpk"
    "gnome-keyring"
    "graphviz"
    "gtk3"
    "helix"
    "http-parser"
    "java-runtime-common"
    "jq"
    "jre17-openjdk"
    "kicad"
    "kicad-library"
    "kicad-library-3d"
    "krb5"
    "less"
    "lvm2"
    "materia-gtk-theme"
    "mesa"
    "minizip"
    "networkmanager"
    "network-manager-applet"
    "nfs-utils"
    "openssh"
    "openssl"
    "pacman-contrib"
    "parallel"
    "pavucontrol"
    "perl"
    "perl-rename"
    "picom"
    "poppler-data"
    "python"
    "qt5-location"
    "qt5-webengine"
    "qt5-declarative"
    "qt6-tools"
    "r"
    "rclone"
    "rio"
    "ripgrep"
    "rocm-core"
    "rocm-device-libs"
    "rocm-opencl-runtime"
    "rxvt-unicode"
    "sddm"
    "seahorse"
    "sheldon"
    "starship"
    "systemd"
    "thunderbird"
    "thunderbird-i18n-ja"
    "tk"
    "tmux"
    "typst"
    "unzip"
    "vagrant"
    "virtualbox"
    "virtualbox-host-modules-arch"
    "vivaldi"
    "vivaldi-ffmpeg-codecs"
    "vlc"
    "vtk"
    "wget"
    "whois"
    "wpa_supplicant"
    "xdg-desktop-portal-gtk"
    "xdg-desktop-portal-wlr"
    "xdg-user-dirs"
    "xf86-video-amdgpu"
    "xorg-server"
    "xorg-xauth"
    "xorg-xwayland"
    "xorg-xrdb"
    "libfido2"
    "yubikey-full-disk-encryption"
    "yubikey-manager-qt"
    "xsel"
    "xclip"
    "sway"
    "swaybg"
    "swaync"
    "waybar"
    "wofi"
    "kwayland-integration"
    "qt5-wayland"
    "qt6-wayland"
    "grim"
    "slurp"
    "i3-wm"
    "i3status"
    "polybar"
    "rofi"
    "fcitx5-gtk"
    "fcitx5-qt"
    "fcitx5-mozc"
    "fcitx5-configtool"
    "noto-fonts"
    "noto-fonts-cjk"
    "noto-fonts-emoji"
    "otf-ipaexfont"
    "otf-ipafont"
    "ttf-fira-code"
    "ttf-hack-nerd"
    "ttf-iosevka-nerd"
    "ttf-jetbrains-mono"
    "ttf-jetbrains-mono-nerd"
    "ttf-nerd-fonts-symbols-mono"
    "ttf-roboto"
    "biber"
    "cpanminus"
    "texlive-basic"
    "texlive-bin"
    "texlive-binextra"
    "texlive-fontsextra"
    "texlive-fontsrecommended"
    "texlive-latex"
    "texlive-latexextra"
    "texlive-luatex"
    "texlive-bibtexextra"
    "texlive-langjapanese"
    "texlive-mathscience"
    "texlive-pictures"
    "texlive-plaingeneric"
    "pipewire"
    "pipewire-alsa"
    "pipewire-docs"
    "pipewire-pulse"
    "wireplumber"
)

MIRROR_URLS=(
    "http://jp.mirrors.cicku.me/archlinux"
    "http://mirrors.cat.net/archlinux"
    # "http://ftp.tsukuba.wide.ad.jp/Linux/archlinux"
    "http://ftp.jaist.ac.jp/pub/Linux/ArchLinux"
    # "http://mirror.nishi.network/archlinux"
    "http://www.miraa.jp/archlinux"
    "http://kr.mirrors.cicku.me/archlinux"
    "http://mirror.funami.tech/arch"
    "http://mirror.morgan.kr/archlinux"
    "http://mirror.siwoo.org/archlinux"
)
n_mirrors=${#MIRROR_URLS[@]}
idx=$((RANDOM % n_mirrors + 1))

function fetch_pkg() {
    # $1 : package name
    echo "------------------------"
    echo "[fetch_pkg] pkg: $1"
    pkg=$1

    name=`pacman -Si ${pkg} | grep 'Name' | awk -F': ' '{print $NF}'`
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    if [[ -z "${name}" ]]; then
        return 1
    fi

    repo=`pacman -Si ${pkg} | grep 'Repository' | awk -F': ' '{print $NF}'`
    arch=`pacman -Si ${pkg} | grep 'Architecture' | awk -F': ' '{print $NF}'`
    pkgver=`pacman -Si ${pkg} | grep 'Version' | awk -F': ' '{print $NF}'`
    filename="${name}-${pkgver}-${arch}.pkg.tar.zst"

    if [[ -e ${OUTDIR}/${repo}/x86_64/${filename} ]]; then
        return 0
    fi

    rm ${OUTDIR}/${repo}/x86_64/${name}-*.pkg.tar.zst*
    echo "==========================================================================="
    echo "===== [DOWNLOADING] ${MIRROR_URLS[idx]}/${repo}/os/x86_64/${filename} ====="
    wget --limit-rate=2m \
        -P "${OUTDIR}/${repo}/x86_64" \
        "${MIRROR_URLS[idx]}/${repo}/os/x86_64/${filename}"
    wget --limit-rate=2m \
        -P "${OUTDIR}/${repo}/x86_64" \
        "${MIRROR_URLS[idx]}/${repo}/os/x86_64/${filename}.sig"
    idx=$((idx % n_mirrors + 1))
    sleep 5

    dep_pkgs=(`pacman -Si ${pkg} | grep 'Depends On' | awk -F': ' '{print $NF}'`)
    for dep in ${dep_pkgs[@]}; do
        fetch_pkg ${dep}
    done
}

pacman -Syy
REPOS=("core" "extra" "community")
for repo in ${REPOS[@]}; do
    wget --limit-rate=2m \
        -O ${OUTDIR}/${repo}/x86_64/${repo}.db \
        ${MIRROR_URLS[idx]}/${repo}/os/x86_64/${repo}.db
    wget --limit-rate=2m \
        -O ${OUTDIR}/${repo}/x86_64/${repo}.files \
        ${MIRROR_URLS[idx]}/${repo}/os/x86_64/${repo}.files
done

idx=$((idx % n_mirrors + 1))
for package in ${pkgs[@]}; do
    fetch_pkg ${package}
done
