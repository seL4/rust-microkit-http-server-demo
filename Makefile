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
		$(sel4cp_source_dir)/release

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
	SEL4_CONFIG=$(abspath $(sel4cp_sdk_config_dir)/config.json) \
	SEL4_INCLUDE_DIRS=$(abspath $(sel4cp_sdk_config_dir)/include)

common_options := \
	--locked \
	-Z unstable-options \
	-Z bindeps \
	-Z build-std=core,alloc,compiler_builtins \
	-Z build-std-features=compiler-builtins-mem \
	--target $(rust_sel4cp_target) \
	--release \
	--target-dir $(abspath $(target_dir)) \
	--out-dir $(build_dir)

artist_crate := banscii-artist
artist := $(build_dir)/$(artist_crate).elf
artist_intermediate := $(build_dir)/artist.intermediate

$(artist): $(artist_intermediate)

.INTERMDIATE: $(artist_intermediate)
$(artist_intermediate):
	$(common_env) \
		cargo build \
			$(common_options) \
			-p $(artist_crate)

assistant_crate := banscii-assistant
assistant := $(build_dir)/$(assistant_crate).elf
assistant_intermediate := $(build_dir)/assistant.intermediate

$(assistant): $(assistant_intermediate)

.INTERMDIATE: $(assistant_intermediate)
$(assistant_intermediate):
	$(common_env) \
		cargo build \
			$(common_options) \
			-p $(assistant_crate)

pl011_driver_crate := banscii-pl011-driver
pl011_driver := $(build_dir)/$(pl011_driver_crate).elf
pl011_driver_intermediate := $(build_dir)/pl011_driver.intermediate

$(pl011_driver): $(pl011_driver_intermediate)

.INTERMDIATE: $(pl011_driver_intermediate)
$(pl011_driver_intermediate):
	$(common_env) \
		cargo build \
			$(common_options) \
			-p $(pl011_driver_crate)

### Loader

loader := $(build_dir)/loader.img
loader_intermediate := $(build_dir)/loader.intermediate

$(loader): $(loader_intermediate)

# TODO get pyoxidizer working
.PHONY: $(loader_intermediate)
$(loader_intermediate): $(assistant) $(artist) $(pl011_driver)
	PYTHONPATH=$(sel4cp_source_dir)/tool:$$PYTHONPATH \
	SEL4CP_SDK=$(sel4cp_sdk_dir) \
		python3 -m sel4coreplat \
			banscii.system \
			--search-path $(build_dir) \
			--board $(sel4cp_board) \
			--config $(sel4cp_config) \
			-o $(build_dir)/loader.img \
			-r $(build_dir)/report.txt

.PHONY: run
run: $(loader)
	qemu-system-aarch64 \
		-machine virt \
		-cpu cortex-a53 -m size=1G \
		-device loader,file=$(loader),addr=0x70000000,cpu-num=0 \
		-serial mon:stdio \
		-nographic

###

external_rust_seL4_dir := ../rust-seL4
external_banscii_dir := $(external_rust_seL4_dir)/crates/examples/sel4cp/banscii

.PHONY: update
update:
	rm -r crates && cp -r $(external_banscii_dir)/pds crates
	cp $(external_banscii_dir)/banscii.system .
	cp $(external_rust_seL4_dir)/support/targets/aarch64-sel4cp-minimal.json support/targets
