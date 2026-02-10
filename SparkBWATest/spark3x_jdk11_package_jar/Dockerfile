FROM eclipse-temurin:11-jdk

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/temurin-11-jdk
ENV PATH="$JAVA_HOME/bin:$PATH"

WORKDIR /workspace

# 基础构建环境
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget ca-certificates tar sudo vim less \
    maven python3 \
    build-essential gcc g++ make cmake pkg-config \
    zlib1g-dev libbz2-dev liblzma-dev libbz2-dev \
 && rm -rf /var/lib/apt/lists/*

# Scala 2.12（用于 Spark 3.5.7）——可选
ARG SCALA_VERSION=2.12.18
RUN wget -q https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz \
 && tar -xzf scala-${SCALA_VERSION}.tgz -C /opt \
 && ln -s /opt/scala-${SCALA_VERSION} /opt/scala \
 && ln -s /opt/scala/bin/* /usr/local/bin/ \
 && rm -f scala-${SCALA_VERSION}.tgz

ENV SCALA_HOME=/opt/scala

CMD ["/bin/bash"]