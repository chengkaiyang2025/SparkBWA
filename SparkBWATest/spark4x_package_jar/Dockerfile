FROM eclipse-temurin:17-jdk-jammy

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java/openjdk
WORKDIR /workspace

# 基础工具 + Maven（如需本地 JNI/C++ 可加上 build-essential）
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget ca-certificates tar sudo vim less \
    maven python3 \
 && rm -rf /var/lib/apt/lists/*

# 安装 Scala 2.13（可改 ARG 为你需要的小版本）
ARG SCALA_VERSION=2.13.14
RUN wget -q https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz \
 && tar -xzf scala-${SCALA_VERSION}.tgz -C /opt \
 && ln -s /opt/scala-${SCALA_VERSION} /opt/scala \
 && ln -s /opt/scala/bin/scala /usr/local/bin/scala \
 && ln -s /opt/scala/bin/scalac /usr/local/bin/scalac \
 && ln -s /opt/scala/bin/scaladoc /usr/local/bin/scaladoc \
 && rm -f scala-${SCALA_VERSION}.tgz
ENV SCALA_HOME=/opt/scala
ENV PATH="${SCALA_HOME}/bin:${PATH}"

CMD ["/bin/bash"]