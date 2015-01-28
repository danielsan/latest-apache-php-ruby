#!/bin/bash
args=$@

if [[ " ${args[*]} " == *" --libs "* ]] ||
   [[ " ${args[*]} " == *" all "* ]]    ||
   [[ " ${args[*]} " == *" --php--install "* ]] ||
   [[ " ${args[*]} " == *" --apache--install "* ]]; then
  # required librearies for installing apache and php5
  sudo aptitude install -y \
   build-essential \
   autoconf \
   libreadline6-dev \
   libxml2-dev libxml2 \
   libcurl4-openssl-dev \
   libicu-dev \
   libapr1-dev libaprutil1-dev \
   libpng-dev libjpeg-dev \
   libmcrypt-dev \
   libltdl-dev \
   openssl \
   nodejs \
   npm \
   git
fi


export APACHE_HASHES_MATCH=1
if [[ " ${args[*]} " == *" --apache-download "* ]]; then
  APACHE_DOWNLOAD_DIR=~/Downloads/Xapache
  mkdir $APACHE_DOWNLOAD_DIR -p
  echo "Entering dir $APACHE_DOWNLOAD_DIR"
  cd $APACHE_DOWNLOAD_DIR

  APACHE_DOWNLOAD_PAGE_FILE=./apache_download_page.html
  APACHE_URL_PREFIX='http://archive.apache.org/dist/httpd/'
  curl -s "${APACHE_URL_PREFIX}?C=M;O=D" > $APACHE_DOWNLOAD_PAGE_FILE
  APACHE_URL=${APACHE_URL_PREFIX}$(grep -Po '"httpd-2\.4\.\d+\.tar.bz2"' $APACHE_DOWNLOAD_PAGE_FILE | head -1 | grep -Po '[^"]+')
  APACHE_FILE=$(echo $APACHE_URL | grep -Po 'httpd-\d\.\d\.\d+\.tar.bz2')
  APACHE_UNPACK_DIR=$(echo $APACHE_FILE | grep -Po 'httpd-\d\.\d\.\d+')
  APACHE_REMOTE_MD5=$(curl -s ${APACHE_URL}.md5 | grep -Po '\w{32}')

  DOWNLOAD=true
  if [ -f $APACHE_FILE ]; then
    echo "$APACHE_FILE already exists"
    echo "Checking MD5 hashes"
    APACHE_LOCAL_MD5=$(md5sum $APACHE_FILE | grep -Po '\w{32}')
    if [ $APACHE_REMOTE_MD5 == $APACHE_LOCAL_MD5 ]; then
      echo "Hashes match, not downloading again"
      DOWNLOAD=false
    else
      echo "Hashes don't match, removing ${APACHE_FILE}"
      cmd="rm -f ${APACHE_FILE}"
      echo $cmd;$cmd
    fi
  fi;

  if [ $DOWNLOAD == true ]; then
    echo "Downloading $APACHE_URL to $APACHE_FILE"
    echo "wget $APACHE_URL -O $APACHE_FILE"
    wget $APACHE_URL -O $APACHE_FILE
  fi
  echo "Checking MD5 hashes"
  APACHE_LOCAL_MD5=$(md5sum $APACHE_FILE | grep -Po '\w{32}')
  echo "APACHE_LOCAL_MD5=${APACHE_LOCAL_MD5}"
  echo "APACHE_REMOTE_MD5=${APACHE_REMOTE_MD5}"

  if [ $APACHE_REMOTE_MD5 == $APACHE_LOCAL_MD5 ]; then
    echo "Hashes match"
    echo
    echo "Extracting $APACHE_FILE ..."
    tar -xf $APACHE_FILE

    echo "Entering $APACHE_UNPACK_DIR"
    echo "cd $APACHE_UNPACK_DIR"
    cd $APACHE_UNPACK_DIR

    echo "=== READY TO INSTALL ==="
  else
    echo "Hashes don't match"
    export APACHE_HASHES_MATCH=0
  fi
fi


