FROM nvidia/cuda:12.0.1-runtime-ubuntu20.04

# tell apt to not ask for keyboard language inputs
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update \
    && apt-get install -y --no-install-recommends apt-transport-https openjdk-11-jdk openjdk-11-jre python python3-pip python3 python3-pip curl  \
    # We remove ensurepip since it adds no functionality since pip is
    # installed on the image and it just takes up 1.6MB on the image
    && rm -r /usr/lib/python*/ensurepip \
    && pip install --upgrade pip setuptools \
    # You may install with python3 packages by using pip3.6
    # Removed the .cache to save space
    && rm -r /root/.cache && rm -rf /var/cache/apt/*

ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-11.0.18.0.10-2.el9_1.x86_64
ENV PATH $PATH: /usr/lib/jvm/java-11-openjdk-11.0.18.0.10-2.el9_1.x86_64:/ /usr/lib/jvm/java-11-openjdk-11.0.18.0.10-2.el9_1.x86_64/bin

RUN rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd

# download directories below need to be synced with these
ENV SPARK_VERSION=spark-3.4.0-bin-hadoop3
ENV RAPIDS_CUDF_JAR=cudf-23.06.0-cuda12.jar
ENV RAPIDS_SPARK_JAR=rapids-4-spark_2.12-23.06.0.jar

COPY scripts/run-spark-shell-gpu.sh /opt/
COPY scripts/run-spark-shell-nogpu.sh /opt/
COPY scripts/entrypoint.sh /opt/

RUN mkdir -p /opt/spark \
 && mkdir -p /opt/spark/python \
 && mkdir -p /opt/spark/work-dir \
 && touch /opt/spark/RELEASE \
 && cd /tmp \
 && curl --output ${SPARK_VERSION}.tgz https://archive.apache.org/dist/spark/spark-3.4.0/${SPARK_VERSION}.tgz \
 && curl --output ${RAPIDS_CUDF_JAR} https://repo1.maven.org/maven2/ai/rapids/cudf/23.06.0/${RAPIDS_CUDF_JAR} \
 && curl --output ${RAPIDS_SPARK_JAR} https://repo1.maven.org/maven2/com/nvidia/rapids-4-spark_2.12/23.06.0/${RAPIDS_SPARK_JAR} \
 && curl --output getGpusResources.sh https://raw.githubusercontent.com/apache/spark/master/examples/src/main/scripts/getGpusResources.sh \
 && tar xzf ${SPARK_VERSION}.tgz \
 && cp -r ${SPARK_VERSION}/jars /opt/spark/jars \
 && cp -r ${SPARK_VERSION}/bin /opt/spark/bin \
 && cp -r ${SPARK_VERSION}/sbin /opt/spark/sbin \
 && cp -r ${SPARK_VERSION}/examples /opt/spark/examples \
 && cp -r ${SPARK_VERSION}/kubernetes/tests /opt/spark/tests \
 && cp -r ${SPARK_VERSION}/data /opt/spark/data \
 && cp -r ${SPARK_VERSION}/python/pyspark /opt/spark/python/pyspark \
 && cp -r ${SPARK_VERSION}/python/lib /opt/spark/python/lib \
 && cp ${RAPIDS_CUDF_JAR} /opt/spark/jars/ \
 && cp ${RAPIDS_SPARK_JAR} /opt/spark/jars/ \
 && cp getGpusResources.sh /opt/ \
 && chmod a+rx /opt/getGpusResources.sh \
 && rm -rf /tmp/* \
 && chown -R 9998:0 /opt \
 && chmod -R g+rwX /opt

ENV SPARK_HOME /opt/spark
WORKDIR /opt/spark/work-dir

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +rx /usr/bin/tini

ENTRYPOINT [ "/opt/entrypoint.sh" ]

