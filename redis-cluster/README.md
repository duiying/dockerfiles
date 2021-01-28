# 搭建 redis-cluster 三主三从以及集群的扩容缩容

首先，容器编排，启动 6 个 redis 容器。  

```sh
docker-compose up -d
```

查看容器：  

```sh
$ docker ps
CONTAINER ID        IMAGE                             COMMAND                  CREATED             STATUS              PORTS                                                        NAMES
b175b738b0ec        daocloud.io/library/redis:5.0.9   "docker-entrypoint.s…"   8 seconds ago       Up 7 seconds        0.0.0.0:7006->7006/tcp, 6379/tcp, 0.0.0.0:17006->17006/tcp   redis7006
f9b7f2d4e1b7        daocloud.io/library/redis:5.0.9   "docker-entrypoint.s…"   8 seconds ago       Up 6 seconds        0.0.0.0:7003->7003/tcp, 6379/tcp, 0.0.0.0:17003->17003/tcp   redis7003
a3de2a0a7384        daocloud.io/library/redis:5.0.9   "docker-entrypoint.s…"   8 seconds ago       Up 7 seconds        0.0.0.0:7005->7005/tcp, 6379/tcp, 0.0.0.0:17005->17005/tcp   redis7005
bf1daf545082        daocloud.io/library/redis:5.0.9   "docker-entrypoint.s…"   8 seconds ago       Up 7 seconds        0.0.0.0:7004->7004/tcp, 6379/tcp, 0.0.0.0:17004->17004/tcp   redis7004
cf23555e09a4        daocloud.io/library/redis:5.0.9   "docker-entrypoint.s…"   8 seconds ago       Up 7 seconds        0.0.0.0:7001->7001/tcp, 6379/tcp, 0.0.0.0:17001->17001/tcp   redis7001
745746a47beb        daocloud.io/library/redis:5.0.9   "docker-entrypoint.s…"   8 seconds ago       Up 7 seconds        0.0.0.0:7002->7002/tcp, 6379/tcp, 0.0.0.0:17002->17002/tcp   redis7002
```

拉取 goodsmileduck/redis-cli 镜像：  

```sh
docker pull goodsmileduck/redis-cli
```

集群配置（下面的 172.18.4.77 是本机的 IP 地址，可以使用 ifconfig 命令查看）：  

```sh
docker run --rm -it goodsmileduck/redis-cli redis-cli -a redis_cluster_pass --cluster-replicas 1 --cluster create 172.18.4.77:7001 172.18.4.77:7002 172.18.4.77:7003 172.18.4.77:7004 172.18.4.77:7005 172.18.4.77:7006
```

命令解释：  

- -a redis_cluster_pass 是 redis 的密码
- --cluster-replicas 1 表示有 1 个从节点  

执行结果如下：  

