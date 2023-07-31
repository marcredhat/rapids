https://uprush.medium.com/accelerating-apache-spark-with-rapids-on-gpu-27b2b8a77344

```
build/buildall --option='-Dcudf.version=cuda12' --profile=341 --option='-Drat.numUnapprovedLicenses=200'

https://dlcdn.apache.org/spark/spark-3.4.1/spark-3.4.1-bin-hadoop3.tgz
```

http://erikerlandson.github.io/blog/2021/06/03/running-rapids-spark-on-ocp/


```
https://github.com/erikerlandson/spark-rapids-ocp/blob/blog-june-2021/Dockerfile

kubectl patch serviceaccount spark  -p '{"imagePullSecrets": [{"name": "regcred"}]}'

```


```
export SPARK_HOME=/opt/spark
export IMAGE_NAME=ip-10-10-85-187.us-west-2.compute.internal:9999/cdppvc2/rapids340marc
export K8SMASTER=k8s://https://api.clev-ocp4-1dff9a7a.clevcdp.net:6443
export SPARK_NAMESPACE=finetune
export SPARK_DRIVER_NAME=sparkdriver


export JAVA_HOME="/usr"
$SPARK_HOME/bin/spark-submit \
     --master $K8SMASTER \
     --deploy-mode cluster  \
     --name examplejob \
     --class org.apache.spark.examples.SparkPi \
     --conf spark.dynamicAllocation.enabled=false \
     --conf spark.executor.instances=1 \
     --conf spark.executor.resource.gpu.amount=1 \
     --conf spark.executor.memory=4G \
     --conf spark.executor.cores=1 \
     --conf spark.driver.cores=1 \
     --conf spark.kubernetes.driver.limit.cores=1200m \
     --conf spark.driver.memory=512m \
     --conf spark.executor.instances=2 \
     --conf spark.executor.cores=1 \
     --conf spark.kubernetes.executor.limit.cores=1200m \
     --conf spark.executor.memory=1024m \
     --conf spark.task.cpus=1 \
     --conf spark.task.resource.gpu.amount=1 \
     --conf spark.rapids.memory.pinnedPool.size=2G \
     --conf spark.executor.memoryOverhead=3G \
     --conf spark.sql.files.maxPartitionBytes=512m \
     --conf spark.sql.shuffle.partitions=10 \
     --conf spark.plugins=com.nvidia.spark.SQLPlugin \
     --conf spark.kubernetes.namespace=$SPARK_NAMESPACE  \
     --conf spark.kubernetes.driver.pod.name=$SPARK_DRIVER_NAME  \
     --conf spark.executor.resource.gpu.discoveryScript=/opt/sparkRapidsPlugin/getGpusResources.sh \
     --conf spark.executor.resource.gpu.vendor=nvidia.com \
     --conf spark.kubernetes.container.image=$IMAGE_NAME \
     --conf spark.executor.extraClassPath=/opt/spark/jars/rapids-4-spark_2.12-23.06.0.jar \
     --conf spark.driver.extraClassPath=/opt/spark/jars/rapids-4-spark_2.12-23.06.0.jar \
     --driver-memory 100M \
     local:///opt/spark/examples/jars/spark-examples_2.12-3.4.0.jar
```

Interactive shell:
```
export SPARK_HOME=/opt/spark
export IMAGE_NAME=ip-10-10-85-187.us-west-2.compute.internal:9999/cdppvc2/rapids340marc
export K8SMASTER=k8s://https://api.clev-ocp4-1dff9a7a.clevcdp.net:6443
export SPARK_NAMESPACE=finetune
export SPARK_DRIVER_NAME=sparkdriver


export JAVA_HOME="/usr"
$SPARK_HOME/bin/spark-shell \
     --master $K8SMASTER \
     --name mysparkshell \
     --deploy-mode client  \
     --conf spark.dynamicAllocation.enabled=false \
     --conf spark.executor.instances=1 \
     --conf spark.executor.resource.gpu.amount=1 \
     --conf spark.executor.memory=4G \
     --conf spark.driver.cores=1 \
     --conf spark.kubernetes.driver.limit.cores=500m \
     --conf spark.driver.memory=512m \
     --conf spark.executor.instances=2 \
     --conf spark.executor.cores=1 \
     --conf spark.kubernetes.executor.limit.cores=500m \
     --conf spark.kubernetes.executor.request.cores=500m\
     --conf spark.executor.memory=1024m \
     --conf spark.task.cpus=1 \
     --conf spark.executor.cores=1 \
     --conf spark.task.cpus=1 \
     --conf spark.task.resource.gpu.amount=1 \
     --conf spark.rapids.memory.pinnedPool.size=500M \
     --conf spark.executor.memoryOverhead=500M \
     --conf spark.sql.files.maxPartitionBytes=512m \
     --conf spark.sql.shuffle.partitions=10 \
     --conf spark.plugins=com.nvidia.spark.SQLPlugin \
     --conf spark.kubernetes.namespace=$SPARK_NAMESPACE  \
     --conf spark.executor.resource.gpu.discoveryScript=/opt/sparkRapidsPlugin/getGpusResources.sh \
     --conf spark.executor.resource.gpu.vendor=nvidia.com \
     --conf spark.kubernetes.container.image=$IMAGE_NAME \
     --conf spark.executor.extraClassPath=/opt/spark/jars/rapids-4-spark_2.12-23.06.0.jar \
     --driver-class-path=/opt/spark/jars/rapids-4-spark_2.12-23.06.0.jar \
     --driver-memory 1G

```

https://nvidia.github.io/spark-rapids/docs/get-started/getting-started-kubernetes.html

```
val df = spark.sparkContext.parallelize(Seq(1)).toDF()
df.createOrReplaceTempView("df")
spark.sql("SELECT value FROM df WHERE value <>1").explain
```

```
spark.sql("SELECT value FROM df WHERE value <>1").show
```

[root@rhel91 spark-rapids-ocp]# kubectl view-allocations -r gpu
 Resource                                          Requested       Limit  Allocatable  Free
  nvidia.com/gpu                                  (100%) 3.0  (100%) 3.0          3.0   0.0
  ├─ ip-10-10-194-195.us-west-2.compute.internal  (100%) 1.0  (100%) 1.0          1.0   0.0
  │  └─ spark-shell-5bfc4b89a5e77262-exec-1              1.0         1.0           __    __
  ├─ ip-10-10-201-56.us-west-2.compute.internal   (100%) 1.0  (100%) 1.0          1.0   0.0
  │  └─ spark-shell-83856a89a5d98b2c-exec-2              1.0         1.0           __    __
  └─ ip-10-10-217-87.us-west-2.compute.internal   (100%) 1.0  (100%) 1.0          1.0   0.0
     └─ spark-shell-83856a89a5d98b2c-exec-1              1.0         1.0           __    __


oc scale machineset clev-ocp4-1dff9a7a-d7866-worker-gpu-us-west-2c --replicas=6 -n openshift-machine-api
```
