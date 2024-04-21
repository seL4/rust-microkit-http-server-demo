#
# Copyright 2023, Colias Group, LLC
#
# SPDX-License-Identifier: BSD-2-Clause
#

BUILD ?= build

build_dir := $(BUILD)

microkit_board := qemu_virt_aarch64
microkit_config := debug
microkit_sdk_config_dir := $(MICROKIT_SDK)/board/$(microkit_board)/$(microkit_config)

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf $(build_dir)

### Protection domains

target_cc := aarch64-none-elf-gcc

rust_target_path := support/targets
rust_microkit_target := aarch64-sel4-microkit
target_dir := $(build_dir)/target

common_env := \
	CC_$(subst -,_,$(rust_microkit_target))=$(target_cc) \
	SEL4_INCLUDE_DIRS=$(abspath $(microkit_sdk_config_dir)/include)

common_options := \
	-Z build-std=core,alloc,compiler_builtins \
	-Z build-std-features=compiler-builtins-mem \
	--target $(rust_microkit_target) \
	--release \
	--target-dir $(abspath $(target_dir)) \
	--out-dir $(abspath $(build_dir))

target_for_crate = $(build_dir)/$(1).elf
intermediate_target_for_crate = $(build_dir)/$(1).intermediate

define build_crate

$(target_for_crate): $(intermediate_target_for_crate)

.INTERMDIATE: $(intermediate_target_for_crate)
$(intermediate_target_for_crate):
	$$(common_env) \
		cargo build \
			$$(common_options) \
			-p $(1)

endef

crates := \
	microkit-http-server-example-server \
	microkit-http-server-example-pl031-driver \
	microkit-http-server-example-sp804-driver \
	microkit-http-server-example-virtio-net-driver \
	microkit-http-server-example-virtio-blk-driver

built_crates := $(foreach crate,$(crates),$(call target_for_crate,$(crate)))

$(eval $(foreach crate,$(crates),$(call build_crate,$(crate))))

### Loader

system_description := http-server.system

loader := $(build_dir)/loader.img

$(loader): $(system_description) $(built_crates)
	$(MICROKIT_SDK)/bin/microkit \
		$< \
		--search-path $(build_dir) \
		--board $(microkit_board) \
		--config $(microkit_config) \
		-r $(build_dir)/report.txt \
		-o $@

### Run

compressed_disk_img := resources/disk.img.gz
disk_img := $(build_dir)/disk.img

$(disk_img): $(compressed_disk_img)
	gunzip < $< > $@

qemu_cmd := \
	qemu-system-aarch64 \
		-machine virt -cpu cortex-a53 -m size=2G \
		-device loader,file=$(loader),addr=0x70000000,cpu-num=0 \
		-serial mon:stdio \
		-nographic \
		-device virtio-net-device,netdev=netdev0 \
		-netdev user,id=netdev0,hostfwd=tcp::8080-:80,hostfwd=tcp::8443-:443 \
		-device virtio-blk-device,drive=blkdev0 \
		-blockdev node-name=blkdev0,read-only=on,driver=file,filename=$(disk_img)

qemu_cmd_prereqs := $(loader) $(disk_img)

.PHONY: run
run: $(qemu_cmd_prereqs)
	$(qemu_cmd)

.PHONY: test
test: test.py $(qemu_cmd_prereqs)
	python3 $< $(qemu_cmd)