```sh
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 172.18.4.77:7005 to 172.18.4.77:7001
Adding replica 172.18.4.77:7006 to 172.18.4.77:7002
Adding replica 172.18.4.77:7004 to 172.18.4.77:7003
>>> Trying to optimize slaves allocation for anti-affinity
[WARNING] Some slaves are in the same host as their master
M: 3a33cc8ee81716da8e4a706c481f9f4e48d7fe00 172.18.4.77:7001
   slots:[0-5460] (5461 slots) master
M: f20bb8408e69bcab7a8834bd5688b8ce35478cb3 172.18.4.77:7002
   slots:[5461-10922] (5462 slots) master
M: 44e668e36edde1fea17df60194742c22c6cb4390 172.18.4.77:7003
   slots:[10923-16383] (5461 slots) master
S: fe64b3a2bacbf851c74cbddfbcbdbaebecbc1c69 172.18.4.77:7004
   replicates f20bb8408e69bcab7a8834bd5688b8ce35478cb3
S: 2f7bca7ae928985b30a1b0ccfdd2d62e52e27dba 172.18.4.77:7005
   replicates 44e668e36edde1fea17df60194742c22c6cb4390
S: 60779af1b1917a5bdbddba1fecf4a6a61fc97682 172.18.4.77:7006
   replicates 3a33cc8ee81716da8e4a706c481f9f4e48d7fe00
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
...
>>> Performing Cluster Check (using node 172.18.4.77:7001)
M: 3a33cc8ee81716da8e4a706c481f9f4e48d7fe00 172.18.4.77:7001
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: fe64b3a2bacbf851c74cbddfbcbdbaebecbc1c69 172.19.0.1:7004
   slots: (0 slots) slave
   replicates f20bb8408e69bcab7a8834bd5688b8ce35478cb3
M: f20bb8408e69bcab7a8834bd5688b8ce35478cb3 172.19.0.1:7002
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
S: 60779af1b1917a5bdbddba1fecf4a6a61fc97682 172.19.0.1:7006
   slots: (0 slots) slave
   replicates 3a33cc8ee81716da8e4a706c481f9f4e48d7fe00
M: 44e668e36edde1fea17df60194742c22c6cb4390 172.19.0.1:7003
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: 2f7bca7ae928985b30a1b0ccfdd2d62e52e27dba 172.19.0.1:7005
   slots: (0 slots) slave
   replicates 44e668e36edde1fea17df60194742c22c6cb4390
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

从结果可以看出分片规则、节点的主从关系，即 3 个 Master 节点（7001、7002、7003），3 个 Slave 节点（7004、7005、7006），3 个 Master 节点的分片是：7001：[0-5460] (5461 slots)、7002：[5461-10922] (5462 slots)、7003：[10923-16383] (5461 slots)。   

连接任意一个节点，查看集群节点（**cluster nodes**）：  

```sh
$ docker run --rm -it goodsmileduck/redis-cli redis-cli -c -h 172.18.4.77 -p 7001 -a redis_cluster_pass
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
172.18.4.77:7001> cluster nodes
fe64b3a2bacbf851c74cbddfbcbdbaebecbc1c69 172.19.0.1:7004@17004 slave f20bb8408e69bcab7a8834bd5688b8ce35478cb3 0 1611817666000 4 connected
f20bb8408e69bcab7a8834bd5688b8ce35478cb3 172.19.0.1:7002@17002 master - 0 1611817666821 2 connected 5461-10922
60779af1b1917a5bdbddba1fecf4a6a61fc97682 172.19.0.1:7006@17006 slave 3a33cc8ee81716da8e4a706c481f9f4e48d7fe00 0 1611817667856 6 connected
44e668e36edde1fea17df60194742c22c6cb4390 172.19.0.1:7003@17003 master - 0 1611817665000 3 connected 10923-16383
2f7bca7ae928985b30a1b0ccfdd2d62e52e27dba 172.19.0.1:7005@17005 slave 44e668e36edde1fea17df60194742c22c6cb4390 0 1611817668880 5 connected
3a33cc8ee81716da8e4a706c481f9f4e48d7fe00 172.19.0.5:7001@17001 myself,master - 0 1611817667000 1 connected 0-5460
```

测试集群存储：  

```sh
172.18.4.77:7001> set key1 val1
-> Redirected to slot [9189] located at 172.19.0.1:7002
OK
```

我们发现，操作 redis7001 存储一个 key，自动路由到了 7002，说明集群部署成功。  

查看集群信息（**cluster info**）：  

```sh
172.19.0.1:7002> cluster info
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:6
cluster_my_epoch:2
cluster_stats_messages_ping_sent:2076
cluster_stats_messages_pong_sent:2114
cluster_stats_messages_meet_sent:4
cluster_stats_messages_sent:4194
cluster_stats_messages_ping_received:2110
cluster_stats_messages_pong_received:2080
cluster_stats_messages_meet_received:4
cluster_stats_messages_received:4194
```

查看集群分片情况（**cluster slots**）：  

```sh
172.19.0.1:7002> cluster slots
1) 1) (integer) 10923
   2) (integer) 16383
   3) 1) "172.19.0.1"
      2) (integer) 7003
      3) "44e668e36edde1fea17df60194742c22c6cb4390"
   4) 1) "172.19.0.1"
      2) (integer) 7005
      3) "2f7bca7ae928985b30a1b0ccfdd2d62e52e27dba"
2) 1) (integer) 0
   2) (integer) 5460
   3) 1) "172.19.0.1"
      2) (integer) 7001
      3) "3a33cc8ee81716da8e4a706c481f9f4e48d7fe00"
   4) 1) "172.19.0.1"
      2) (integer) 7006
      3) "60779af1b1917a5bdbddba1fecf4a6a61fc97682"
3) 1) (integer) 5461
   2) (integer) 10922
   3) 1) "172.19.0.2"
      2) (integer) 7002
      3) "f20bb8408e69bcab7a8834bd5688b8ce35478cb3"
   4) 1) "172.19.0.1"
      2) (integer) 7004
      3) "fe64b3a2bacbf851c74cbddfbcbdbaebecbc1c69"
```













