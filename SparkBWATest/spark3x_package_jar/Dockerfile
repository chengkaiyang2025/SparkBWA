FROM eclipse-temurin:8-jdk

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java/openjdk
WORKDIR /workspace

# 基础工具 + Maven + JNI/C++ 构建链
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget ca-certificates tar sudo vim less \
    maven python3 \
    build-essential gcc g++ make cmake pkg-config \
    zlib1g-dev libbz2-dev liblzma-dev \
 && rm -rf /var/lib/apt/lists/*

# 选择 Scala 版本：
# - Spark 3.2/3.3 → Scala 2.12.x（默认）
# - Spark 3.4/3.5 → Scala 2.12.x 或 2.13.x（任选其一）
ARG SCALA_VERSION=2.12.18
RUN wget -q https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz \
 && tar -xzf scala-${SCALA_VERSION}.tgz -C /opt \
 && ln -s /opt/scala-${SCALA_VERSION} /opt/scala \
 && ln -s /opt/scala/bin/scala /usr/local/bin/scala \
 && ln -s /opt/scala/bin/scalac /usr/local/bin/scalac \
 && ln -s /opt/scala/bin/scaladoc /usr/local/bin/scaladoc \
 && rm -f scala-${SCALA_VERSION}.tgz
ENV SCALA_HOME=/opt/scala
ENV PATH="${SCALA_HOME}/bin:${PATH}"

# 提示：JNI 头文件路径在 $JAVA_HOME/include 和 $JAVA_HOME/include/linux
CMD ["/bin/bash"]