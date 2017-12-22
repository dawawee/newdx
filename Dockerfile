FROM base/archlinux:latest as builder
MAINTAINER Samuel Bernard "samuel.bernard@gmail.com"

# Let's run stuff
RUN \
  # First, update everything (start by keyring and pacman)
  pacman -Sy && \
  pacman -S archlinux-keyring --noconfirm && \
  pacman -S pacman --noconfirm && \
  pacman-db-upgrade && \
  pacman -Su --noconfirm && \
  # Install what is needed to build xmr-stak
  pacman -S base-devel git --noconfirm && \
  # Install useful tools
  pacman -S vim tree iproute2 inetutils --noconfirm && \
  # Generate locale en_US
  locale-gen en_US.UTF-8

RUN \
  # Create an user
  useradd -m -G wheel -s /bin/bash user && \
  # Install sudo and configure it
  pacman -S sudo --noconfirm && \
  echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER user
WORKDIR /home/user
RUN \
  # Get xmr-stak from AUR
  git clone https://aur.archlinux.org/xmr-stak_cpu.git && \
  # Enable options we want
  sed -i -e "s/HTTPD_ENABLE=OFF/HTTPD_ENABLE=ON/g" \
    -e "s/depends=(/depends=('libmicrohttpd' /g" \
    xmr-stak_cpu/PKGBUILD && \
  # Verify options
  cat xmr-stak_cpu/PKGBUILD && \
  # Build and package
  cd xmr-stak_cpu && makepkg -s --noconfirm

# Restart from clean image
FROM base/archlinux:latest
# Create user
RUN useradd -m -s /bin/bash xmr
# Get xmr-stak package
COPY --from=builder \
  /home/user/xmr-stak_cpu/xmr-stak_cpu-*-x86_64.pkg.tar.xz /tmp/.
RUN \
  # Install it with its dependency
  pacman -Sy hwloc --noconfirm && \
  pacman -U /tmp/xmr-stak_cpu-*-x86_64.pkg.tar.xz --noconfirm && \
  # Install useful packages
  pacman -Sy tmux vim tree iproute2 inetutils curl --noconfirm && \
  # Clean cache
  pacman -Scc --noconfirm

WORKDIR /home/xmr
USER xmr
CMD ["/usr/bin/tmux"]
