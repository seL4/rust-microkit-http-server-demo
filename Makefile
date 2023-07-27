build_dir := build

sel4cp_board := qemu_arm_virt
sel4cp_config := debug
sel4cp_sdk_config_dir := $(SEL4CP_SDK)/board/$(sel4cp_board)/$(sel4cp_config)

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf $(build_dir)

### Protection domains

rust_target_path := support/targets
rust_sel4cp_target := aarch64-sel4cp-minimal
target_dir := $(build_dir)/target

common_env := \
	SEL4_INCLUDE_DIRS=$(abspath $(sel4cp_sdk_config_dir)/include)

common_options := \
	-Z build-std=core,alloc,compiler_builtins \
	-Z build-std-features=compiler-builtins-mem \
	--target $(rust_sel4cp_target) \
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
	banscii-artist \
	banscii-assistant \
	banscii-pl011-driver

built_crates := $(foreach crate,$(crates),$(call target_for_crate,$(crate)))

$(eval $(foreach crate,$(crates),$(call build_crate,$(crate))))

### Loader

system_description := banscii.system

loader := $(build_dir)/loader.img

$(loader): $(system_description) $(built_crates)
	$(SEL4CP_SDK)/bin/sel4cp \
		$< \
		--search-path $(build_dir) \
		--board $(sel4cp_board) \
		--config $(sel4cp_config) \
		-r $(build_dir)/report.txt \
		-o $@

### Run

qemu_cmd := \
	qemu-system-aarch64 \
		-machine virt \
		-cpu cortex-a53 -m size=1G \
		-device loader,file=$(loader),addr=0x70000000,cpu-num=0 \
		-serial mon:stdio \
		-nographic

.PHONY: run
run: $(loader)
	$(qemu_cmd)

.PHONY: test
test: test.py $(loader)
	python3 $< $(qemu_cmd)
