#
# Copyright 2023, Colias Group, LLC
#
# SPDX-License-Identifier: BSD-2-Clause
#

# This repo's code mirrors that of a demo found in the rust-sel4 repo.

set -eu

external_rust_seL4_dir=../../rust-sel4
external_demo_dir=$external_rust_seL4_dir/crates/examples/microkit/http-server

cp $external_rust_seL4_dir/rust-toolchain.toml .
cp $external_rust_seL4_dir/support/targets/aarch64-sel4-microkit.json support/targets
rm -r crates
cp -r $external_demo_dir crates
find crates -name Cargo.nix -delete
mv crates/*.system .

subst='s,path = "\(../\)*../../../../\([^"]*\)",git = "https://github.com/seL4/rust-sel4",g' \
# subst='s,path = "\(../\)*../../../../\([^"]*\)",path = "/rust-sel4/crates/\2",g' \

find crates -name Cargo.toml -exec sed -i "$subst" {} +

cargo update -w -p sel4-microkit

disk_img_dst=resources/disk.img.gz
if [ ! -e $disk_img_dst ]; then
    attr_path=worlds.aarch64.qemu-arm-virt.microkit.instances.microkit.examples.http-server.smallDiskImage
    out_path=$(nix-build $external_rust_seL4_dir -A $attr_path --no-out-link)
    gzip < $out_path/disk.img > $disk_img_dst
fi
