# Based on https://github.com/puckel/docker-airflow and https://github.com/Drunkar/dockerfiles/tree/master/airflow
FROM ubuntu:18.04

# Define en_US.
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Airflow basic env
ENV COLORED_LOG_FORMAT='[%%(blue)s%%(asctime)s%%(reset)s] {%%(blue)s%%(filename)s:%%(reset)s%%(lineno)d} %%(log_color)s%%(levelname)s%%(reset)s - %%(log_color)s%%(message)s%%(reset)s'
ENV LOG_FORMAT='[%%(asctime)s] {%%(filename)s:%%(lineno)d} %%(levelname)s - %%(message)s'
ENV SIMPLE_LOG_FORMAT='%%(asctime)s %%(levelname)s - %%(message)s'
ENV LOG_FILENAME_TEMPLATE='{{ ti.dag_id }}/{{ ti.task_id }}/{{ ts }}/{{ try_number }}.log'
ENV LOG_PROCESSOR_FILENAME_TEMPLATE='{{ filename }}.log'
ENV LOG_ID_TEMPLATE ='{dag_id}-{task_id}-{execution_date}-{try_number}'
ENV SMTP_HOST = smtp.exmail.qq.com
ENV SMTP_STARTTLS = False
ENV SMTP_SSL = True
ENV SMTP_PASSWORD = BDreports1234
ENV SMTP_PORT = 465
ENV SMTP_MAIL_FROM = bigdata-reports@infinities.com.cn

RUN apt-get update --fix-missing && \
    apt-get -y install \
        build-essential \
        apt-utils \
        git \
        wget \
        curl \
        bzip2 \
        netcat \
        locales \
        ca-certificates \
        libglib2.0-0 \
        libxext6 \
        libsm6 \
        libxrender1 \
        libmysqlclient-dev \
        libpq-dev \
        libsasl2-dev \
        libssl-dev \
        libkrb5-dev \
        libffi-dev \
        libxml2-dev \
        libxslt-dev
ENV FERNET_KEY='40u1ZtDjgFwVVL_uSEDQxGHZpmtH0qG52ofT2llbau4='
ENV AIRFLOW_HOME=/home/airflow
ENV AIRFLOW_DAGS_WORKSPACE=${AIRFLOW_HOME}/workspace \
    AIRFLOW_DAGS_DIR=${AIRFLOW_HOME}/dags \
    AIRFLOW_FERNET_KEY=${FERNET_KEY} \
    AIRFLOW_WEBSERVER_SECRET_KEY=${FERNET_KEY}

RUN useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    curl https://repo.anaconda.com/miniconda/Miniconda3-py37_4.8.3-Linux-x86_64.sh -o ${AIRFLOW_HOME}/conda.sh && \
    /bin/bash ${AIRFLOW_HOME}/conda.sh -b -p /opt/conda && \
    rm ${AIRFLOW_HOME}/conda.sh

ENV PATH /opt/conda/bin:$PATH
COPY config/ ${AIRFLOW_HOME}
COPY bin/ ${AIRFLOW_HOME}
RUN conda install --yes --file ${AIRFLOW_HOME}/requirements-conda.txt \
    && pip install -r ${AIRFLOW_HOME}/requirements-pip.txt \
    && conda clean -i -t -y

#
# Install Airflow from the list of available options:
#
# 1. Uncomment to pip install from an official release
#RUN pip install airflow[celery,crypto,hive,jdbc,ldap,password,postgres,s3,vertica]==1.8.0
#
# 2. Uncomment to pip install from a github repo/branch/commit.  YMMV.
#
RUN pip install apache-airflow[celery,crypto,mysql,jdbc,password,postgres,s3,vertica,presto,redis,ssh] -i \
    https://mirrors.aliyun.com/pypi/simple/
#
# 3. Uncomment to git clone the repo, git checkout a branch, git reset to a commit, then build from source.
#
#RUN git clone https://github.com/dennisobrien/incubator-airflow.git airflow_src && \
#      cd airflow_src && \
#      git checkout dennisobrien/gunicorn-forwarded-allow-ips && \
#      git reset --hard 6aef967960207b9d0e472cb84b1112d1dc959139 && \
#      pip install -e .[celery,crypto,hive,jdbc,ldap,password,postgres,s3,vertica]

ENV MATPLOTLIBRC ${AIRFLOW_HOME}/.config/matplotlib/
ADD config/matplotlibrc ${AIRFLOW_HOME}/.config/matplotlib/matplotlibrc
RUN chmod 0644 ${AIRFLOW_HOME}/.config/matplotlib/matplotlibrc

# Uncomment if you want to install your own dags.
#COPY dags/ /usr/local/airflow/dags

RUN chown -R airflow: ${AIRFLOW_HOME} \
    && chmod +x ${AIRFLOW_HOME}/docker-entrypoint.sh \
    && chmod +x ${AIRFLOW_HOME}/wait-for-it.sh

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["./docker-entrypoint.sh"]
