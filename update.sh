# This repo's code mirrors that of a demo found in the rust-sel4 repo.

set -eu

external_rust_seL4_dir=../../rust-sel4
external_demo_dir=$external_rust_seL4_dir/crates/examples/microkit/http-server

cp $external_rust_seL4_dir/rust-toolchain.toml .
cp $external_rust_seL4_dir/support/targets/aarch64-sel4-microkit.json support/targets
rm -r crates
cp -r $external_demo_dir crates
mv crates/*.system .

subst='s,path = "\(../\)*../../../../\([^"]*\)",git = "https://github.com/seL4/rust-sel4",g' \
# subst='s,path = "\(../\)*../../../../\([^"]*\)",path = "/rust-sel4/crates/\2",g' \

find crates -name Cargo.toml -exec sed -i "$subst" {} +

cargo update -w -p sel4
