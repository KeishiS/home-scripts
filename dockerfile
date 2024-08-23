FROM archlinux:base-devel

RUN useradd -m builder && \
    echo "builder ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir -p /home-scripts

COPY . /home-scripts
RUN chown -R builder:builder /home-scripts

RUN pacman -Syy

RUN cd /home-scripts/aur-cache && sudo -u builder makepkg -sci --noconfirm && \
    cd /home-scripts/pkg-cache && sudo -u builder makepkg -sci --noconfirm

RUN mkdir -p /nfs/archlinux

# RUN systemctl enable aur-cache.timer pkg-cache.timer

CMD [ "/usr/bin/bash" ]