if [[ " ${args[*]} " == *" --apache--install "* ]]; then
  export APACHE_VERSION=$(grep Version: httpd.spec | grep -Po '\d+\.\d+\.\d+')
  export APACHE_RELEASE=$(grep Version: httpd.spec | grep -Po '\d+\.\d+')

  export APACHE_INSTALL_DIR=/opt/apache-${APACHE_VERSION}/
  export APACHE_RELEASE_DIR=/opt/apache-${APACHE_RELEASE}/

  # After download and decompress the apache 2.4.(last version) run this configure
  ./configure --prefix=${APACHE_INSTALL_DIR} \
    --enable-mods-shared=all \
    --enable-file-cache \
    --enable-isapi \
    --enable-cache-socache \
    --enable-so \
    --enable-deflate \
    --enable-expires \
    --enable-proxy \
    --enable-proxy-balancer \
    --enable-proxy-http \
    --enable-ssl \
    --enable-vhost-alias \
    --enable-rewrite \
    --with-mpm=prefork \
    --with-program-name=apache && \
  make && \
  sudo make install || exit

  sudo rm -f $APACHE_RELEASE_DIR
  sudo ln -s $APACHE_INSTALL_DIR $APACHE_RELEASE_DIR

  # edit /opt/apache-2.4/conf/apache.conf
  #LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
  sudo sed -i 's~#LoadModule slotmem_shm_module ~LoadModule slotmem_shm_module ~' /opt/apache-2.4/conf/apache.conf

  #LoadModule rewrite_module modules/mod_rewrite.so
  sudo sed -i 's~#LoadModule rewrite_module ~LoadModule rewrite_module ~' /opt/apache-2.4/conf/apache.conf

  sudo mkdir -p /opt/apache-2.4/conf/extra/vhosts/

  # sudo vim /etc/environment
  # add the following paths to the end of the content of the PATH variable ("inside the quotes")
  if ! grep -q '/opt/apache-2.4/bin' /etc/environment; then
    echo "adding '/opt/apache-2.4/bin' to the PATH variable in /etc/environment"
    sudo sed -i 's~"$~:/opt/apache-2.4/bin"~' /etc/environment
    source /etc/environment
  fi

  # sudo vim /etc/sudoers
  # add the following paths to the end of the content of secure_path=
  if ! grep -q '/opt/apache-2.4/bin' /etc/sudoers; then
    echo "adding '/opt/apache-2.4/bin' to the PATH variable in /etc/sudoers"
    sudo sed -i 's~"$~:/opt/apache-2.4/bin"~' /etc/sudoers
  fi
fi


export PHP_HASHES_MATCH=1
if [[ " ${args[*]} " == *" --php-download "* ]]; then
  PHP_DOWNLOAD_DIR=~/Downloads/Xphp
  mkdir $PHP_DOWNLOAD_DIR -p
  echo "Entering dir $PHP_DOWNLOAD_DIR"
  cd $PHP_DOWNLOAD_DIR

  PHP_DOWNLOAD_PAGE_FILE=./php_download_page.html
  curl -s http://php.net/downloads.php > $PHP_DOWNLOAD_PAGE_FILE
  PHP_URL='http://us1.php.net'$(grep -Po '"[^"]+.bz2/from/a/mirror"' $PHP_DOWNLOAD_PAGE_FILE | head -1 | grep -Po '[^"]+'| sed 's~/a/~/this/~' )
  PHP_FILE=$(echo $PHP_URL | grep -Po 'php-[^\/]+')
  PHP_UNPACK_DIR=$(echo $PHP_FILE | grep -Po 'php-\d\.\d\.\d+')
  PHP_REMOTE_MD5=$(grep 'class="md5sum"' $PHP_DOWNLOAD_PAGE_FILE | head -1 | grep -Po '\w{32}')

  DOWNLOAD=true
  if [ -f $PHP_FILE ]; then
    echo "$PHP_FILE already exists"
    echo "Checking MD5 hashes"
    PHP_LOCAL_MD5=$(md5sum $PHP_FILE | grep -Po '\w{32}')
    if [ $PHP_REMOTE_MD5 == $PHP_LOCAL_MD5 ]; then
      echo "Hashes match, not downloading again"
      DOWNLOAD=false
    else
      echo "Hashes don't match, removing ${PHP_FILE}"
      cmd="rm -f ${PHP_FILE}"
      echo $cmd;$cmd
    fi
  fi;

  if [ $DOWNLOAD == true  ]; then
    echo "Downloading $PHP_URL to $PHP_FILE"
    echo "wget $PHP_URL -O $PHP_FILE"
    wget $PHP_URL -O $PHP_FILE
  fi
  echo "Checking MD5 hashes"
  PHP_LOCAL_MD5=$(md5sum $PHP_FILE | grep -Po '\w{32}')
  echo "PHP_LOCAL_MD5=${PHP_LOCAL_MD5}"
  echo "PHP_REMOTE_MD5=${PHP_REMOTE_MD5}"

  if [ $PHP_REMOTE_MD5 == $PHP_LOCAL_MD5 ]; then
    echo "Hashes match"
    echo
    echo "Extracting $PHP_FILE ..."
    tar -xf $PHP_FILE

    echo "Entering $PHP_UNPACK_DIR"
    echo "cd $PHP_UNPACK_DIR"
    cd $PHP_UNPACK_DIR

    echo "=== READY TO INSTALL ==="
  else
    echo "Hashes don't match"
    export PHP_HASHES_MATCH=0
  fi
