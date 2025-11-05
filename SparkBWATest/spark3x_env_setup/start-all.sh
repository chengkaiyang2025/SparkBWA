#!/usr/bin/env bash
# start-all.sh — for Hadoop 3.3.x + Spark 3.3.x
set -euo pipefail

# ====== Env ======
export HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"
export SPARK_HOME="${SPARK_HOME:-/opt/spark}"
export JAVA_HOME="${JAVA_HOME:-/opt/java/openjdk}"
export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH"

# Hadoop data dirs
NN_DIR="/data/hdfs/namenode"
DN_DIR="/data/hdfs/datanode"
mkdir -p "$NN_DIR" "$DN_DIR"

# Hadoop logs
mkdir -p "$HADOOP_HOME/logs"

# Optional: Spark event log dir (for History Server)
SPARK_EVENTS_DIR="${SPARK_EVENTS_DIR:-/tmp/spark-events}"
mkdir -p "$SPARK_EVENTS_DIR"

echo "JAVA_HOME=${JAVA_HOME}"
java -version || true
echo

# ====== First-time NN format ======
if [ ! -f "${NN_DIR}/current/VERSION" ]; then
  echo ">> Formatting HDFS NameNode (first time)..."
  hdfs namenode -format -force
fi

# ====== Optional: start sshd (if installed) ======
if command -v /usr/sbin/sshd >/dev/null 2>&1; then
  mkdir -p /var/run/sshd
  if ! pgrep -x sshd >/dev/null 2>&1; then
    echo ">> Starting sshd..."
    /usr/sbin/sshd || true
  fi
fi

# ====== Start HDFS (DFS) ======
echo ">> Starting HDFS..."
start-dfs.sh

# Basic health check
echo ">> Checking HDFS..."
timeout 30 bash -c 'until hdfs dfs -ls / >/dev/null 2>&1; do sleep 2; done' || true

# ====== Start YARN ======
echo ">> Starting YARN..."
start-yarn.sh

# ====== Optional: Spark History Server ======
# Enable by setting SPARK_HISTORY=1 (or true)
if [[ "${SPARK_HISTORY:-0}" = "1" || "${SPARK_HISTORY:-false}" = "true" ]]; then
  echo ">> Starting Spark History Server..."
  # Ensure event log enabled via spark-defaults.conf if you like:
  #   spark.eventLog.enabled true
  #   spark.eventLog.dir file:///tmp/spark-events
  "${SPARK_HOME}/sbin/start-history-server.sh" || true
fi

# ====== Print UIs ======
cat <<EOF

==== Services ====
HDFS NameNode UI:   http://localhost:9870
YARN ResourceMgr:   http://localhost:8088
Spark App UI(s):    http://localhost:4040   (when app is running)
Spark History UI:   http://localhost:18080  (if enabled)

HDFS nn dir: ${NN_DIR}
HDFS dn dir: ${DN_DIR}
Spark events: ${SPARK_EVENTS_DIR}
==================

EOF

# ====== Graceful shutdown ======
cleanup() {
  echo ">> Stopping services..."
  if [[ "${SPARK_HISTORY:-0}" = "1" || "${SPARK_HISTORY:-false}" = "true" ]]; then
    "${SPARK_HOME}/sbin/stop-history-server.sh" || true
  fi
  stop-yarn.sh || true
  stop-dfs.sh || true
  if pgrep -x sshd >/dev/null 2>&1; then
    pkill -TERM -x sshd || true
  fi
  echo ">> All services stopped."
}
trap cleanup INT TERM

# ====== Keep container alive; follow key logs ======
echo ">> Tail Hadoop logs (Ctrl+C to stop container)…"
# Tail will continue even if some files rotate/not exist yet
tail -n +1 -F \
  "$HADOOP_HOME/logs/"*namenode* \
  "$HADOOP_HOME/logs/"*datanode* \
  "$HADOOP_HOME/logs/"*resourcemanager* \
  "$HADOOP_HOME/logs/"*nodemanager* 2>/dev/null &
wait $!