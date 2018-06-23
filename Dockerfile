FROM debian:stretch-slim

RUN apt-get -y update && \
    apt-get -y install \
    build-essential \
      autotools-dev \
      rsync \
      curl \
      wget \
      jq \
      openssh-server \
      openssh-client \
      sudo \
      cmake \
      g++ \
      python-pip \
      gcc \
    # ifconfig
      net-tools  \
      iputils-ping  \
      vim \
      fish  \
      tmux && \
    apt-get autoremove

RUN apt-get install -y g++ automake wget autoconf autoconf-archive libtool libboost-all-dev \
    libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev liblz4-dev \
    liblzma-dev libsnappy-dev make zlib1g-dev binutils-dev libjemalloc-dev libssl-dev \
    pkg-config libiberty-dev git cmake libev-dev libhiredis-dev libzmq5 libzmq5-dev build-essential

## Install Folly
RUN git clone https://github.com/facebook/folly \
    && cd folly/folly \
    && git checkout tags/v2017.08.14.00 \
    && autoreconf -ivf \
    && ./configure \
    && make -j4 \
    && make install

## Install Cityhash
RUN git clone https://github.com/google/cityhash \
    && cd cityhash \
    && ./configure \
    && make all check CXXFLAGS="-g -O3" \
    && make install

COPY ./ /clipper

RUN  cd /clipper \
    && ./configure --cleanup-quiet \
    && ./configure --release \
    && cd release \
    && make -j8 management_frontend \
    && make -j8 query_frontend

# Install Redis.
RUN \
  cd /tmp && \
  wget http://download.redis.io/redis-stable.tar.gz && \
  tar xvzf redis-stable.tar.gz && \
  cd redis-stable && \
  make && \
  make install && \
  cp -f src/redis-sentinel /usr/local/bin && \
  mkdir -p /etc/redis && \
  cp -f *.conf /etc/redis && \
  rm -rf /tmp/redis-stable* && \
  sed -i 's/^\(bind .*\)$/# \1/' /etc/redis/redis.conf && \
  sed -i 's/^\(daemonize .*\)$/# \1/' /etc/redis/redis.conf && \
  sed -i 's/^\(dir .*\)$/# \1\ndir \/data/' /etc/redis/redis.conf && \
  sed -i 's/^\(logfile .*\)$/# \1/' /etc/redis/redis.conf

# Define mountable directories.
VOLUME ["/data"]

# Define working directory.
WORKDIR /data

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Define default command.
CMD ["redis-server", "/etc/redis/redis.conf"]

# Expose ports.
EXPOSE 6379
EXPOSE 1338
EXPOSE 1337
EXPOSE 7000

RUN pip install numpy scikit-learn requests
RUN cd ~ && git clone https://github.com/YuchenJin/clipper_caffe2.git
                
