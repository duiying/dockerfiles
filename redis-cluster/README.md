# 搭建 redis-cluster 三主三从以及集群的扩容缩容

### 目录

- [创建三主三从集群](#创建三主三从集群)
- [手动指定主从](#手动指定主从)
- [集群的扩容](#集群的扩容)
- [集群的缩容](#集群的缩容)
- [集群操作总结](#集群操作总结)

### 创建三主三从集群

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

上面的六个节点中，7001、7006 为一组主从，7002、7004 为一组主从，7003、7005 为一组主从，这是自动生成的主从关系，**如果我们想手动指定节点的主从关系应该怎样做？**  

### 手动指定主从

我们先把**环境恢复**到刚执行完 docker-compose up -d 时的环境（1、删除 6 个目录下的 data 目录；2、docker-compose down；3、docker-compose up -d；）。  

**1、先创建不含 Slave 的集群**  

```sh
docker run --rm -it goodsmileduck/redis-cli redis-cli -a redis_cluster_pass --cluster-replicas 0 --cluster create 172.18.4.77:7001 172.18.4.77:7002 172.18.4.77:7003 
```  

执行结果如下：  

```sh
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
>>> Performing hash slots allocation on 3 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
M: 6153f122ee1d4bebbd1d2911a253f5fd14432b88 172.18.4.77:7001
   slots:[0-5460] (5461 slots) master
M: d511c1cf25e40d82db8b1ff303ab4691d96e8621 172.18.4.77:7002
   slots:[5461-10922] (5462 slots) master
M: 9c3ce34bdec25c6fbad23200fe013d531ef27e4c 172.18.4.77:7003
   slots:[10923-16383] (5461 slots) master
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
...
>>> Performing Cluster Check (using node 172.18.4.77:7001)
M: 6153f122ee1d4bebbd1d2911a253f5fd14432b88 172.18.4.77:7001
   slots:[0-5460] (5461 slots) master
M: 9c3ce34bdec25c6fbad23200fe013d531ef27e4c 172.21.0.1:7003
   slots:[10923-16383] (5461 slots) master
M: d511c1cf25e40d82db8b1ff303ab4691d96e8621 172.21.0.1:7002
   slots:[5461-10922] (5462 slots) master
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

**2、手动添加 Slave**  

```sh
# 设置 Slave 为 7004 节点，对应的 Master 为 7001 节点
docker run --rm -it goodsmileduck/redis-cli redis-cli -a redis_cluster_pass --cluster add-node 172.18.4.77:7004 172.18.4.77:7001 --cluster-slave --cluster-master-id 6153f122ee1d4bebbd1d2911a253f5fd14432b88
# 设置 Slave 为 7005 节点，对应的 Master 为 7002 节点
docker run --rm -it goodsmileduck/redis-cli redis-cli -a redis_cluster_pass --cluster add-node 172.18.4.77:7005 172.18.4.77:7002 --cluster-slave --cluster-master-id d511c1cf25e40d82db8b1ff303ab4691d96e8621
# 设置 Slave 为 7006 节点，对应的 Master 为 7003 节点
docker run --rm -it goodsmileduck/redis-cli redis-cli -a redis_cluster_pass --cluster add-node 172.18.4.77:7006 172.18.4.77:7003 --cluster-slave --cluster-master-id 9c3ce34bdec25c6fbad23200fe013d531ef27e4c
```

三条命令的执行结果如下：  

```sh
# 第一条命令执行结果
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
>>> Adding node 172.18.4.77:7004 to cluster 172.18.4.77:7001
>>> Performing Cluster Check (using node 172.18.4.77:7001)
M: 6153f122ee1d4bebbd1d2911a253f5fd14432b88 172.18.4.77:7001
   slots:[0-5460] (5461 slots) master
M: 9c3ce34bdec25c6fbad23200fe013d531ef27e4c 172.21.0.1:7003
   slots:[10923-16383] (5461 slots) master
M: d511c1cf25e40d82db8b1ff303ab4691d96e8621 172.21.0.1:7002
   slots:[5461-10922] (5462 slots) master
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
>>> Send CLUSTER MEET to node 172.18.4.77:7004 to make it join the cluster.
Waiting for the cluster to join

>>> Configure node as replica of 172.18.4.77:7001.
[OK] New node added correctly.

# 第二条命令执行结果
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
>>> Adding node 172.18.4.77:7005 to cluster 172.18.4.77:7002
>>> Performing Cluster Check (using node 172.18.4.77:7002)
M: d511c1cf25e40d82db8b1ff303ab4691d96e8621 172.18.4.77:7002
   slots:[5461-10922] (5462 slots) master
S: 8c29b33eacf918fb3227734884962c78d21cbc9c 172.21.0.1:7004
   slots: (0 slots) slave
   replicates 6153f122ee1d4bebbd1d2911a253f5fd14432b88
M: 9c3ce34bdec25c6fbad23200fe013d531ef27e4c 172.21.0.1:7003
   slots:[10923-16383] (5461 slots) master
M: 6153f122ee1d4bebbd1d2911a253f5fd14432b88 172.21.0.1:7001
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
>>> Send CLUSTER MEET to node 172.18.4.77:7005 to make it join the cluster.
Waiting for the cluster to join

>>> Configure node as replica of 172.18.4.77:7002.
[OK] New node added correctly.

# 第三条命令执行结果
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
>>> Adding node 172.18.4.77:7006 to cluster 172.18.4.77:7003
>>> Performing Cluster Check (using node 172.18.4.77:7003)
M: 9c3ce34bdec25c6fbad23200fe013d531ef27e4c 172.18.4.77:7003
   slots:[10923-16383] (5461 slots) master
S: 2366c99562a1eb9503657e17f15acf65a1b7967d 172.21.0.1:7005
   slots: (0 slots) slave
   replicates d511c1cf25e40d82db8b1ff303ab4691d96e8621
M: 6153f122ee1d4bebbd1d2911a253f5fd14432b88 172.21.0.1:7001
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
M: d511c1cf25e40d82db8b1ff303ab4691d96e8621 172.21.0.1:7002
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
S: 8c29b33eacf918fb3227734884962c78d21cbc9c 172.21.0.1:7004
   slots: (0 slots) slave
   replicates 6153f122ee1d4bebbd1d2911a253f5fd14432b88
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
>>> Send CLUSTER MEET to node 172.18.4.77:7006 to make it join the cluster.
Waiting for the cluster to join

>>> Configure node as replica of 172.18.4.77:7003.
[OK] New node added correctly.
```

**3、查看集群分片情况（cluster slots）**  

```sh
$ docker run --rm -it goodsmileduck/redis-cli redis-cli -c -h 172.18.4.77 -p 7001 -a redis_cluster_pass
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
172.18.4.77:7001> cluster slots
1) 1) (integer) 0
   2) (integer) 5460
   3) 1) "172.21.0.4"
      2) (integer) 7001
      3) "6153f122ee1d4bebbd1d2911a253f5fd14432b88"
   4) 1) "172.21.0.1"
      2) (integer) 7004
      3) "8c29b33eacf918fb3227734884962c78d21cbc9c"
