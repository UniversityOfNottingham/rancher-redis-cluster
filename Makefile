REPO ?= uonappdev.azurecr.io
VERSION ?= dev
PROJECT ?= cache

.PHONY: build push build-redis-server build-redis-sentinel push-redis-server push-redis-sentinel

build: build-redis-server build-redis-sentinel

push: build push-redis-server push-redis-sentinel

build-redis-server:
	docker build -t $(REPO)/$(PROJECT)/redis-server:$(VERSION) redis-server/

build-redis-sentinel:
	docker build -t $(REPO)/$(PROJECT)/redis-sentinel:$(VERSION) redis-sentinel/

push-redis-server:
	docker push $(REPO)/$(PROJECT)/redis-server:$(VERSION)

push-redis-sentinel:
	docker push $(REPO)/$(PROJECT)/redis-sentinel:$(VERSION)

.PHONY: release
release:
	docker tag $(REPO)/$(PROJECT)/redis-server:$(VERSION) $(REPO)/redis-server:latest
	docker push $(REPO)/$(PROJECT)/redis-server:latest
	docker tag $(REPO)/$(PROJECT)/redis-sentinel:$(VERSION) $(REPO)/redis-sentinel:latest
	docker push $(REPO)/$(PROJECT)/redis-sentinel:latest

default: build
