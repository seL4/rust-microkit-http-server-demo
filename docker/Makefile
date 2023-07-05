work_root := ..

label := rust-sel4-sel4cp-demo
image_repository := $(label)
image_tag := $(image_repository)
container_name := $(label)
dockerfile := Dockerfile

uid := $(shell id -u)
gid := $(shell id -g)

.PHONY: none
none:

.PHONY: build
build:
	docker build \
		--build-arg UID=$(uid) --build-arg GID=$(gid) \
		--label $(label) -t $(image_tag) -f $(dockerfile) .

.PHONY: run
run: build
	docker run -d --name $(container_name) --label $(label) \
		--mount type=bind,src=$(abspath $(work_root)),dst=/work \
		$(image_tag) sleep inf

.PHONY: exec
exec:
	docker exec -it $(container_name) bash

.PHONY: rm-container
rm-container:
	for id in $$(docker ps -aq -f "name=^$(container_name)$$"); do \
		docker rm -f $$id; \
	done