2) 1) (integer) 10923
   2) (integer) 16383
   3) 1) "172.21.0.1"
      2) (integer) 7003
      3) "9c3ce34bdec25c6fbad23200fe013d531ef27e4c"
   4) 1) "172.21.0.1"
      2) (integer) 7006
      3) "1403bce5e9fac62d3dd144de664af0aea97ef4b5"
3) 1) (integer) 5461
   2) (integer) 10922
   3) 1) "172.21.0.1"
      2) (integer) 7002
      3) "d511c1cf25e40d82db8b1ff303ab4691d96e8621"
   4) 1) "172.21.0.1"
      2) (integer) 7005
      3) "2366c99562a1eb9503657e17f15acf65a1b7967d"
172.18.4.77:7001> set key1 val1
-> Redirected to slot [9189] located at 172.21.0.1:7002
OK
```

可以看到，我们成功地手动设置了节点之间的主从关系。  

### 集群的扩容

首先，新增两个节点 7007 和 7008。  

```sh
docker-compose -f docker-compose-expand.yml up -d
```

**1、添加主节点（7007）到集群中**  

- 172.21.0.1:7007 是新节点的 IP 和端口
- 172.21.0.1:7001 是集群中任意节点的 IP 和端口

```sh
docker run --rm -it goodsmileduck/redis-cli redis-cli --cluster add-node 172.21.0.1:7007 172.21.0.1:7001 -a redis_cluster_pass
```

查看集群中的节点信息，发现已经多了 7007 节点，但是该节点没有包含任何 slot。  

```sh
172.18.4.77:7001> cluster nodes
1403bce5e9fac62d3dd144de664af0aea97ef4b5 172.21.0.1:7006@17006 slave 9c3ce34bdec25c6fbad23200fe013d531ef27e4c 0 1611827087000 3 connected
6153f122ee1d4bebbd1d2911a253f5fd14432b88 172.21.0.4:7001@17001 myself,master - 0 1611827085000 1 connected 0-5460
4c32c47bd248f86415a86512186a3261be78bb3a 172.21.0.1:7007@17007 master - 0 1611827088276 0 connected
8c29b33eacf918fb3227734884962c78d21cbc9c 172.21.0.1:7004@17004 slave 6153f122ee1d4bebbd1d2911a253f5fd14432b88 0 1611827086238 1 connected
2366c99562a1eb9503657e17f15acf65a1b7967d 172.21.0.1:7005@17005 slave d511c1cf25e40d82db8b1ff303ab4691d96e8621 0 1611827083000 2 connected
9c3ce34bdec25c6fbad23200fe013d531ef27e4c 172.21.0.1:7003@17003 master - 0 1611827087258 3 connected 10923-16383
d511c1cf25e40d82db8b1ff303ab4691d96e8621 172.21.0.1:7002@17002 master - 0 1611827086000 2 connected 5461-10922
```

**2、分配槽**  

从集群中节点信息中可以看出，我们已经成功地往集群中添加了一个主节点，但是这个主节点还没有成为真正的主节点，因为这个节点还没有分配 slot，现在要给这个节点分配 slot。 

```sh
$ docker run --rm -it goodsmileduck/redis-cli redis-cli --cluster reshard 172.21.0.1:7007 -a redis_cluster_pass
# 分配 4096 个哈希槽给新节点
How many slots do you want to move (from 1 to 16384)? 4096
# 输入新节点的 id
What is the receiving node ID? 4c32c47bd248f86415a86512186a3261be78bb3a
Please enter all the source node IDs.
  Type 'all' to use all the nodes as source nodes for the hash slots.
  Type 'done' once you entered all the source nodes IDs.
