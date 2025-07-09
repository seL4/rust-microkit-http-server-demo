#
# Copyright 2023, Colias Group, LLC
#
# SPDX-License-Identifier: BSD-2-Clause
#

BUILD ?= build

build_dir := $(BUILD)

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf $(build_dir)

microkit_board := qemu_virt_aarch64
microkit_config := debug
microkit_sdk_config_dir := $(MICROKIT_SDK)/board/$(microkit_board)/$(microkit_config)

sel4_include_dirs := $(microkit_sdk_config_dir)/include

### Protection domains

target := aarch64-sel4-microkit

target_cc := aarch64-none-elf-gcc

crate = $(build_dir)/$(1).elf

define build_crate

$(crate): $(crate).intermediate

.INTERMDIATE: $(crate).intermediate
$(crate).intermediate:
	CC_$(subst -,_,$(target))=$(target_cc) \
	SEL4_INCLUDE_DIRS=$(abspath $(sel4_include_dirs)) \
		cargo build \
			--target-dir $(build_dir)/target \
			--artifact-dir $(build_dir) \
			--target $(target) \
			--release \
			-p $(1)

endef

crate_names := \
	microkit-http-server-example-server \
	microkit-http-server-example-pl031-driver \
	microkit-http-server-example-sp804-driver \
	microkit-http-server-example-virtio-net-driver \
	microkit-http-server-example-virtio-blk-driver

crates := $(foreach crate_name,$(crate_names),$(call crate,$(crate_name)))

$(eval $(foreach crate_name,$(crate_names),$(call build_crate,$(crate_name))))

### Loader

system_description := http-server.system

loader := $(build_dir)/loader.img

$(loader): $(system_description) $(crates)
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
		-machine virt,virtualization=on -cpu cortex-a53 -m size=2G \
		-serial mon:stdio \
		-nographic \
		-device loader,file=$(loader),addr=0x70000000,cpu-num=0 \
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
