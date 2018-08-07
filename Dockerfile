FROM debian:stable-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y && \
	apt-get install -y vim nano iproute2 net-tools procps proot qemu-user-static && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	mkdir -p /data

COPY xzb /xzb
VOLUME /data

CMD proot -R /xzb -b /data -w / -q "qemu-mipsel-static -cpu 24KEc" /bin/sh /bin/etm_monitor
