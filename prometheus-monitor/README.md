# 使用 Prometheus + Grafana 监控 机器、MySQL、Redis

Prometheus + Grafana 监控的原理：  

<div align=center><img src="https://raw.githubusercontent.com/duiying/img/master/监控.png" width="600"></div>  

关于**采集器**：  

- node-exporter：负责机器的监控
- mysql-exporter：负责 MySQL 的监控
- redis-exporter：负责 Redis 的监控

关于**端口**：  

- 9100：node-exporter 暴露的端口
- 9104：mysql-exporter 暴露的端口
- 9121：redis-exporter 暴露的端口
- 9090：Prometheus 暴露的端口
- 3000：Grafana 暴露的端口

配置 Grafana：  

- create datasource：name 自定义，type 选 prometheus，url 填写 http://localhost:9090 ，保存并测试
- import dashboard：MySQL：11323 机器：8919 Redis：2751

> 当监控数据为空时的排查思路：检查对应 exporter 暴露的 metrics 接口是否有效！

