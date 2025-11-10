# 仍基于你现有镜像：Hadoop 3.3.x + Java 8 + Spark 3.3
FROM jdk8-hadoop3.3-spark3.3

SHELL ["/bin/bash", "-lc"]
ENV DEBIAN_FRONTEND=noninteractive

# -------------------------------------------------------------------
# 0) 基础工具链
# -------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl wget ca-certificates tar bash procps \
      git vim less sudo \
      maven python3 \
      make build-essential pkg-config \
      zlib1g-dev libbz2-dev liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------------------
# 1) 安装 Java 17（供 Spark 4 使用），并确保 Java 8 路径固定存在（供 Hadoop/YARN 使用）
# -------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA8_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV JAVA17_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# 如果基础镜像 Java8 目录名不同，则补软链或安装 openjdk-8
RUN mkdir -p /usr/lib/jvm && \
    if [ ! -d "${JAVA8_HOME}" ]; then \
      if [ -d /usr/lib/jvm/java-1.8.0-openjdk-amd64 ]; then \
        ln -s /usr/lib/jvm/java-1.8.0-openjdk-amd64 "${JAVA8_HOME}"; \
      else \
        apt-get update && apt-get install -y --no-install-recommends openjdk-8-jdk && \
        rm -rf /var/lib/apt/lists/*; \
      fi; \
    fi

# 默认仍用 Java 8（Hadoop/YARN）
ENV JAVA_HOME=${JAVA8_HOME}
ENV PATH="$JAVA_HOME/bin:$PATH"

# -------------------------------------------------------------------
# 2) 安装 Scala 2.13.14
# -------------------------------------------------------------------
ARG SCALA_VERSION=2.13.14
RUN wget -q https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz \
 && tar -xzf scala-${SCALA_VERSION}.tgz -C /opt \
 && ln -s /opt/scala-${SCALA_VERSION} /opt/scala \
 && ln -sf /opt/scala/bin/scala /usr/local/bin/scala \
 && ln -sf /opt/scala/bin/scalac /usr/local/bin/scalac \
 && ln -sf /opt/scala/bin/scaladoc /usr/local/bin/scaladoc \
 && rm -f scala-${SCALA_VERSION}.tgz
ENV SCALA_HOME=/opt/scala
ENV PATH="${SCALA_HOME}/bin:${PATH}"

# -------------------------------------------------------------------
# 3) 安装 Spark 4.0.1（Hadoop3 预编译包），替换旧的 Spark 3.x
#    - 带多镜像回退，避免主站轮换导致 404
# -------------------------------------------------------------------
ARG SPARK_VERSION=4.0.1
RUN set -euo pipefail; \
    if [ -d /opt/spark ]; then rm -rf /opt/spark; fi; \
    TMPDIR=$(mktemp -d) && cd "$TMPDIR"; \
    URLS=( \
      "https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" \
      "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" \
      "https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" \
    ); \
    for u in "${URLS[@]}"; do \
      echo "Trying $u"; \
      if curl -fL --connect-timeout 15 --retry 5 --retry-delay 2 -o spark.tgz "$u"; then break; fi; \
      rm -f spark.tgz; \
    done; \
    [ -s spark.tgz ] || { echo "Failed to download Spark ${SPARK_VERSION}"; exit 1; }; \
    tar -xzf spark.tgz -C /opt; \
    ln -s /opt/spark-${SPARK_VERSION}-bin-hadoop3 /opt/spark; \
    rm -rf "$TMPDIR"
ENV SPARK_HOME=/opt/spark
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"

# -------------------------------------------------------------------
# 4) 写入 Spark 配置（改用 echo/printf，避免 Docker 解析器把行首误判成指令）
#    - YARN 模式：AM/Executor 用 Java 17
#    - 本地/Client 模式：Driver 用 Java 17
# -------------------------------------------------------------------
RUN set -e; \
    mkdir -p "$SPARK_HOME/conf"; \
    echo "spark.yarn.appMasterEnv.JAVA_HOME=${JAVA17_HOME}" > "$SPARK_HOME/conf/spark-defaults.conf"; \
    echo "spark.executorEnv.JAVA_HOME=${JAVA17_HOME}" >> "$SPARK_HOME/conf/spark-defaults.conf"; \
    printf '%s\n' '#!/usr/bin/env bash' "export JAVA_HOME=${JAVA17_HOME}" > "$SPARK_HOME/conf/spark-env.sh"; \
    chmod +x "$SPARK_HOME/conf/spark-env.sh"

# -------------------------------------------------------------------
# 5) 补齐 Hadoop 的 log4j.properties（避免 HADOOP_CONF_DIR incomplete 的 WARNING）
# -------------------------------------------------------------------
RUN set -euo pipefail; \
    LOG4J_CONTENT=$'log4j.rootLogger=INFO, console\nlog4j.appender.console=org.apache.log4j.ConsoleAppender\nlog4j.appender.console.target=System.err\nlog4j.appender.console.layout=org.apache.log4j.PatternLayout\nlog4j.appender.console.layout.ConversionPattern=%d{ISO8601} %-5p %c: %m%n\n'; \
    for d in \
      "${HADOOP_HOME:-/opt/hadoop}/etc/hadoop" \
      "/usr/local/hadoop/etc/hadoop" \
      "/etc/hadoop/conf" \
    ; do \
      if [ -d "$d" ]; then \
        echo "Writing log4j.properties to $d"; \
        printf "%s" "$LOG4J_CONTENT" > "$d/log4j.properties"; \
      fi; \
    done || true

# 可选标签
LABEL maintainer="you" \
      spark.version="${SPARK_VERSION}" \
      java8.home="${JAVA8_HOME}" \
      java17.home="${JAVA17_HOME}" \
      scala.version="${SCALA_VERSION}"

# 保留基础镜像的 ENTRYPOINT/CMD（不改）