#!/usr/bin/env bash

# Exit if any command fails
set -e -x

# Timestamp for output directories
timestamp=$(date +%Y%m%d_%H%M%S)

# Log file
LOG="benchmark_hg_38_${timestamp}.log"

echo "==== SparkBWA vs BWA Benchmark ====" | tee -a "$LOG"
echo "Start time: $(date)" | tee -a "$LOG"
echo | tee -a "$LOG"

########################################
# 1. Run SparkBWA (YARN cluster mode)
########################################

echo "[1/2] Running SparkBWA (spark-submit, YARN cluster mode)..." | tee -a "$LOG"
spark_start=$(date +%s)

/opt/spark-3/bin/spark-submit \
  --class com.github.sparkbwa.SparkBWA \
  --master yarn \
  --deploy-mode cluster \
  --conf spark.yarn.maxAppAttempts=3 \
  --conf spark.task.maxFailures=3 \
  --conf spark.stage.maxConsecutiveAttempts=3 \
  --executor-cores 4 \
  --executor-memory 2G \
  --conf spark.executor.memoryOverhead=8g \
  --num-executors 2 \
  --verbose \
  /home/hadoop/SparkBWA/SparkBWATest/compliedJarFile/SparkBWA-jdk11-spark357-v10.jar \
  -t /home/hadoop/spark_bwa_tmp \
  -m -r -p \
  --index /home/hadoop/bwa_input_files_hg38/hg38.fa \
  -n 2 \
  -w "-t 8 -R @RG\tID:foo\tLB:bar\tPL:illumina\tPU:illumina\tSM:ERR000589" \
  /user/hadoop/ERR000589_1.filt.fastq \
  /user/hadoop/ERR000589_2.filt.fastq \
  Output_ERR000589_hg38_${timestamp} | tee -a "$LOG"

spark_end=$(date +%s)
spark_elapsed=$((spark_end - spark_start))

echo | tee -a "$LOG"
echo "SparkBWA finished at: $(date)" | tee -a "$LOG"
echo "SparkBWA runtime: ${spark_elapsed} seconds (~$((spark_elapsed/60)) minutes)" | tee -a "$LOG"
echo | tee -a "$LOG"
# Uncomment,just for test.
#########################################
## 2. Run single-node BWA MEM
#########################################
#
#echo "[2/2] Running BWA MEM locally..." | tee -benchmark_hg_38_20251218_155434.log "$LOG"
#bwa_start=$(date +%s)
#
#/home/hadoop/bwa-0.7.19/bwa mem -v 3 -t 1 \
#  -R "@RG\tID:foo\tLB:bar\tPL:illumina\tPU:illumina\tSM:ERR000589" \
#  /home/hadoop/bwa_input_files_hg38/hg38.fa \
#  /home/hadoop/bwa_input_files/ERR000589_1.filt.fastq \
#  /home/hadoop/bwa_input_files/ERR000589_2.filt.fastq \
#  > ~/bwa_input_files_copy/hg_38_output_${timestamp}.sam
#
#bwa_end=$(date +%s)
#bwa_elapsed=$((bwa_end - bwa_start))
#
#echo | tee -benchmark_hg_38_20251218_155434.log "$LOG"
#echo "BWA MEM finished at: $(date)" | tee -benchmark_hg_38_20251218_155434.log "$LOG"
#echo "BWA MEM runtime: ${bwa_elapsed} seconds (~$((bwa_elapsed/60)) minutes)" | tee -benchmark_hg_38_20251218_155434.log "$LOG"
#
#########################################
## 3. Summary
#########################################
#
#echo | tee -benchmark_hg_38_20251218_155434.log "$LOG"
#echo "===== Benchmark Summary on HG38 =====" | tee -benchmark_hg_38_20251218_155434.log "$LOG"
#echo "SparkBWA: ${spark_elapsed} seconds (~$((spark_elapsed/60)) minutes)" | tee -benchmark_hg_38_20251218_155434.log "$LOG"
#echo "BWA MEM : ${bwa_elapsed} seconds (~$((bwa_elapsed/60)) minutes)" | tee -benchmark_hg_38_20251218_155434.log "$LOG"
#echo "Full log saved to: $LOG" | tee -benchmark_hg_38_20251218_155434.log "$LOG"
#
