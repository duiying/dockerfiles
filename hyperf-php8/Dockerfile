FROM hyperf/hyperf:8.0-alpine-v3.13-swoole

# Change timezone
RUN set -x; \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    echo Asia/Shanghais > /etc/timezone

# Set default work directory
WORKDIR /data/www
