echo "installing solr"

foswiki_root="/var/www/foswiki"
solr_version="5.5.5"
solr_archive="/tmp/packages/solr-$solr_version.tgz"
solr_download_url="https://archive.apache.org/dist/lucene/solr/$solr_version/solr-$solr_version.tgz"
solr_extract_dir="/opt"
solr_install_dir="$solr_extract_dir/solr-$solr_version"
solr_home="/var/solr"
solr_rc_file="/etc/init.d/solr"
solr_env="$solr_home/solr.in.sh"
solr_log_properties="$solr_home/log4j.properties"
solr_port=8983
solr_log_dir="/var/log/solr"

if test -f $solr_archive; then
  echo "... found solr package locally"
else
  echo "... downloading solr"
  wget -q -O $solr_archive $solr_download_url
fi

# stop running instance
if test -f $solr_rc_file; then
  echo "... stopping solr instance"
  service solr stop >/dev/null 2>&1
fi

# create user
solr_uid="$(id -u solr)"
if [ $? -ne 0 ]; then
  echo "creating user solr"
  addgroup -S solr
  adduser -S -s /bin/bash -G solr -D -h $solr_home solr
fi

if test -d $solr_install_dir; then
  echo "... already installed, skipping"
else
  echo "... extracting $solr_archive to $solr_install_dir"
  tar zxf $solr_archive -C $solr_extract_dir
  chown -R root: $solr_install_dir
  find $solr_install_dir -type d -print0 | xargs -0 chmod 0755
  find $solr_install_dir -type f -print0 | xargs -0 chmod 0644
  chmod -R 0755 $solr_install_dir/bin
  rm -f $solr_extract_dir/solr
  ln -s $solr_install_dir $solr_extract_dir/solr
fi

echo "... installing solr service"
cat <<HERE > $solr_rc_file
#!/sbin/openrc-run

name="Solr"
directory="$solr_install_dir/bin"
command_user="solr:solr"
command="$solr_install_dir/bin/solr"
directory="/opt/solr/bin"
pidfile="/var/solr/solr-8983.pid"
export SOLR_INCLUDE="/var/solr/solr.in.sh"

start() {
  ebegin "Starting solr"
  start-stop-daemon --start \
      --exec /opt/solr/bin/solr \
      --name solr \
      --user solr \
      --group solr \
      --pidfile $pidfile \
      -- \
      start
  eend $?
}

stop() {
  ebegin "Stopping solr"
  start-stop-daemon --stop \
      --exec /opt/solr/bin/solr \
      --name solr \
      --user solr \
      --group solr \
      --pidfile $pidfile \
      -- \
      stop
  eend $?
}

status() {
  su -c 'SOLR_INCLUDE="/var/solr/solr.in.sh" /opt/solr/bin/solr status' - solr
}
HERE

chmod +x $solr_rc_file

# install data directories and files
mkdir -p $solr_home/data/cores
mkdir -p $solr_log_dir
chown solr:solr $solr_log_dir

if test ! -f "$solr_home/data/solr.xml"; then
  cp $solr_install_dir/server/solr/solr.xml $solr_home/data/solr.xml
fi

if test -d $solr_home/data/cores/foswiki; then
  echo "... foswiki core already exists, skipping"
else
  echo "... installing foswiki core"
  cp -r $foswiki_root/solr/cores/foswiki $solr_home/data/cores/
  mkdir $solr_home/data/configsets
  ln -s $foswiki_root/solr/configsets/foswiki_configs $solr_home/data/configsets/
fi

if test -f $solr_log_properties; then
  echo "... $solr_log_properties already exists, skipping"
else
  echo "... configuring $solr_log_properties"
  cp $solr_install_dir/server/resources/log4j.properties $solr_log_properties
  sed_expr="s#solr.log=.*#solr.log=$solr_log_dir#"
  sed -i -e "$sed_expr" $solr_log_properties
  # downgrade log level 
  sed -i "s/log4j.rootLogger=WARN/log4j.rootLogger=INFO/" $solr_log_properties
fi

# install solr env
if test -f $solr_env; then
  echo "... solr.in.sh already exists, skipping"
else
  echo "... configuring $solr_env"
  cp $solr_install_dir/bin/solr.in.sh $solr_env
  cat  <<HERE>> $solr_env
SOLR_HOME="$solr_home/data"
LOG4J_PROPS="$solr_log_properties"
SOLR_LOGS_DIR="$solr_log_dir"
SOLR_PORT="$solr_port"
SOLR_OPTS="\$SOLR_OPTS -Djetty.host=localhost -Ddisable.configEdit=true"
SOLR_HOST="127.0.0.1"
SOLR_HEAP="1024m"
GC_LOG_OPTS=""
SOLR_PID_DIR="/var/solr"

HERE
fi

chown solr:solr $solr_env
chown -R solr:solr "$solr_home"
find $solr_home -type d -print0 | xargs -0 chmod 0750
find $solr_home -type f -print0 | xargs -0 chmod 0640

rc-update add solr default
service solr restart >/dev/null
