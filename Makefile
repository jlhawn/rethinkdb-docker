ORG?=jlhawn
PROJ?=rethinkdb
VERSION?=2.3.6
CARCH?=x86_64

image:
	docker build --build-arg CARCH=$(CARCH) -t $(ORG)/$(PROJ):$(VERSION) -f Dockerfile .

push:
	docker push $(ORG)/$(PROJ):$(VERSION)
