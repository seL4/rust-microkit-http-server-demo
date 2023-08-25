FROM trustworthysystems/sel4

WORKDIR /tmp

RUN rm -r *

RUN apt-get update -q && apt-get install -y --no-install-recommends \
    python3-venv \
    musl-tools \
    pandoc \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-recommended \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    url="https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz"; \
    wget -nv "$url"; \
    tar -xf gcc-arm-*.tar.xz; \
    rm gcc-arm-*.tar.xz; \
    mv gcc-arm-* /opt/gcc-aarch64-none-elf;

ENV PATH=/opt/gcc-aarch64-none-elf/bin:$PATH

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

ARG UID
ARG GID

RUN groupadd -f -g $GID x && useradd -u $UID -g $GID -G sudo -m -p x x
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers # for convenience

USER x

RUN curl -sSf https://sh.rustup.rs | \
        bash -s -- -y --no-modify-path --default-toolchain none

ENV PATH=/home/x/.cargo/bin:$PATH

WORKDIR /work
