# Banscii

This repository demonstrates the use of the [rust-seL4](https://github.com/coliasgroup/rust-seL4) crates with the [seL4 Core Platform](https://github.com/BreakawayConsulting/sel4cp).

Banksy has been struggling to keep up with the growing demand for his art.
He has decided to leverage trustworthy operating system technology to scale up production without compromising the integrity or value of his work.
A fleet of _Banscii_ devices will begin producing his art on his behalf.
These devices will contain his most precious artistic secrets, along with cryptographic keys which will be used to authenticate the work they produce.

The Banscii system is comprised of three components:

- `pl011-driver` (untrusted):
    Serial driver.
- `assistant` (untrusted):
    Interacts with the human operator with a text interface via `pl011-driver` to receive subject material and, in concert with `artist`, return authentic works of art.
    `assistant` takes a subject (a string), renders it to greyscale ASCII art using a TrueType font, and then passes it to `artist` for completion.
- `artist` (trusted):
    Receives drafts from `assistant`, which it completes, digitally signs, and then returns as authentic Bansky pieces.

### Rustdoc for the `sel4cp` crate

https://coliasgroup.com/rust-seL4-html/views/aarch64-sel4cp/aarch64-sel4cp/doc/sel4cp/index.html

### Quick start

The only requirements for getting started are Git, Make, and Docker.

First, clone this respository:

```
git clone https://github.com/coliasgroup/rust-seL4-sel4cp-demo.git
cd rust-seL4-sel4cp-demo
```

Next, build, run, and enter a Docker container for development:

```
make -C docker/ run && make -C docker/ exec
```

Inside the container, build and emulate the demo:

```
make run
```

At the prompt, enter some text:

```
banscii> Hello, World!

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@#x@@@+:@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%@
@+=@@@:+@@@@%%%@%@@@@@%@@@@@@@#x%@@@@@@@@@ @@@@@@@@ @@@@#x%@@@@%####@@@%@@@@#x++x@@@:=@
@:x@@@.%@%-=x##@ +@@@+ @@@@%=:++ %@@@@@@@x-@@@#@@@@.@%=:++ %=.:+x#x #@+ @@@+-:%@#:x@.#@
% xxx= ++x ==+%@ #@@@+-@@@x.#@@#-@@@@@@@@-#@@# #@@x:x.#@@#-@@.%@#=:#@@+:@@@@:x@@%-%+-@@
:.x#%x-@@==@@+%@.:=++x.==++.++==@%#@@@@@#-@@@- #@@-x+.x+==@@@.## =+++++.==@@==+=+@@.x@@
x-%@@#.@@%-==x@@@@@@@@@@@@@@%@@@@=:@@@@@==@x:%+.x-+@@%%@@@@@@#+@@%@@@@@@@@@@@%%@@@@%@@@
@x#@@@:=@@@@@@@@@@@@@@@@@@@@@@@@x=@@@@@@%:=#@@@%x@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

Signature:
3f4314ef18dd2380ce57978b68929c1144ed4066a5f72f14ac84963c3870dd1f
a7cec3ced3c4f7d27c3ab770fc023746dd7991bede3c70cc2392fbddb7e918e4
35641576ee267c3e08c1b7b628fab90b7750e1b243aadac69bee6b12bb2af043
dd4ea4d3e5774e283b737ee39066a34fb8ab1ddd723f624c356d0b692179ab2f
ec47f2183ef50a24c9ff79008252dae807dcb144642e5d3877887cc8719adf33
53b9253ab211ba106d746c722e1c3973aa5bbaad987e19440c6d56934842b311
83bd3ee3257bb57fcb0aba0e275fa718e47d72706fe8cba1e46df3171f5791c8
dfa38c0cd6e6a72693b265c077a52e84bd671563fc2d4a056310d6b5023a13cf
```
