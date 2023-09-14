RUST_SEL4 ?= /dev/null

work_root := ..

id := rust-microkit-http-server-demo
image_tag := $(id)
container_name := $(id)

uid := $(shell id -u)
gid := $(shell id -g)

.PHONY: none
none:

.PHONY: build
build:
	docker build \
		--build-arg UID=$(uid) --build-arg GID=$(gid) \
		-t $(image_tag) .

.PHONY: run
run: build
	docker run -d --name $(container_name) \
		--mount type=bind,src=$(abspath $(work_root)),dst=/work \
		--mount type=bind,src=$(abspath $(RUST_SEL4)),dst=/rust-sel4 \
		--publish 9080:8080/tcp \
		--publish 9443:8443/tcp \
		$(image_tag) sleep inf

.PHONY: exec
exec:
	docker exec -it $(container_name) bash

.PHONY: rm-container
rm-container:
	for id in $$(docker ps -aq -f "name=^$(container_name)$$"); do \
		docker rm -f $$id; \
	done

.PHONY: test
test: build
	docker run --rm \
		--mount type=bind,readonly,src=$(abspath $(work_root)),dst=/work \
		--mount type=bind,readonly,src=$(abspath $(RUST_SEL4)),dst=/rust-sel4 \
		-i $(image_tag) \
		make test BUILD=/tmp/build
