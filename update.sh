# This repo's code mirrors that of a demo found in the rust-seL4 repo.

set -eu

external_rust_seL4_dir=../../rust-seL4
external_banscii_dir=$external_rust_seL4_dir/crates/examples/sel4cp/banscii

cp $external_rust_seL4_dir/rust-toolchain.toml .
cp $external_rust_seL4_dir/support/targets/aarch64-sel4cp-minimal.json support/targets
cp $external_banscii_dir/banscii.system .
rm -r crates && cp -r $external_banscii_dir/pds crates
