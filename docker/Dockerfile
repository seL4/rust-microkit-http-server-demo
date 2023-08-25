FROM trustworthysystems/sel4

WORKDIR /tmp

RUN rm -r *

RUN apt-get update -q && apt-get install -y --no-install-recommends \
    # for qemu
    pkg-config \
    libglib2.0-dev \
    libaio-dev \
    libpixman-1-dev \
    libslirp-dev \
    # for sel4cp
    python3-venv \
    musl-tools \
    pandoc \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-recommended \
    # for test script
    python3-requests \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    target=aarch64-none-elf; \
    install_dir=/opt/gcc-$target; \
    sysroot_dir=$install_dir-sysroot; \
    url="https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz"; \
    wget -nv "$url"; \
    tar -xf gcc-arm-*.tar.xz; \
    rm gcc-arm-*.tar.xz; \
    mv gcc-arm-* $install_dir; \
    mkdir -p $sysroot_dir; \
    ln -s $install_dir/$target $sysroot_dir/usr;

ENV PATH=/opt/gcc-aarch64-none-elf/bin:$PATH

RUN set -eux; \
    version=7.2.0; \
    url="https://download.qemu.org/qemu-${version}.tar.xz"; \
    wget -nv "$url"; \
    tar -xf qemu-*.tar.xz; \
    rm qemu-*.tar.xz; \
    cd qemu-*; \
    qemu_arm_virt_sp804_url="https://github.com/coliasgroup/qemu/commit/cd3b78de4b5a8d7c79ae99dab2b5e0ab1ba0ffac.patch"; \
    curl -sSL "$qemu_arm_virt_sp804_url" | patch -p1; \
    ./configure \
        --prefix=/opt/qemu \
        --enable-slirp \
        --enable-linux-aio \
        --target-list=arm-softmmu,aarch64-softmmu,riscv32-softmmu,riscv64-softmmu,i386-softmmu,x86_64-softmmu; \
    make -j$(nproc) all; \
    make install; \
    cd ..; \
    rm -rf qemu-*;

ENV PATH=/opt/qemu/bin:$PATH

ENV SEL4CP_SDK_VERSION=1.2.6

# branch: rust-seL4
RUN git clone \
        https://github.com/coliasgroup/sel4cp.git \
        --branch keep/286ebb642150779b8d2ed119b0c43b62 \
        --config advice.detachedHead=false

# branch: rust-sel4cp
RUN git clone \
        https://github.com/coliasgroup/seL4.git \
        --branch keep/fc80c9ad05d33e77a6b850dae8eb4b83 \
        --config advice.detachedHead=false \
        sel4cp/seL4

RUN set -eux; \
    cd sel4cp; \
    python3.9 -m venv pyenv; \
    ./pyenv/bin/pip install --upgrade pip setuptools wheel; \
    ./pyenv/bin/pip install -r requirements.txt; \
    ./pyenv/bin/pip install sel4-deps; \
    ./pyenv/bin/python3 build_sdk.py --sel4 ./seL4; \
    chmod a+rX release/sel4cp-sdk-$SEL4CP_SDK_VERSION/bin/sel4cp; \
    mkdir /opt/sel4cp; \
    mv release/sel4cp-sdk-$SEL4CP_SDK_VERSION /opt/sel4cp; \
    rm -rf $HOME/.cache/pyoxidizer; \
    cd ..; \
    rm -rf sel4cp;

ENV SEL4CP_SDK=/opt/sel4cp/sel4cp-sdk-$SEL4CP_SDK_VERSION

RUN git clone \
        https://github.com/seL4/website_pr_hosting \
        --branch PR_280 \
        --config advice.detachedHead=false \
        content

RUN set -eux; \
    (cd content/localhost && find . -print -depth | cpio -o -H newc) > content.cpio; \
    rm -rf content

ARG UID
ARG GID

RUN groupadd -f -g $GID x && useradd -u $UID -g $GID -G sudo -m -p x x
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers # for convenience

USER x

RUN curl -sSf https://sh.rustup.rs | \
        bash -s -- -y --no-modify-path --default-toolchain none

ENV PATH=/home/x/.cargo/bin:$PATH

WORKDIR /work
