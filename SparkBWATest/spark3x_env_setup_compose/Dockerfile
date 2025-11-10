# 使用 BuildKit 扩展（支持缓存 mount 等）
# syntax=docker/dockerfile:1.6

FROM eclipse-temurin:8-jdk-jammy

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java/openjdk
WORKDIR /root

# Versions / Paths
ENV SCALA_VERSION=2.12.18 \
    HADOOP_VERSION=3.3.5 \
    SPARK_VERSION=3.3.2 \
    HADOOP_HOME=/opt/hadoop \
    SPARK_HOME=/opt/spark \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    YARN_CONF_DIR=/opt/hadoop/etc/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin:/opt/scala/bin

# 可覆写的下载源（默认用 Apache CDN，比 archive 快）
ARG HADOOP_URL=https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
# ARG SPARK_URL=https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz
# 如果 CDN 访问慢，你也可以在构建时 --build-arg 改成：
# HADOOP_URL=https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
ARG SPARK_URL=https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Tools（用 BuildKit cache 加速 apt）
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update \
 && apt-get install -y --no-install-recommends \
    curl wget ca-certificates vim less openssh-server \
    net-tools iputils-ping rsync procps maven python3 \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /var/run/sshd

# ---- Hadoop（带重试/超时/断点续传/进度）----
RUN set -eux; \
    echo "==> Downloading Hadoop from: ${HADOOP_URL}"; \
    curl -fL --retry 5 --retry-delay 2 --retry-connrefused \
         --connect-timeout 30 --max-time 0 \
         -o "hadoop-${HADOOP_VERSION}.tar.gz" \
         "${HADOOP_URL}"; \
    echo "==> Extracting..."; \
    tar -xzf "hadoop-${HADOOP_VERSION}.tar.gz" -C /opt; \
    mv "/opt/hadoop-${HADOOP_VERSION}" "${HADOOP_HOME}"; \
    rm "hadoop-${HADOOP_VERSION}.tar.gz"; \
    mkdir -p /data/hdfs/namenode /data/hdfs/datanode; \
    (grep -qE '^[[:space:]]*export JAVA_HOME=' "$HADOOP_HOME/etc/hadoop/hadoop-env.sh" \
      && sed -i "s|^[[:space:]]*export JAVA_HOME=.*|export JAVA_HOME=${JAVA_HOME}|g" "$HADOOP_HOME/etc/hadoop/hadoop-env.sh" \
      || echo "export JAVA_HOME=${JAVA_HOME}" >> "$HADOOP_HOME/etc/hadoop/hadoop-env.sh")

# ---- Spark（带重试/进度，URL 可覆写）----
RUN set -eux; \
    echo "==> Downloading Spark from: ${SPARK_URL}"; \
    curl -fL --retry 5 --retry-delay 2 --retry-connrefused \
         --connect-timeout 30 --max-time 0 \
         -o "spark-${SPARK_VERSION}-bin-hadoop3.tgz" \
         "${SPARK_URL}"; \
    tar -xzf "spark-${SPARK_VERSION}-bin-hadoop3.tgz" -C /opt; \
    mv "/opt/spark-${SPARK_VERSION}-bin-hadoop3" "${SPARK_HOME}"; \
    rm "spark-${SPARK_VERSION}-bin-hadoop3.tgz"; \
    mkdir -p /tmp/spark-events; \
    echo -e "spark.eventLog.enabled true\nspark.eventLog.dir file:///tmp/spark-events\nspark.master local[*]" >> "$SPARK_HOME/conf/spark-defaults.conf"

# ---- Scala（显示进度）----
RUN wget --progress=dot:giga "https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" \
 && tar -xzf "scala-${SCALA_VERSION}.tgz" -C /opt \
 && ln -s "/opt/scala-${SCALA_VERSION}" /opt/scala \
 && rm -f "scala-${SCALA_VERSION}.tgz"

# No default CMD — compose 的各服务用 command 指定前台进程