# 从哪几个节点中移动槽，all 表示从所有的主节点中随机转移，给新节点凑给 4096 个槽
Source node #1:all
Do you want to proceed with the proposed reshard plan (yes/no)? yes
```

执行需要一定的时间，完成后，查看集群节点信息：  

```sh
172.21.0.1:7002> cluster nodes
8c29b33eacf918fb3227734884962c78d21cbc9c 172.21.0.1:7004@17004 slave 6153f122ee1d4bebbd1d2911a253f5fd14432b88 0 1611828194634 1 connected
2366c99562a1eb9503657e17f15acf65a1b7967d 172.21.0.1:7005@17005 slave d511c1cf25e40d82db8b1ff303ab4691d96e8621 0 1611828193000 2 connected
6153f122ee1d4bebbd1d2911a253f5fd14432b88 172.21.0.1:7001@17001 master - 0 1611828192000 1 connected 1365-5460
9c3ce34bdec25c6fbad23200fe013d531ef27e4c 172.21.0.1:7003@17003 master - 0 1611828193000 3 connected 12288-16383
4c32c47bd248f86415a86512186a3261be78bb3a 172.21.0.1:7007@17007 master - 0 1611828192000 4 connected 0-1364 5461-6826 10923-12287
1403bce5e9fac62d3dd144de664af0aea97ef4b5 172.21.0.1:7006@17006 slave 9c3ce34bdec25c6fbad23200fe013d531ef27e4c 0 1611828193620 3 connected
d511c1cf25e40d82db8b1ff303ab4691d96e8621 172.21.0.6:7002@17002 myself,master - 0 1611828192000 2 connected 6827-10922
```

可见，0-1364 5461-6826 10923-12287 的槽被分配给了新增加的节点 7007，三个加起来刚好 4096 个槽（slot）。  

**3、添加从节点（7008）**  

- 172.21.0.1:7008 是新节点的 IP 和端口
- 172.21.0.1:7001 是集群中任意节点的 IP 和端口
- 4c32c47bd248f86415a86512186a3261be78bb3a 是主节点 7007 的 id

```sh
docker run --rm -it goodsmileduck/redis-cli redis-cli --cluster add-node 172.21.0.1:7008 172.21.0.1:7001 --cluster-slave --cluster-master-id 4c32c47bd248f86415a86512186a3261be78bb3a -a redis_cluster_pass
```

查看集群节点信息：  

```sh
172.21.0.1:7002> cluster nodes
9150a5823280c13353ba6ec0c98806571c0a4c56 172.21.0.1:7008@17008 slave 4c32c47bd248f86415a86512186a3261be78bb3a 0 1611828550511 4 connected
8c29b33eacf918fb3227734884962c78d21cbc9c 172.21.0.1:7004@17004 slave 6153f122ee1d4bebbd1d2911a253f5fd14432b88 0 1611828548000 1 connected
2366c99562a1eb9503657e17f15acf65a1b7967d 172.21.0.1:7005@17005 slave d511c1cf25e40d82db8b1ff303ab4691d96e8621 0 1611828551539 2 connected
6153f122ee1d4bebbd1d2911a253f5fd14432b88 172.21.0.1:7001@17001 master - 0 1611828550000 1 connected 1365-5460
9c3ce34bdec25c6fbad23200fe013d531ef27e4c 172.21.0.1:7003@17003 master - 0 1611828549000 3 connected 12288-16383
4c32c47bd248f86415a86512186a3261be78bb3a 172.21.0.1:7007@17007 master - 0 1611828547445 4 connected 0-1364 5461-6826 10923-12287
1403bce5e9fac62d3dd144de664af0aea97ef4b5 172.21.0.1:7006@17006 slave 9c3ce34bdec25c6fbad23200fe013d531ef27e4c 0 1611828550000 3 connected
d511c1cf25e40d82db8b1ff303ab4691d96e8621 172.21.0.6:7002@17002 myself,master - 0 1611828545000 2 connected 6827-10922
```

### 集群的缩容

删除一个 Master 节点之前，应该先删除 Slave 节点，同时要使用 reshard 命令迁移该 Master 节点的所有 slot，然后再删除该 Master 节点。  

**1、删除 Slave 节点（7008）**  

删除节点使用的是 del-node 命令，此命令需要指定节点的 IP 和端口，以及该节点的 id。  

```sh
docker run --rm -it goodsmileduck/redis-cli redis-cli --cluster del-node 172.21.0.1:7008 9150a5823280c13353ba6ec0c98806571c0a4c56 -a redis_cluster_pass
```

**2、迁移 Master 节点（7007）的 slot**  

```sh
# 7007 节点的 1365 个 slot 迁移到 7001 上
docker run --rm -it goodsmileduck/redis-cli redis-cli --cluster reshard 172.21.0.1:7007 --cluster-from 4c32c47bd248f86415a86512186a3261be78bb3a --cluster-to 6153f122ee1d4bebbd1d2911a253f5fd14432b88 --cluster-slots 1365 -a redis_cluster_pass
# 7007 节点的 1366 个 slot 迁移到 7002 上
docker run --rm -it goodsmileduck/redis-cli redis-cli --cluster reshard 172.21.0.1:7007 --cluster-from 4c32c47bd248f86415a86512186a3261be78bb3a --cluster-to d511c1cf25e40d82db8b1ff303ab4691d96e8621 --cluster-slots 1366 -a redis_cluster_pass
# 7007 节点的 1365 个 slot 迁移到 7003 上
docker run --rm -it goodsmileduck/redis-cli redis-cli --cluster reshard 172.21.0.1:7007 --cluster-from 4c32c47bd248f86415a86512186a3261be78bb3a --cluster-to 9c3ce34bdec25c6fbad23200fe013d531ef27e4c --cluster-slots 1365 -a redis_cluster_pass
```

迁移完 4096 个 slot 之后，7007 节点中没有 slot 了。  

```sh
172.21.0.1:7002> cluster nodes
8c29b33eacf918fb3227734884962c78d21cbc9c 172.21.0.1:7004@17004 slave 6153f122ee1d4bebbd1d2911a253f5fd14432b88 0 1611831050870 5 connected
2366c99562a1eb9503657e17f15acf65a1b7967d 172.21.0.1:7005@17005 slave d511c1cf25e40d82db8b1ff303ab4691d96e8621 0 1611831053932 6 connected
6153f122ee1d4bebbd1d2911a253f5fd14432b88 172.21.0.1:7001@17001 master - 0 1611831051000 5 connected 0-5460
9c3ce34bdec25c6fbad23200fe013d531ef27e4c 172.21.0.1:7003@17003 master - 0 1611831049000 7 connected 10923-16383
4c32c47bd248f86415a86512186a3261be78bb3a 172.21.0.1:7007@17007 master - 0 1611831052000 4 connected
1403bce5e9fac62d3dd144de664af0aea97ef4b5 172.21.0.1:7006@17006 slave 9c3ce34bdec25c6fbad23200fe013d531ef27e4c 0 1611831052914 7 connected
d511c1cf25e40d82db8b1ff303ab4691d96e8621 172.21.0.6:7002@17002 myself,master - 0 1611831050000 6 connected 5461-10922
```

**3、删除空的 Master 节点（7007）**  

```sh
docker run --rm -it goodsmileduck/redis-cli redis-cli --cluster del-node 172.21.0.1:7007 4c32c47bd248f86415a86512186a3261be78bb3a -a redis_cluster_pass
```

查看集群节点信息：  

```sh
172.21.0.1:7002> cluster nodes
8c29b33eacf918fb3227734884962c78d21cbc9c 172.21.0.1:7004@17004 slave 6153f122ee1d4bebbd1d2911a253f5fd14432b88 0 1611831155925 5 connected
2366c99562a1eb9503657e17f15acf65a1b7967d 172.21.0.1:7005@17005 slave d511c1cf25e40d82db8b1ff303ab4691d96e8621 0 1611831156000 6 connected
6153f122ee1d4bebbd1d2911a253f5fd14432b88 172.21.0.1:7001@17001 master - 0 1611831157000 5 connected 0-5460
9c3ce34bdec25c6fbad23200fe013d531ef27e4c 172.21.0.1:7003@17003 master - 0 1611831155000 7 connected 10923-16383
1403bce5e9fac62d3dd144de664af0aea97ef4b5 172.21.0.1:7006@17006 slave 9c3ce34bdec25c6fbad23200fe013d531ef27e4c 0 1611831157966 7 connected
d511c1cf25e40d82db8b1ff303ab4691d96e8621 172.21.0.6:7002@17002 myself,master - 0 1611831154000 6 connected 5461-10922
```

### 集群操作总结

```sh
# 查看集群节点信息
cluster nodes
# 查看集群分片情况
cluster slots
# 查看集群信息
cluster info
# 添加节点
redis-cli --cluster add-node 172.21.0.1:7007 172.21.0.1:7001 -a redis_cluster_pass
# 删除节点
redis-cli --cluster del-node 172.21.0.1:7007 4c32c47bd248f86415a86512186a3261be78bb3a -a redis_cluster_pass
# 新节点分配槽
redis-cli --cluster reshard 172.21.0.1:7007 -a redis_cluster_pass
# 迁移槽到别的节点中
redis-cli --cluster reshard 172.21.0.1:7007 --cluster-from 4c32c47bd248f86415a86512186a3261be78bb3a --cluster-to 6153f122ee1d4bebbd1d2911a253f5fd14432b88 --cluster-slots 1365 -a redis_cluster_pass
```  


















