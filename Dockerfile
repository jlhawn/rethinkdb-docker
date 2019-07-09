FROM alpine:3.10 AS builder

ARG VERSION=2.3.6

# Also: ppc64le, s390x
ARG CARCH=x86_64

RUN \
    apk add --update \
        alpine-sdk bash python perl protobuf-dev icu-dev \
        libressl-dev curl-dev boost-dev linux-headers \
        bsd-compat-headers m4 paxmark libexecinfo-dev

RUN \
    wget https://download.rethinkdb.com/dist/rethinkdb-$VERSION.tgz && \
    gunzip rethinkdb-$VERSION.tgz && \
    tar xvf rethinkdb-$VERSION.tar && \
    rm rethinkdb-$VERSION.tar

COPY *.patch ./rethinkdb-$VERSION/

ARG PATCHES="libressl-all.patch \
    openssl-1.1-all.patch \
    enable-build-ppc64le.patch \
    enable-build-s390x.patch \
    paxmark-x86_64.patch \
    extproc-js-all.patch"

RUN cd rethinkdb-$VERSION && \
    for i in $PATCHES; do \
        case $i in \
        *-$CARCH.patch|*-all.patch) \
            echo $i; patch -p1 < "$i"; \
        esac; \
    done

RUN \
    cd rethinkdb-$VERSION && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --dynamic all \
        --with-system-malloc && \
    export LDFLAGS="$LDFLAGS -lexecinfo" && \
    export CXXFLAGS="$CXXFLAGS -DBOOST_NO_CXX11_EXPLICIT_CONVERSION_OPERATORS -fno-delete-null-pointer-checks" && \
    make --jobs $(grep -c '^processor' /proc/cpuinfo) SPLIT_SYMBOLS=1 || \
    paxmark -m build/external/v8_3.30.33.16/build/out/x64.release/mksnapshot && \
    make --jobs $(grep -c '^processor' /proc/cpuinfo) SPLIT_SYMBOLS=1 && \
    mv build/release_system/rethinkdb /usr/local/bin/

FROM alpine:latest

RUN \
    apk add --update \
        ca-certificates libstdc++ libgcc libcurl protobuf libexecinfo

COPY --from=builder /usr/local/bin/rethinkdb /usr/local/bin/rethinkdb

ENTRYPOINT ["rethinkdb"]
