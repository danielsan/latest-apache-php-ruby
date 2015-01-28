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