# Introduction

#  传统 BWA 的局限性
随着新一代测序（NGS）技术的发展，DNA 测序数据的规模呈指数级增长，序列比对（sequence alignment）通常是最耗时的步骤之一，需要将大量短序列逐条映射到一个体积庞大的参考基因组上。
尽管近年来在算法层面不断优化，但由于数据规模增长速度极快，序列比对仍然是整个分析流程中的主要性能瓶颈。

Burrows-Wheeler Aligner（BWA）是目前最常用的序列比对工具之一 ，同时BWA提供了多线程版本，可以实现在个人 PC ，服务器上多线程提高序列比对速度。
但是 BWA 只能运行一台服务器，收到单个服务器的 CPU 内存的限制，如果序列文件很大，那么运行时间往往很长，需要很长时间才能得到对别结果。


## SparkBWA 

为了解决这个问题，我们可以使用分布式的方法将基因对比的工作分散在多个服务器分别执行，然后最后在将运行结果合并起来。SparkBWA 就是这个解决方案的实现思路之一。

SparkBWA 主要是将 Apache Spark 计算框架，Hadoop 的 yarn 资源分配管理机制，以及 BWA 算法结合起来，让 BWA 在多台服务器上同时运行，最后再将每台机器的运行结果汇总一起。
Spark 本身自带的算子级别并行能力，容错机制，比较适合这类数据计算任务。

在本次 研究 中，我们做了以下事情
1. 首先将 Spark 版本，BWA 版本以及相应的 Hadoop，jdk 版本升级到最新版本，同时重新编译 jar 包，在本机伪hadoop集群上运行，验证 SparkBWA 的所有步骤能够正常运行。
2. 在三台服务器上验证，使用 chr22，hg38 作为索引文件，SparkBWA 是否能够正常运行，解决 hadoop 环境问题，SparkBWA 自身代码的问题，以及资源分配问题。
3. 以 hg38 作为索引文件，对比 SparkBWA 较于 BWA 来说，速度提升了多少倍

实验结果表明，在 3 台节点并行执行情况下，SparkBWA 相比于单机 BWA 性能确实有明显提升，在最优化的配置情况下，性能能提升到 10 倍以上。通过一系列的实验，本次研究验证了 SparkBWA 在最新版本
BWA 和 Spark 版本下的可行性，并对性能提升原因以及 SparkBWA 自身的不足点以及限制 进行了初步分析。

# Background

## 2.1 Burrows-Wheeler Aligner (BWA)
Burrows-Wheeler Aligner（BWA）是一种广泛使用的短序列比对工具。其中 BWA-MEM 是目前最常用的版本，本次研究的实验也是主要是基于 BWA-MEM 算法。本试验中我们主要使用 lhs3 的 bwa 作为基准测试，
使用类似如下命令进行基准测试：

```bash
/home/hadoop/bwa-0.7.19/bwa mem -v 3 -t 8 \
  -R "@RG\tID:foo\tLB:bar\tPL:illumina\tPU:illumina\tSM:ERR000589" \
  /home/hadoop/bwa_input_files_hg38/hg38.fa \
  /home/hadoop/bwa_input_files/ERR000589_1.filt.fastq \
  /home/hadoop/bwa_input_files/ERR000589_2.filt.fastq \
  > ~/bwa_input_files_copy/hg_38_output.sam
```

该命令使用 8 个线程在单台服务器上执行对比操作，其中 `/home/hadoop/bwa_input_files_hg38/hg38.fa ` 是使用 bwa 创建的索引文件，ERR000589_1.filt.fastq 和 ERR000589_2.filt.fastq 分别为序列文件。

BWA-MEM 的对比过程偏向于 CPU 密集型计算，但同时在对比过程中，算法也需要把 index 索引文件加载到内存中，当索引文件比较大时候，需要将整个索引文件加载到内存中。bwa 会逐条读取 FASTQ 文件中的每条 read 使用索引文件对其进行对比。
因此 FASTQ 输入文件具有可切分性，我们可以在运行 bwa mem 时候指定多线程来从 FASTQ 中不同位置进行对比，在单机模型上实现使用多线程并行进行处理。

