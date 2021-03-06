# 搭建 Kafka 集群

1、容器编排。  

```sh
docker-compose up -d
```

2、查看容器信息。  

```sh
$ docker ps
CONTAINER ID   IMAGE                                  COMMAND                  CREATED          STATUS          PORTS                                        NAMES
632e7b922c8e   wurstmeister/kafka                     "start-kafka.sh"         43 seconds ago   Up 41 seconds   0.0.0.0:9093->9093/tcp                       kafka2
2f24af88d5b4   wurstmeister/kafka                     "start-kafka.sh"         43 seconds ago   Up 41 seconds   0.0.0.0:9094->9094/tcp                       kafka3
c1d3b33f5584   wurstmeister/kafka                     "start-kafka.sh"         43 seconds ago   Up 41 seconds   0.0.0.0:9092->9092/tcp                       kafka1
873c6bfadf68   daocloud.io/library/zookeeper:3.4.14   "/docker-entrypoint.…"   44 seconds ago   Up 42 seconds   2888/tcp, 3888/tcp, 0.0.0.0:2182->2181/tcp   zoo2
1b9d3a0cbfac   daocloud.io/library/zookeeper:3.4.14   "/docker-entrypoint.…"   44 seconds ago   Up 42 seconds   2888/tcp, 0.0.0.0:2181->2181/tcp, 3888/tcp   zoo1
d66c23d04114   daocloud.io/library/zookeeper:3.4.14   "/docker-entrypoint.…"   44 seconds ago   Up 42 seconds   2888/tcp, 3888/tcp, 0.0.0.0:2183->2181/tcp   zoo3
```

3、进入任意一个 Kafka 容器，创建 Topic。  

```sh
docker exec -it kafka1 bash
/opt/kafka_2.13-2.7.0/bin/kafka-topics.sh --create --topic test001 --partitions 5 --zookeeper zoo1:2181 --replication-factor 3
```

4、在 Kafka1 容器内部，启动生产者，生产一条消息。  

```sh
bash-4.4# /opt/kafka_2.13-2.7.0/bin/kafka-console-producer.sh --broker-list kafka1:9092 --topic test001
>hello 
```

5、进入任意 Kafka 容器内部，启动消费者，可以看到接收到了消息。  

```sh
docker exec -it kafka2 bash
bash-4.4# opt/kafka_2.13-2.7.0/bin/kafka-console-consumer.sh --bootstrap-server kafka2:9093 --topic test001 --from-beginning
hello
```

6、查看 Kafka Topic 列表，使用 `--list` 参数。  

> 可以使用任意 Kafka 节点、ZK 节点。  

```sh
bash-4.4# /opt/kafka_2.13-2.7.0/bin/kafka-topics.sh --list --zookeeper zoo1:2181
__consumer_offsets
test001
```

7、查看 Kafka 指定 Topic 详情，使用 `--topic` 与 `--describe` 参数。   

```sh
bash-4.4# /opt/kafka_2.13-2.7.0/bin/kafka-topics.sh --zookeeper zoo1:2181 --topic test001 --describe
Topic: test001	PartitionCount: 5	ReplicationFactor: 3	Configs:
	Topic: test001	Partition: 0	Leader: 1003	Replicas: 1003,1001,1002	Isr: 1003,1001,1002
	Topic: test001	Partition: 1	Leader: 1001	Replicas: 1001,1002,1003	Isr: 1001,1002,1003
	Topic: test001	Partition: 2	Leader: 1002	Replicas: 1002,1003,1001	Isr: 1002,1003,1001
	Topic: test001	Partition: 3	Leader: 1003	Replicas: 1003,1002,1001	Isr: 1003,1002,1001
	Topic: test001	Partition: 4	Leader: 1001	Replicas: 1001,1003,1002	Isr: 1001,1003,1002
```





