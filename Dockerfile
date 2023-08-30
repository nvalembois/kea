FROM alpine:3 AS build

ARG VERSION="2.5.1"
ARG SIGNATURE="7A5E084CACA51884"

ADD https://downloads.isc.org/isc/kea/$VERSION/kea-$VERSION.tar.gz /tmp/kea.tar.gz
ADD https://downloads.isc.org/isc/kea/$VERSION/kea-$VERSION.tar.gz.asc /tmp/kea.tar.gz.asc
ADD isc.gpgpub /tmp/isc.gpgpub

RUN apk add gnupg && \
    gpg --import /tmp/isc.gpgpub && \
    gpg --status-fd 1 --verify /tmp/kea.tar.gz.asc /tmp/kea.tar.gz 2>/dev/null | grep -q "GOODSIG ${SIGNATURE} " && \
    tar -C /tmp -xf /tmp/kea.tar.gz && \
    mv /tmp/kea-${VERSION} /tmp/kea

RUN apk add g++ linux-headers make automake libtool musl-dev boost boost-dev boost-static \
            openssl openssl-dev openssl-libs-static log4cplus log4cplus-dev log4cplus-static && \
    cd /tmp/kea && \
    ./configure LDFLAGS='-static' --prefix=/ && \
    make && \
    make install DESTDIR=/rootfs && \
    echo 'nogroup:*:10000:nobody' > /rootfs/etc/group && \
    echo 'nobody:*:10000:10000:::' > /rootfs/etc/passwd && \
    rm -R /rootfs/include /rootfs/lib/*a /rootfs/etc/kea/*.conf /rootfs/share/doc /rootfs/share/man /rootfs/share/kea/scripts

FROM scratch

LABEL org.opencontainers.image.source=https://github.com/nvalembois/kea-dhcpd
LABEL org.opencontainers.image.description="DHCP Server by isc-kea"

COPY --from=build /rootfs /

USER 10000:10000
ENTRYPOINT ["/sbin/kea-dhcp4"]
CMD ["-c /etc/kea/dhcp4.conf"]
