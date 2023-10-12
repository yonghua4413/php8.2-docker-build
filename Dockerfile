FROM centos:7

#设置时区
ENV TZ=Asia/Shanghai
RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime

#复制源码
COPY ./src/* /usr/local/src/

#安装基本依赖
RUN yum update -y && yum -y install gcc autoconf gcc-c++ make libxml2 libxml2-devel openssl openssl-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel readline readline-devel libxslt libxslt-devel systemd-devel openjpeg-devel libicu-devel \
    && yum clean all \
    && rm -rf /var/cache/yum/*

RUN cd /usr/local/src/ && tar xvf pcre2-10.34.tar.gz && cd pcre2-10.34 && ./configure \
    --prefix=/usr/local/pcre2 \
    --enable-pcre2-16 \
    --enable-pcre2-32 \
    --enable-jit \
    --enable-jit-sealloc && make && make install && export PKG_CONFIG_PATH=/usr/local/pcre2/lib/pkgconfig/

#安装sqlite
RUN cd  /usr/local/src/ && tar -xvf sqlite-autoconf-3430100.tar.gz && cd sqlite-autoconf-3430100 && ./configure && make && make install

#安装libiconv
RUN cd  /usr/local/src/ && tar -xvf libiconv-1.16.tar.gz && cd libiconv-1.16 && ./configure --prefix=/usr/local/libiconv && ln -s /usr/local/lib/libiconv.so.2 /usr/lib64/ && make ZEND_EXTRA_LIBS="-liconv" -j4 && make install

#安装oniguruma
RUN cd /usr/local/src/ && rpm -i oniguruma-6.8.2-1.el7.x86_64.rpm && rpm -i oniguruma-devel-6.8.2-1.el7.x86_64.rpm

#安装libzip
RUN cd /usr/local/src/ && tar -xvf libzip-1.2.0.tar.gz && cd libzip-1.2.0 && ./configure && make && make install

#安装php
RUN cd /usr/local/src && tar -xvf php-8.2.11.tar.gz && cd php-8.2.11 && ./configure \
  --prefix=/usr/local/php \
  --with-config-file-path=/usr/local/php/etc \
  --with-config-file-scan-dir=/usr/local/php/conf.d \
  --enable-fpm \
  --with-fpm-systemd \
  --enable-fileinfo \
  --enable-mbstring \
  --enable-ftp \
  --enable-gd \
  --enable-gd-jis-conv \
  --enable-mysqlnd \
  --enable-pdo \
  --enable-sockets \
  --enable-xml \
  --enable-soap \
  --enable-pcntl \
  --enable-cli \
  --with-openssl \
  --with-mysqli=mysqlnd \
  --with-pdo-mysql=mysqlnd \
  --with-pear \
  --with-zlib \
  --with-zip \
  --with-iconv=/usr/local/libiconv \
  --with-curl PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/ && make -j4 && make install

#配置
RUN cd /usr/local/src/php-8.2.11 && \
    cp php.ini-production /usr/local/php/etc/php.ini && \
    sed -i -e 's/expose_php = On/expose_php = Off/g' /usr/local/php/etc/php.ini &&\
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf && \
    cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf && \
    sed -i -e 's/127.0.0.1:9000/0.0.0.0:9000/g' /usr/local/php/etc/php-fpm.d/www.conf && \
    ln -s /usr/local/php/bin/php /usr/bin/php && \
    ln -s /usr/local/php/bin/phpize /usr/bin/phpize && \
    ln -s /usr/local/php/sbin/php-fpm /usr/bin/php-fpm

#安装php-redis扩展
RUN cd /usr/local/src && \
    tar xvf phpredis-5.3.7.tar.gz && \
    cd phpredis-5.3.7 && /usr/local/php/bin/phpize && \
    ./configure --with-php-config=/usr/local/php/bin/php-config && make -j4 && make install && \
    echo 'extension="redis.so"' >> /usr/local/php/etc/php.ini && rm -rf phpredis

# 安装composer
RUN cd /usr/local/src && mv ./composer /usr/bin/composer && chmod +x /usr/bin/composer && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

WORKDIR /data/www

EXPOSE 9000

CMD ["/usr/local/php/sbin/php-fpm", "-F"]
