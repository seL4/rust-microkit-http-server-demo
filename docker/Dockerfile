FROM trustworthysystems/sel4

RUN apt-get update -q && apt-get install -y --no-install-recommends \
    wget \
    sudo man vim \
    bash-completion \
    python3-venv \
    musl-tools \
    pandoc \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    && rm -rf /var/lib/apt/lists/*

# Derived from:
# https://hub.docker.com/r/rustlang/rust/dockerfile

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN set -eux; \
    url="https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init"; \
    wget "$url"; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --default-toolchain nightly; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

ENV CARGO_HOME=

RUN set -eux; \
    url="https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz"; \
    wget -nv "$url"; \
    tar -xf gcc-arm-*.tar.xz; \
    rm gcc-arm-*.tar.xz; \
    mv gcc-arm-* gcc-aarch64-none-elf;

ENV PATH=/gcc-aarch64-none-elf/bin:$PATH

RUN mkdir /deps

WORKDIR /deps

ENV SEL4CP_SDK_VERSION=1.2.6

# branch: rust-sel4cp
RUN git clone \
        https://github.com/coliasgroup/seL4.git \
        --branch keep/fc80c9ad05d33e77a6b850dae8eb4b83 \
        --config advice.detachedHead=false

# branch: rust-seL4
RUN git clone \
        https://github.com/coliasgroup/sel4cp.git \
        --branch keep/54c22948cd0fde4035dde293fbe572ca \
        --config advice.detachedHead=false

RUN cd sel4cp && \
        python3.9 -m venv pyenv && \
        ./pyenv/bin/pip install --upgrade pip setuptools wheel && \
        ./pyenv/bin/pip install -r requirements.txt && \
        ./pyenv/bin/pip install sel4-deps

RUN cd sel4cp && \
        ./pyenv/bin/python3 build_sdk.py --sel4 ../seL4 && \
        chmod a+rwX release/sel4cp-sdk-$SEL4CP_SDK_VERSION/bin/sel4cp

ENV SEL4CP_SDK=/deps/sel4cp/release/sel4cp-sdk-$SEL4CP_SDK_VERSION

ARG UID
ARG GID

RUN groupadd -f -g $GID x && useradd -u $UID -g $GID -G sudo -m -p x x
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers # for convenience

USER x

WORKDIR /work