而这种 FASTQ 具备可切分性，并可以并行地与索引文件进行对比，这为 SparkBWA 中在多台服务器上分布式并行运行 bwa 算法打下基础。




## 2.2 Apache Spark 与 YARN

Apache Spark 是一种数据处理的分布式计算框架，主要在内存中进行分布式计算。通过Resilient Distributed Dataset（RDD）将数据划分为多个分区并分布存储在集群的不同节点中，从而实现高效的数据并行计算。Spark 程序通常可以以DAG图的方式
来表示计算流程图，便于用户监控程序运行进度。

Spark 的算子主要包括 map，reduce 两类，采用数据并行方式在多个节点上运行，来提高整体数据的吞吐量。这用方式的可扩展性远高于在单机上采用多线程的方式运行 bwa，我们总能够通过增加集群节点的方式提高并行能力，减少单服务器多线程在
内存 cpu 方面的限制。

在资源管理方面，SparkBWA 并没有使用 Spark Standalone 的方式进行运行，而是选择使用 Yarn 作为资源管理器。也就是我们通过 Yarn 来指定 SparkBWA 能使用多少内存资源或者 CPU 资源。SparkBWA 会以 executor 的形式运行在
每个 yarn 的container 中，并通过 RPC 的方式进行通讯。

相比于 BWA，使用 SparkBWA 的另一个好处是提供了任务失败重新调度的机制。这样当某个节点的内存资源不够甚至某个节点无法访问时候，这个节点的任务会被重新分配到其他节点重新运行，保证任务能够尽可能运行下去，提高了bwa 的运行稳定性。

另外，在论文中也指出 SparkBWA 会从 hdfs 上读取 index 文件，并将结果写在 hdfs 上。当 index 文件和结果文件特别大时候，使用 hdfs 比单机存储在读写上吞吐量更大，不会让读写文件这些IO操作成为 SparkBWA 运行的瓶颈。

## 2.3 传统 BWA 的局限性

总结来说，SparkBWA 在以下两个方面突破了 传统 BWA 的局限性：
1. 使用分布式运行方式，来运行序列对比工作。即使序列文件再大，我们总可以通过增加集群节点的方式增加并行度，提高对比速度，这突破了单机运行 BWA 受到单节点内存，CPU 的限制。
2. 提供了更便捷的资源管理和容错机制。借助 yarn 的资源管理和容错，我们可以方便地控制运行任务所需要的内存资源。同时当个别节点无法访问时候，容错机制能最大程度上使用其他节点继续运行当前任务。

# SparkBWA Architecture

## 3.1 Overall Workflow

SparkBWA 的整体工作流程分为三个步骤：读取、切分 FASTQ 序列文件，调用 BWA 执行序列对比，合并与保存结果文件。整个过程借助 SparkBWA 的分布式计算能力，同时使用 JNI 的方式调度原生 bwa 算法进行序列对比。

首先 SparkBWA 会读取 hdfs 上的 FASTQ 序列文件，然后将 FASTQ 序列文件切分多个 partition，然后重新分区到集群的不同节点。由于 FASTQ 的 reads 之间不存在依赖问题，这一步能够自然地实现数据集别的并行。
在重新分区后，在 map 阶段每个 Spark executor 会负责处理一个或多个数据分析。首先每个节点的 Spark executor 会先将当前分区的 fastq 文件缓存到节点本地，然后通过 JNI 方式调用 executor 中编译好的 bwa 工具，对比本节点 index 文件，进行序列对比。
当对比完成后，把本地的对比结果 sam 文件上传到 hdfs 的临时目录上。
最后，SparkBWA 将 hdfs 上所有 executor 得到的 sam 文件 合并为一个 sam 文件，保存在 hdfs 上。

正如论文中提到的那样，整个流程中几个关键设计原则是：
1. 不对 BWA 的源代码进行修改，而是使用 JNI 调用与传参的方式，将 BWA 工具看成一个黑盒计算模块，通过这种方式保证兼容不同版本的 BWA，让系统具备较好的可维护性。
2. 使用 JNI 


## 3.2 Two-Level Parallelism
