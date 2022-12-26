build_dir := build

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf $(build_dir)

kernel_source_dir := seL4
kernel_build_dir := $(build_dir)/kernel/build
kernel_install_dir := $(build_dir)/kernel/install
kernel_settings := kernel-settings.cmake
cross_compiler_prefix := aarch64-linux-gnu-

.PHONY: configure-kernel
configure-kernel:
	cmake \
		-DCROSS_COMPILER_PREFIX=$(cross_compiler_prefix) \
		-DCMAKE_TOOLCHAIN_FILE=gcc.cmake \
		-DCMAKE_INSTALL_PREFIX=$(kernel_install_dir) \
		-C $(kernel_settings) \
		-G Ninja \
		-S $(kernel_source_dir) \
		-B $(kernel_build_dir)

build_kernel_intermediate := $(build_dir)/kernel/build.intermediate

.INTERMDIATE: $(build_kernel_intermediate)
$(build_kernel_intermediate): configure-kernel
	ninja -C $(kernel_build_dir) all

.PHONY: install-kernel
install-kernel: $(build_kernel_intermediate)
	ninja -C $(kernel_build_dir) install
	install -D -T $(kernel_build_dir)/gen_config/kernel/gen_config.json $(kernel_install_dir)/support/config.json
	install -D -T $(kernel_build_dir)/kernel.dtb $(kernel_install_dir)/support/kernel.dtb
	install -D -T $(kernel_build_dir)/gen_headers/plat/machine/platform_gen.yaml $(kernel_install_dir)/support/platform-info.yaml

rust_source_dir := rust-seL4
manifest_path := $(rust_source_dir)/Cargo.toml
rust_target_path := $(rust_source_dir)/support/targets
target_dir := $(build_dir)/target
rust_sel4_target := aarch64-unknown-sel4
rust_bare_metal_target := aarch64-unknown-none

cargo_build := \
	RUST_TARGET_PATH=$(abspath $(rust_target_path)) \
	SEL4_PREFIX=$(abspath $(kernel_install_dir)) \
		cargo build \
			--locked \
			--manifest-path $(abspath $(manifest_path)) \
			--target-dir $(abspath $(target_dir)) \
			--out-dir $(build_dir)

app_crate := minimal-with-state
app := $(build_dir)/$(app_crate).elf
app_intermediate := $(build_dir)/app.intermediate

$(app): $(app_intermediate)

.INTERMDIATE: $(app_intermediate)
$(app_intermediate):
	$(cargo_build) \
		--target $(rust_sel4_target) \
		-p $(app_crate)

loader_crate := loader
loader := $(build_dir)/$(loader_crate)
loader_intermediate := $(build_dir)/loader.intermediate
loader_config := loader-config.json

$(loader): $(loader_intermediate)

.INTERMDIATE: $(loader_intermediate)
$(loader_intermediate): $(app)
	CC=$(cross_compiler_prefix)gcc \
	SEL4_APP=$(abspath $(app)) \
	SEL4_LOADER_CONFIG=$(abspath $(loader_config)) \
		$(cargo_build) \
			--target $(rust_bare_metal_target) \
			-p $(loader_crate)

.PHONY: run
run: $(loader)
	qemu-system-aarch64 \
		-machine virt,virtualization=on \
		-cpu cortex-a57 \
		-smp 2 -m 1024 \
		-nographic \
		-serial mon:stdio \
		-kernel $<
