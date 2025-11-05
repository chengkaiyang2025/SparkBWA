docker buildx build --platform=linux/amd64 -t jdk8-hadoop2.7-spark2.4 .

docker run -it --name sparkbwa_2 \
  -p 50070:50070 \
  -p 8088:8088 \
  -p 4040:4040 \
  -p 7077:7077 \
  -p 8080:8080 \
  -p 18080:18080 \
  jdk8-hadoop2.7-spark2.4