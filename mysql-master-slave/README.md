# 搭建 MySQL 一主一从

启动两个 MySQL 容器：  

```sh
docker-compose up -d
```

查看容器：  

```sh
$ docker ps
CONTAINER ID        IMAGE                             COMMAND                  CREATED             STATUS              PORTS                     NAMES
2ced99ebb94d        daocloud.io/library/mysql:5.7.4   "/entrypoint.sh mysq…"   4 seconds ago       Up 2 seconds        0.0.0.0:33061->3306/tcp   mysql-master
ab519e1ebb7f        daocloud.io/library/mysql:5.7.4   "/entrypoint.sh mysq…"   4 seconds ago       Up 3 seconds        0.0.0.0:33062->3306/tcp   mysql-slave
```

配置 Master：  

```sh
# 进入 Master 容器
$ docker exec -it mysql-master bash
# 连接 MySQL
root@38f1b57d8fc7:/usr/local/mysql# mysql -uroot -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.4-m14-log MySQL Community Server (GPL)

Copyright (c) 2000, 2014, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
# 创建同步用户
mysql> create user repl;
Query OK, 0 rows affected (0.00 sec)
# 设置同步用户权限
mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%' IDENTIFIED BY 'replpass';
Query OK, 0 rows affected (0.00 sec)
# 显示 Master 状态，重点关注 File 和 Position
mysql> show master status;
+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000003 |     1175 |              | mysql            |                   |
+------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)
```

配置 Slave：  

```sh
# 进入 Slave 容器
$ docker exec -it mysql-slave bash 
root@440ddc710e59:/usr/local/mysql# mysql -uroot -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.4-m14 MySQL Community Server (GPL)

Copyright (c) 2000, 2014, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
# 配置连接 Master 的参数，记得修改 MASTER_LOG_FILE、MASTER_LOG_POS 的值
mysql> CHANGE MASTER TO MASTER_HOST='mysql-master',MASTER_USER='repl',MASTER_PASSWORD='replpass',MASTER_LOG_FILE='mysql-bin.000003',MASTER_LOG_POS=1175;
Query OK, 0 rows affected, 2 warnings (0.05 sec)
# 启动 Slave 服务
mysql> start slave;
Query OK, 0 rows affected (0.00 sec)
# 显示 Slave 状态，当 Slave_IO_Running、Slave_SQL_Running 为 Yes 时说明同步服务正常
mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: mysql-master
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000003
          Read_Master_Log_Pos: 1175
               Relay_Log_File: 440ddc710e59-relay-bin.000002
                Relay_Log_Pos: 283
        Relay_Master_Log_File: mysql-bin.000003
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 1175
              Relay_Log_Space: 463
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: 07766f05-4efa-11eb-b084-0242ac130003
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
1 row in set (0.00 sec)
```

验证主从复制：  

```sh
# Master 创建一个 test 库
$ docker exec -it mysql-master bash
root@38f1b57d8fc7:/usr/local/mysql# mysql -uroot -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 4
Server version: 5.7.4-m14-log MySQL Community Server (GPL)

Copyright (c) 2000, 2014, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> create database test;
Query OK, 1 row affected (0.01 sec)

# 查看 Slave 是否同步
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| test               |
+--------------------+
4 rows in set (0.02 sec)
```

至此，MySQL 主从复制环境已搭建完成。  

测试数据的同步：  

```sh
# Master
mysql> use test;
Database changed
mysql> CREATE TABLE `t_passport_role` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL DEFAULT '',
  `admin` tinyint(4) NOT NULL DEFAULT '0',
  `status` tinyint(4) NOT NULL DEFAULT '1',
  `sort` int(10) NOT NULL DEFAULT '99',
  `mtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `ctime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
mysql> INSERT INTO `t_passport_role` VALUES (1, 'root', 1, 1, 1, '2020-09-04 14:26:32', '2020-09-02 19:45:21');
Query OK, 1 row affected (0.00 sec)

# Slave
mysql> use test;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> select * from t_passport_role;
+----+------+-------+--------+------+---------------------+---------------------+
| id | name | admin | status | sort | mtime               | ctime               |
+----+------+-------+--------+------+---------------------+---------------------+
|  1 | root |     1 |      1 |    1 | 2020-09-04 14:26:32 | 2020-09-02 19:45:21 |
+----+------+-------+--------+------+---------------------+---------------------+
1 row in set (0.00 sec)
```

同步状态关键指标：  

**当前同步文件**  

- Master：File（mysql-bin.000003）
- Slave：Master_Log_File（mysql-bin.000003）  

**当前同步 pos 点位**  

- Master：Position（1175）
- Slave：Read_Master_Log_Pos（1175） 

**Seconds_Behind_Master**：值为 0 表示健康，值长时间非 0 则同步存在压力或网络存在延迟。














