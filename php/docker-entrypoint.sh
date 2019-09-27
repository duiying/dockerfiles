#!/bin/bash

# 定时任务
/usr/sbin/init
/usr/sbin/crond

echo "info: starting php-fpm.."

# 启动FPM
/usr/sbin/php-fpm -c /etc/php.ini -y /etc/php-fpm.conf

tail -f /dev/null