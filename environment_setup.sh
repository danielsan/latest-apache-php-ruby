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

