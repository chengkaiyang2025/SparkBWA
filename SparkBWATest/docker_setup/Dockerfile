# JDK 8 + Scala 2.11 + Hadoop 2.7.7 + Spark 2.4.8 + Maven
FROM openjdk:8-jdk

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/local/openjdk-8

# Versions
ENV SCALA_VERSION=2.11.12 \
    HADOOP_VERSION=2.7.7 \
    SPARK_VERSION=2.4.8 \
    HADOOP_HOME=/opt/hadoop \
    SPARK_HOME=/opt/spark \
    MAVEN_OPTS="-Xms256m -Xmx1024m"
# export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
# export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
# export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin

ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin
# 编译所需工具与头文件
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential make zlib1g-dev libbz2-dev liblzma-dev \
 && rm -rf /var/lib/apt/lists/*
 
# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl ssh pdsh rsync net-tools iputils-ping procps vim less ca-certificates \
    openssh-server maven python3 \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /var/run/sshd

# Hadoop
RUN wget -q https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
 && tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt \
 && mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
 && rm hadoop-${HADOOP_VERSION}.tar.gz

# Spark prebuilt for Hadoop 2.7 (Scala 2.11)
# Note: Spark 2.4.8 default build is Scala 2.11 and the -bin-hadoop2.7 package matches Hadoop 2.7.x
RUN wget -q https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz \
 && tar -xzf spark-${SPARK_VERSION}-bin-hadoop2.7.tgz -C /opt \
 && mv /opt/spark-${SPARK_VERSION}-bin-hadoop2.7 ${SPARK_HOME} \
 && rm spark-${SPARK_VERSION}-bin-hadoop2.7.tgz

# Scala (needed for building/running some Scala apps)
RUN wget -q https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz \
 && tar -xzf scala-${SCALA_VERSION}.tgz -C /opt \
 && ln -s /opt/scala-${SCALA_VERSION}/bin/scala /usr/local/bin/scala \
 && ln -s /opt/scala-${SCALA_VERSION}/bin/scalac /usr/local/bin/scalac \
 && ln -s /opt/scala-${SCALA_VERSION}/bin/sbt /usr/local/bin/sbt || true \
 && rm scala-${SCALA_VERSION}.tgz

# Hadoop minimal single-node config
# Hadoop minimal single-node config
RUN mkdir -p /data/hdfs/namenode /data/hdfs/datanode && \
    # 设置 JAVA_HOME（有些发行包里是注释行，这里兜底追加）
    (grep -qE '^\s*export JAVA_HOME=' $HADOOP_HOME/etc/hadoop/hadoop-env.sh \
      && sed -i 's|^\s*export JAVA_HOME=.*|export JAVA_HOME=/usr/local/openjdk-8|g' $HADOOP_HOME/etc/hadoop/hadoop-env.sh \
      || echo 'export JAVA_HOME=/usr/local/openjdk-8' >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh)

RUN cat > $HADOOP_HOME/etc/hadoop/core-site.xml <<'EOF'
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
</configuration>
EOF

RUN cat > $HADOOP_HOME/etc/hadoop/hdfs-site.xml <<'EOF'
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
EOF

RUN cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $HADOOP_HOME/etc/hadoop/mapred-site.xml && \
    cat > $HADOOP_HOME/etc/hadoop/mapred-site.xml <<'EOF'
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>
EOF

RUN cat > $HADOOP_HOME/etc/hadoop/yarn-site.xml <<'EOF'
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
</configuration>
EOF

# Spark defaults (run on YARN by default optional)
RUN bash -lc 'mkdir -p $SPARK_HOME/conf && echo "spark.master local[*]" > $SPARK_HOME/conf/spark-defaults.conf'

# SSH no-password localhost
RUN ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa \
 && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys \
 && printf "Host *\n  StrictHostKeyChecking no\n" > /root/.ssh/config

# Convenience start script
COPY start-all.sh /opt/start-all.sh
RUN chmod +x /opt/start-all.sh

EXPOSE 8080 7077 4040 18080 50070 8088 9000
WORKDIR /root

CMD ["/opt/start-all.sh"]
