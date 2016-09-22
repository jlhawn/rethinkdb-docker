ORG?=jlhawn
PROJ?=rethinkdb
VERSION?=2.3.5

image:

	# Build the rethinkdb-build image.
	docker build --build-arg VERSION=$(VERSION) -t rethinkdb-build -f Dockerfile.build .

	# Create a container from that image, copy out the built RethinkDB binary
	# into the local bin directory, and remove the container.
	docker rm -f rethinkdb-build || true
	docker create --name rethinkdb-build rethinkdb-build
	docker cp rethinkdb-build:/usr/local/bin/rethinkdb .
	docker rm rethinkdb-build

	# Build the minimal image.
	docker build -t $(ORG)/$(PROJ):$(VERSION) -f Dockerfile.min .

push:

	docker push $(ORG)/$(PROJ):$(VERSION)
