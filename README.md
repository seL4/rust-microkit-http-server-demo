# Simple build system demo for [rust-seL4](https://gitlab.com/coliasgroup/rust-seL4)

This repository demonstrates the use of the [rust-seL4](https://gitlab.com/coliasgroup/rust-seL4) crates with a simple build system.

### Quick start

The only requirements for getting started are Git, Make, and Docker.

First, clone this respository:

```
git clone https://gitlab.com/coliasgroup/rust-seL4-simple-build-system-demo
cd rust-seL4-simple-build-system-demo
```

Next, build, run, and enter a Docker container for development:

```
make -C docker/ run && make -C docker/ exec
```

Finally, inside the container, build and emulate a simple seL4-based system with a root task written in Rust:

```
make install-kernel
make run
```
