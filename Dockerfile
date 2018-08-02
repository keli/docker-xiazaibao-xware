FROM debian:stable-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y && \
	apt-get install -y net-tools procps proot qemu-user-static && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	echo '127.0.0.1	report.em.sandai.net' >> /etc/hosts && \
	mkdir -p /data

COPY xzb /xzb
VOLUME /data

CMD proot -R /xzb -b /proc -b /data -w / -q "qemu-mipsel-static -cpu 24KEc" /bin/sh /bin/etm_monitor
