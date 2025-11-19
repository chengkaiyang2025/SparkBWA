# Hadoop + YARN + Spark (client) via Docker Compose

This bundle runs HDFS (NN/DN) and YARN (RM/NM) in separate containers, plus a `spark-client`
container for submitting Spark jobs to YARN.

## Versions
- JDK: 8 (Temurin)
- Hadoop: 3.3.4
- Spark: 3.3.2 (Hadoop 3 prebuilt)
- Scala: 2.12.18

## How to use

1) Build the image (first time):
with cache:
```bash
docker compose build --no-cache 
```
```bash
docker compose build --progress=plain --build-arg BUILDKIT_STEP_LOG_MAX_SIZE=10485760 --build-arg BUILDKIT_STEP_LOG_MAX_SPEED=10485760 --network=host
```
2) Start the stack:
```bash
docker compose up -d
```

UIs:
- NameNode: http://localhost:9870
- ResourceManager: http://localhost:8088
- NodeManager: http://localhost:8042
- DataNode: http://localhost:9864

192.168.1.98
- NameNode: http://192.168.1.98:9870
- ResourceManager: http://192.168.1.98:8088
- NodeManager: http://192.168.1.98:8042
- DataNode: http://192.168.1.98:9864

3) Submit a Spark job:
```bash
docker compose exec spark-client bash

# Inside the container:
$SPARK_HOME/bin/spark-submit --master yarn --deploy-mode client --class org.apache.spark.examples.SparkPi $SPARK_HOME/examples/jars/spark-examples_2.12-3.3.2.jar 100
```

## Notes
- The first `namenode` start will auto-format HDFS and persist to the `nn-data` volume.
- If you run on Apple Silicon (arm64) but need amd64 images, use `docker buildx` with `--platform=linux/amd64`.
- To adjust memory/cores for YARN, set yarn-site.xml / mapred-site.xml accordingly.
