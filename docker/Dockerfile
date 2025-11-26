#
# Copyright 2023, Colias Group, LLC
#
# SPDX-License-Identifier: BSD-2-Clause
#

FROM debian:bookworm

RUN apt-get update -q && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    unzip \
    ca-certificates \
    # for qemu
    ninja-build \
    pkg-config \
    libglib2.0-dev \
    libaio-dev \
    libpixman-1-dev \
    libslirp-dev \
    # for bindgen
    libclang-dev \
    # for test script
    python3-pexpect \
    python3-requests \
    # for hacking
    bash-completion \
    man \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    url="https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-elf.tar.xz"; \
    dst=/opt/gcc-aarch64-none-elf; \
    mkdir -p $dst; \
    curl -sSfL "$url" | tar -xJ -C $dst --strip-components=1;

ENV PATH=/opt/gcc-aarch64-none-elf/bin:$PATH

RUN set -eux; \
    version=7.2.0; \
    url="https://download.qemu.org/qemu-${version}.tar.xz"; \
    curl -sSfL "$url" | tar -xJ; \
    cd qemu-*; \
    qemu_arm_virt_sp804_url="https://github.com/coliasgroup/qemu/commit/cd3b78de4b5a8d7c79ae99dab2b5e0ab1ba0ffac.patch"; \
    curl -sSfL "$qemu_arm_virt_sp804_url" | patch -p1; \
    ./configure \
        --prefix=/opt/qemu \
        --enable-linux-aio \
        --enable-slirp \
        --target-list=aarch64-softmmu; \
    make -j$(nproc) all; \
    make install; \
    rm -rf $(pwd);

ENV PATH=/opt/qemu/bin:$PATH

ENV MICROKIT_SDK=/opt/microkit/sdk

RUN set -eux; \
    mkdir -p $MICROKIT_SDK; \
    cd $MICROKIT_SDK; \
    curl -L \
        "https://github.com/seL4/microkit/releases/download/2.1.0/microkit-sdk-2.1.0-linux-x86-64.tar.gz" \
            | tar -xzf - --strip-components=1; \
    chmod -R a+X .; # HACK

ARG UID
ARG GID

RUN set -eux; \
    if [ $UID -eq 0 ]; then \
        if [ $GID -ne 0 ]; then \
            echo "error: \$UID == 0 but \$GID != 0" >&2; \
            exit 1; \
        fi; \
    else \
        if getent passwd $UID; then \
            echo "error: \$UID $UID already exists" >&2; \
            exit 1; \
        fi; \
        if ! getent group $GID; then \
            groupadd --gid $GID x; \
        fi; \
        useradd --uid $UID --gid $GID --groups sudo --create-home x; \
    fi;

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $UID

RUN set -eux; \
    if [ $UID -ne 0 ]; then \
        curl -sSf https://sh.rustup.rs | \
            bash -s -- -y --no-modify-path --default-toolchain none; \
    fi;

ENV PATH=/home/x/.cargo/bin:$PATH

WORKDIR /work
