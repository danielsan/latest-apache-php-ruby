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

