#!/bin/bash
set -e

# Start sshd (Hadoop scripts use ssh to localhost even in single-node)
/usr/sbin/sshd

# Format NameNode on first run
if [ ! -d "/data/hdfs/namenode/current" ]; then
  echo "Formatting HDFS NameNode ..."
  $HADOOP_HOME/bin/hdfs namenode -format -force
fi

echo "Starting HDFS ..."
$HADOOP_HOME/sbin/start-dfs.sh

echo "Starting YARN ..."
$HADOOP_HOME/sbin/start-yarn.sh

# Option 1: Spark standalone (uncomment if you prefer standalone instead of YARN)
# $SPARK_HOME/sbin/start-master.sh
# $SPARK_HOME/sbin/start-worker.sh spark://localhost:7077

echo "All services started."
echo "HDFS UI:     http://localhost:50070"
echo "YARN UI:     http://localhost:8088"
echo "Spark (app UI appears when a job runs): http://localhost:4040"

# Keep container running
tail -f /dev/null
