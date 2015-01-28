# How to install the latest version

This Project is meant to help a fast way to install from source code
the latest version of Apache, PHP and Ruby on Ubuntu Linux.

For all the commands below it is necessary to clone this repo or download the .sh file

### Preparing
  ```sh
  git clone https://github.com/danielsan/latest-apache-php-ruby
  cd latest-apache-php-ruby
  ```

## How to download and install Apache latest version?
  ```sh
  ./environment_setup.sh --apache-download --apache-install
  ```
#### How to download Apache latest version?
  ```sh
  ./environment_setup.sh --apache-download
  ```

#### How to install Apache latest version?
The following command assumes that your working directory
is the one with the apache source code.
  ```sh
  ./environment_setup.sh --apache-install
  ```

## How to download and install PHP latest version?
  ```sh
  ./environment_setup.sh --php-download --php-install
  ```
#### How to download PHP latest version?
  ```sh
  ./environment_setup.sh --php-download
  ```
#### How to install PHP latest version?
The following command assumes that your working directory
is the one with the PHP source code.
  ```sh
  ./environment_setup.sh --php-install
  ```

## How to install RbEnv latest version?
  ```sh
  ./environment_setup.sh --rbenv-install
  ```

## How to install Ruby latest version?
The following command assumes that your working directory
is the one with the PHP source code.
  ```sh
  ./environment_setup.sh --ruby-install
  ```

## How to install RbEnv and Ruby latest version?
  ```sh
  ./environment_setup.sh --rbenv-install --ruby-install
  ```
