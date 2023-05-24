build_dir := build

kernel_source_dir := seL4
sel4cp_source_dir := sel4cp

sel4cp_board := qemu_arm_virt
sel4cp_config := debug
sel4cp_sdk_dir := $(sel4cp_source_dir)/release/sel4cp-sdk-1.2.6
sel4cp_sdk_config_dir := $(sel4cp_sdk_dir)/board/$(sel4cp_board)/$(sel4cp_config)

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf \
		$(build_dir) \
		$(sel4cp_source_dir)/build \
		$(sel4cp_source_dir)/release \
		$(sel4cp_source_dir)/pyenv \
		$(sel4cp_source_dir)/tool/build

### sel4cp SDK

.PHONY:
create-sel4cp-sdk-venv:
	cd $(sel4cp_source_dir) && \
		python3.9 -m venv pyenv && \
		./pyenv/bin/pip install --upgrade pip setuptools wheel && \
		./pyenv/bin/pip install -r requirements.txt && \
		./pyenv/bin/pip install sel4-deps

.PHONY:
build-sel4cp-sdk: create-sel4cp-sdk-venv
	cd $(sel4cp_source_dir) && \
		./pyenv/bin/python3 build_sdk.py --sel4 $(abspath $(kernel_source_dir))

### Protection domains

rust_target_path := support/targets
rust_sel4cp_target := aarch64-sel4cp-minimal
target_dir := $(build_dir)/target

common_env := \
	RUST_TARGET_PATH=$(abspath $(rust_target_path)) \
	SEL4_INCLUDE_DIRS=$(abspath $(sel4cp_sdk_config_dir)/include)

common_options := \
	-Z build-std=core,alloc,compiler_builtins \
	-Z build-std-features=compiler-builtins-mem \
	--target $(rust_sel4cp_target) \
	--release \
	--target-dir $(abspath $(target_dir)) \
	--out-dir $(build_dir)

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
	$(sel4cp_sdk_dir)/bin/sel4cp \
		$< \
		--search-path $(build_dir) \
		--board $(sel4cp_board) \
		--config $(sel4cp_config) \
		-r $(build_dir)/report.txt \
		-o $(build_dir)/loader.img

.PHONY: run
run: $(loader)
	qemu-system-aarch64 \
		-machine virt \
		-cpu cortex-a53 -m size=1G \
		-device loader,file=$(loader),addr=0x70000000,cpu-num=0 \
		-serial mon:stdio \
		-nographic
