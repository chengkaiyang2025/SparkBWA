

# Readme

- The src directory contains the SparkBWA source code upgraded to support Spark 3.x.
- submit_hg38.sh is the main test submission script. It can be executed directly on the buna server under the directory /home/hadoop/SparkBWA.
- The SparkBWATest/compliedJarFile directory contains previously compiled JAR files. The latest version used in this study is SparkBWA-jdk11-spark357-v10.jar.
- The SparkBWATest/spark3x_jdk11_package_jar directory provides the container environment configuration files used to build SparkBWA for Spark 3.x and JDK 11.
- The SparkBWATest/spark3x_env_setup_compose directory contains Docker Compose configurations for starting the services required by SparkBWA on a local laptop, such as Hadoop.


