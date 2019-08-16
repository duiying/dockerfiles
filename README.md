<h1 align="center"> dockerfiles </h1>
<p align="center"> 
php dev dockerfiles
</p>

阿里云容器镜像服务：https://cr.console.aliyun.com/cn-beijing/instances/repositories

```bash
# 拉取Swoole镜像
docker pull registry.cn-beijing.aliyuncs.com/duiying/php7.3-swoole4.3.5:1.0
# 给Swoole镜像打一个标签，目的是简化其名称
docker tag registry.cn-beijing.aliyuncs.com/duiying/php7.3-swoole4.3.5:1.0 php-swoole:1.0
# 新建映射目录
mkdir /root/swoole
# 启动容器
docker run -d -v /root/swoole:/root/swoole -p 9501:9501 --name php-swoole php-swoole:1.0
```