# JDK 8（Spark 3.3 支持 8/11；如需 11 将此行改为 eclipse-temurin:11-jdk）
FROM eclipse-temurin:8-jdk

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java/openjdk
WORKDIR /root

# 版本与路径
ENV SCALA_VERSION=2.12.18 \
    HADOOP_VERSION=3.3.4 \
    SPARK_VERSION=3.3.2 \
    HADOOP_HOME=/opt/hadoop \
    SPARK_HOME=/opt/spark

ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin:/opt/scala/bin

# 常用工具 + Maven + Python（按需增减）
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl ca-certificates vim less openssh-server \
    net-tools iputils-ping rsync procps \
    maven python3 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd

# ---------- 安装 Hadoop 3.3.x ----------
RUN wget -q https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
 && tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt \
 && mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
 && rm hadoop-${HADOOP_VERSION}.tar.gz

# Hadoop 配置（最小单机）
RUN mkdir -p /data/hdfs/namenode /data/hdfs/datanode \
 && sed -i "s|^# export JAVA_HOME.*|export JAVA_HOME=${JAVA_HOME}|g" ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh || \
    echo "export JAVA_HOME=${JAVA_HOME}" >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh

# core-site.xml
RUN bash -lc 'cat > $HADOOP_HOME/etc/hadoop/core-site.xml <<EOF
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
</configuration>
EOF'

# hdfs-site.xml（Hadoop 3.x 端口/路径）
RUN bash -lc 'cat > $HADOOP_HOME/etc/hadoop/hdfs-site.xml <<EOF
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:/data/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:/data/hdfs/datanode</value>
  </property>
</configuration>
EOF'

# mapred-site.xml
RUN cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $HADOOP_HOME/etc/hadoop/mapred-site.xml \
 && bash -lc 'cat > $HADOOP_HOME/etc/hadoop/mapred-site.xml <<EOF
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>
EOF'

# yarn-site.xml
RUN bash -lc 'cat > $HADOOP_HOME/etc/hadoop/yarn-site.xml <<EOF
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
</configuration>
EOF'

# ---------- 安装 Spark 3.3（预编译 Hadoop3 变体） ----------
RUN wget -q https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz \
 && tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz -C /opt \
 && mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} \
 && rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Spark 默认配置（本地模式，可按需改成 yarn）
RUN bash -lc 'mkdir -p $SPARK_HOME/conf && echo "spark.master local[*]" > $SPARK_HOME/conf/spark-defaults.conf'

# ---------- 安装 Scala 2.12.x ----------
RUN wget -q https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz \
 && tar -xzf scala-${SCALA_VERSION}.tgz -C /opt \
 && ln -s /opt/scala-${SCALA_VERSION} /opt/scala \
 && rm -f scala-${SCALA_VERSION}.tgz

# SSH 免密（可选）
RUN ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa \
 && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys \
 && printf "Host *\n  StrictHostKeyChecking no\n" > /root/.ssh/config

# 简单启动脚本（按需替换为你自己的 start-all.sh）
RUN bash -lc 'cat > /opt/start-all.sh <<EOF
#!/usr/bin/env bash
set -e
if [ ! -f /data/hdfs/namenode/current/VERSION ]; then
  \$HADOOP_HOME/bin/hdfs namenode -format -force
fi
\$HADOOP_HOME/sbin/start-dfs.sh
\$HADOOP_HOME/sbin/start-yarn.sh
echo "HDFS & YARN started."
echo "Spark available at: \$SPARK_HOME"
tail -f /dev/null
EOF' \
 && chmod +x /opt/start-all.sh

EXPOSE 4040 7077 8088 9000 9870 9864
# 4040 Spark UI, 7077 Spark master (standalone), 8088 YARN RM, 9000 HDFS, 9870 NN UI, 9864 DN UI

CMD ["/opt/start-all.sh"]