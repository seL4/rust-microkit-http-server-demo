BUILD ?= build

build_dir := $(BUILD)

microkit_board := qemu_arm_virt
microkit_config := debug
microkit_sdk_config_dir := $(MICROKIT_SDK)/board/$(microkit_board)/$(microkit_config)

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf $(build_dir)

### Protection domains

target_cc := aarch64-none-elf-gcc
target_bindgen_clang_args := --sysroot=/opt/gcc-aarch64-none-elf-sysroot

rust_target_path := support/targets
rust_microkit_target := aarch64-sel4-microkit
target_dir := $(build_dir)/target

common_env := \
	CC_$(subst -,_,$(rust_microkit_target))=$(target_cc) \
	BINDGEN_EXTRA_CLANG_ARGS_$(subst -,_,$(rust_microkit_target))="$(target_bindgen_clang_args)" \
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

content_cpio := /tmp/content.cpio

qemu_cmd := \
	qemu-system-aarch64 \
		-machine virt \
		-cpu cortex-a53 -m size=1G \
		-device loader,file=$(loader),addr=0x70000000,cpu-num=0 \
		-serial mon:stdio \
		-nographic \
		-device virtio-net-device,netdev=netdev0 \
		-netdev user,id=netdev0,hostfwd=tcp::8080-:80,hostfwd=tcp::8443-:443 \
		-device virtio-blk-device,drive=blkdev0 \
		-blockdev node-name=blkdev0,read-only=on,driver=file,filename=$(content_cpio)

.PHONY: run
run: $(loader)
	$(qemu_cmd)

.PHONY: test
test: test.py $(loader)
	python3 $< $(qemu_cmd)