fi


if [[ " ${args[*]} " == *" --php-install "* ]] && [ $PHP_HASHES_MATCH == 1 ]; then
  # Finding out PHP_VERSION
  export PHP_VERSION=$(grep 'PHP_VERSION ' ./main/php_version.h | grep -Po "([\d\.]+)")
  echo PHP_VERSION=$PHP_VERSION
  export PHP_RELEASE=$(grep 'PHP_VERSION ' ./main/php_version.h | grep -Po "\d+\.\d+")
  echo PHP_RELEASE=$PHP_RELEASE
  export PHP_INSTALL_DIR=/opt/php-${PHP_VERSION}/
  echo PHP_INSTALL_DIR=$PHP_INSTALL_DIR
  export PHP_RELEASE_DIR=/opt/php-${PHP_RELEASE}/
  echo PHP_RELEASE_DIR=$PHP_RELEASE_DIR
exit
  # After download and decompress the php 5.6.(last version) run this configure
  ./configure --prefix=${PHP_INSTALL_DIR} \
  --with-openssl \
  --with-apxs2=/opt/apache-2.4/bin/apxs \
  --enable-debug \
  --enable-libgcc \
  --with-libxml-dir \
  --with-pcre-regex \
  --with-zlib \
  --enable-calendar \
  --with-curl \
  --enable-ftp \
  --enable-gd-native-ttf \
  --enable-intl \
  --enable-mbstring \
  --with-mysql \
  --with-mysqli \
  --enable-embedded-mysqli \
  --enable-opcache \
  --with-pdo-mysql \
  --enable-soap \
  --enable-sockets \
  --enable-zip \
  --with-readline \
  --with-gd \
  --with-mcrypt \
  --enable-pcntl \
  --enable-bcmath \
  --with-pear && \
  make && \
  sudo make install || exit

  sudo rm -f /opt/php-5.6
  sudo ln -s $PHP_INSTALL_DIR /opt/php-5.6
  # copy php.ini to php directory
  sudo cp ./php.ini-production /opt/php-5.6/lib/php.ini
  sudo sed -i 's~;date.timezone *= *$~date.timezone = America/New_York~' /opt/php-5.6/lib/php.ini

  # Configure apache to work with PHP
  # LoadModule php5_module        modules/libphp5.so
  sudo sed -i 's~#LoadModule php5_module ~LoadModule php5_module ~' /opt/apache-2.4/conf/apache.conf

  echo '
  # Add the following line
  AddHandler php5-script php

  # At the Include section add this line
  Include conf/extra/vhosts/*.conf
  ' | sudo tee -a /opt/apache-2.4/conf/apache.conf

  # sudo vim /etc/environment
  # add the following paths to the end of the content of the PATH variable ("inside the quotes")
  if ! grep -q '/opt/php-5.6/bin' /etc/environment; then
    echo "adding '/opt/php-5.6/bin' to the PATH variable in /etc/environment"
    sudo sed -i 's~"$~:/opt/php-5.6/bin"~' /etc/environment
    source /etc/environment
  fi
  if ! grep -q '/opt/php-5.6/bin' /etc/sudoers; then
    echo "adding '/opt/php-5.6/bin' to the PATH variable in /etc/sudoers"
    sudo sed -i 's~"$~:/opt/php-5.6/bin"~' /etc/sudoers
  fi
fi


if [[ " ${args[*]} " == *" --php-install "* ]]      || \
   [[ " ${args[*]} " == *" --php-libs "* ]] || \
   [[ " ${args[*]} " == *" --php-memcache "* ]]; then

  sudo /opt/php-5.6/bin/pecl install Memcache
  echo '[memcache]
  extension=memcache.so
  memcache.dbpath="/var/lib/memcache"
  memcache.maxreclevel=0
  memcache.maxfiles=0
  memcache.archivememlim=0
  memcache.maxfilesize=0
  memcache.maxratio=0
  ' | sudo tee -a /opt/php-5.6/lib/php.ini
fi

if [[ " ${args[*]} " == *" --php-install "* ]]      || \
   [[ " ${args[*]} " == *" --php-libs "* ]] || \
   [[ " ${args[*]} " == *" --php-mongo "* ]]; then

  sudo /opt/php-5.6/bin/pecl install Mongo
  echo '[mongo]
  extension=mongo.so
  ' | sudo tee -a /opt/php-5.6/lib/php.ini
fi

if [[ " ${args[*]} " == *" --php-install "* ]]      || \
   [[ " ${args[*]} " == *" --php-libs "* ]] || \
   [[ " ${args[*]} " == *" --php-redis "* ]]; then

  sudo /opt/php-5.6/bin/pecl install Redis
  echo '[redis]
  extension=redis.so
  ' | sudo tee -a /opt/php-5.6/lib/php.ini
fi


if [[ " ${args[*]} " == *" --php-install "* ]]      || \
   [[ " ${args[*]} " == *" --php-libs "* ]] || \
   [[ " ${args[*]} " == *" --php-composer "* ]]; then

  #curl -sS https://getcomposer.org/installer | php
  /opt/php-5.6/bin/php -r "readfile('https://getcomposer.org/installer');" | /opt/php-5.6/bin/php
  sudo mv composer.phar /usr/local/bin/

  echo '#!/bin/bash
  php -d memory_limit=-1 /usr/local/bin/composer.phar $@
  ' | sudo tee /usr/local/bin/composer
  sudo chmod 755 /usr/local/bin/composer
fi


if [[ " ${args[*]} " == *" --mongodb "* ]]; then
  # Mongodb 2.6.*
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
  echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
  sudo apt-get update
  sudo apt-get install -y mongodb-org
fi


if [[ " ${args[*]} " == *" --redis "* ]]; then
  # Redis last version
  sudo aptitude install -y redis-server
fi

if [[ " ${args[*]} " == *" --memcache "* ]] || [[ " ${args[*]} " == *" --memcached "* ]]; then
  # Redis last version
  sudo aptitude install -y memcached
fi

if [[ " ${args[*]} " == *" --rbenv "* ]]; then
  #### RUBY environment
  # https://github.com/sstephenson/rbenv#basic-github-checkout
  git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc  #or .bash_profile
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
  source ~/.bashrc

  # https://github.com/sstephenson/ruby-build#readme
  git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

  rbenv rehash
fi


if [[ " ${args[*]} " == *" --ruby-install "* ]]; then
  #try
  export RUBY_VERSION=$(rbenv install -list | grep -Po '^\s*2.+' | tail -1)
  rbenv install $RUBY_VERSION
fi

# if you have some error messages related to ripper like these messages:
#   linking shared-object ripper.so
#   make[2]: Leaving directory `/tmp/ruby-build.20140505165022.26735/ruby-2.2.0.preview2/ext/ripper'
#   make[1]: Leaving directory `/tmp/ruby-build.20140505165022.26735/ruby-2.2.0.preview2'
#   make: *** [build-ext] Error 2
#
# Try this out:
if [[ " ${args[*]} " == *" --alt-ruby-install "* ]]; then
  export RUBY_VERSION=$(rbenv install -list | grep -Po '^\s*2.+' | tail -1)
  RUBY_CONFIGURE_OPTS=--with-readline-dir="/lib/x86_64-linux-gnu/libreadline.so.6" rbenv install $RUBY_VERSION
fi


if [[ " ${args[*]} " == *" --ruby-install "* ]] || \
   [[ " ${args[*]} " == *" --alt-ruby-install "* ]]; then
  # then
  rbenv global $RUBY_VERSION
  rbenv rehash
  gem install bundler
  gem install capistrano
  rbenv rehash
fi