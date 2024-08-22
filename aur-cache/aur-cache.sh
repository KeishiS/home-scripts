#!/usr/bin/bash

# set -x

WORKDIR=`mktemp -d /tmp/aur-cache-XXXXXX`
OUTDIR=/nfs/archlinux
cd $WORKDIR
pkgs=(
    "1password"
    "electron22-bin"
    "freerouting"
    "gitkraken"
    "google-chrome"
    "insync"
    "keybase-bin"
    "mailspring-bin"
    "midori-bin"
    "nomacs-qt6-git"
    "quarto-cli-bin"
    "rstudio-desktop-bin"
    "sddm-sugar-dark"
    "simplescreenrecorder"
    "slack-desktop-wayland"
    "spleen-font"
    "swaylock-effects"
    "visual-studio-code-bin"
    "otf-source-han-code-jp"
    "ttf-icomoon-feather"
    "ttf-hackgen"
    "ttf-juliamono"
    "ttf-material-design-icons-extended"
    "zoom"
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


for pkg in ${pkgs[@]}; do
    echo "----------[PROCESSING] ${pkg}----------"
    git clone https://aur.archlinux.org/${pkg}.git
    cd ${pkg}
    pkgver=`makepkg --printsrcinfo | grep "pkgver" | awk -F'= ' '{print $2}'`
    pkgrel=`makepkg --printsrcinfo | grep "pkgrel" | awk -F'= ' '{print $2}'`
    ls ${OUTDIR}/aur-cache/${pkg}-${pkgver}-${pkgrel}*.pkg.tar.zst > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        rm ${OUTDIR}/aur-cache/${pkg}*.pkg.tar.zst
        makepkg -sc
        mv *.pkg.tar.zst ${OUTDIR}/aur-cache/
    fi

    dep_pkgs=(`makepkg --printsrcinfo | grep -E "^\s+depends" | awk -F'= ' '{print $NF}'`)
    for dep in ${dep_pkgs[@]}; do
        fetch_pkg ${dep}
    done

    cd ..
    rm -rf ${pkg}
done

cd ${OUTDIR}/aur-cache
rm -rf ${WORKDIR}
repo-add aur-cache.db.tar.gz *.pkg.tar.zst
