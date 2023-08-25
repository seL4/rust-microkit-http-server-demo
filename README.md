# HTTP Server

This repository demonstrates the use of the [rust-seL4](https://github.com/coliasgroup/rust-seL4) crates with the [seL4 Core Platform](https://github.com/BreakawayConsulting/sel4cp).

### Rustdoc for the `sel4cp` crate

https://coliasgroup.com/rust-seL4/views/aarch64-sel4cp/aarch64-sel4cp/doc/sel4cp/index.html

### Quick start

The only requirements for getting started are Git, Make, and Docker.

First, clone this respository:

```
git clone https://github.com/coliasgroup/rust-seL4-sel4cp-http-server-demo.git
cd rust-seL4-sel4cp-http-server-demo
```

Next, build, run, and enter a Docker container for development:

```
make -C docker/ run && make -C docker/ exec
```

Inside the container, build and emulate the demo:

```
make run
```

Finally, in a browser, access http://localhost:9080 or https://localhost:9443.
