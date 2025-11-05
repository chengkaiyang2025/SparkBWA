docker buildx build --platform=linux/amd64 -t jdk8-hadoop3.3-spark3.3 .
  
docker run -it --name sparkbwa_3 \
  -p 9870:9870 \     # ✅ Hadoop NameNode UI 新端口
  -p 8088:8088 \     # YARN ResourceManager UI
  -p 4040:4040 \     # Spark App UI
  -p 7077:7077 \     # Spark Standalone Master
  -p 8080:8080 \     # Spark Master Web UI
  -p 18080:18080 \   # Spark History Server UI
  jdk11-hadoop3.3-spark3.3