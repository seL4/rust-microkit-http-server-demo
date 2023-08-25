# This repo's code mirrors that of a demo found in the rust-seL4 repo.

set -eu

external_rust_seL4_dir=../../rust-seL4
external_demo_dir=$external_rust_seL4_dir/crates/examples/sel4cp/http-server

cp $external_rust_seL4_dir/rust-toolchain.toml .
cp $external_rust_seL4_dir/support/targets/aarch64-sel4cp.json support/targets
rm -r crates
cp -r $external_demo_dir crates
mv crates/*.system .

subst='s,path = "\(../\)*../../../../\([^"]*\)",git = "https://github.com/coliasgroup/rust-seL4",g' \
# subst='s,path = "\(../\)*../../../../\([^"]*\)",path = "/rust-seL4/crates/\2",g' \

find crates -name Cargo.toml -exec sed -i "$subst" {} +

cargo update -w -p sel4
