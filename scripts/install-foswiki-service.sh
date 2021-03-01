echo "installing foswiki service"

foswiki_rc_file="/etc/init.d/foswiki"

if test -f $foswiki_rc_file; then
  echo "... already installed, skipping"
  exit
fi

cat <<"EOF" > $foswiki_rc_file
#!/sbin/openrc-run

FOSWIKI_ROOT=/var/www/foswiki
FOSWIKI_FCGI=foswiki.fcgi
FOSWIKI_BIND=127.0.0.1:9001
FOSWIKI_CHILDREN=2
FOSWIKI_MAX_REQUESTS=-1
FOSWIKI_MAX_SIZE=1024000
FOSWIKI_CHECK_SIZE=10
FOSWIKI_WARMING=1
FOSWIKI_PNAME=foswiki

name="Foswiki"
pidfile=/var/www/foswiki/working/foswiki.pid
directory="${FOSWIKI_ROOT}/bin"
command_user="nginx:nginx"
command_args_background="-d"
command="${FOSWIKI_ROOT}/bin/${FOSWIKI_FCGI}"
command_args="-n ${FOSWIKI_CHILDREN}
              -l ${FOSWIKI_BIND}
              -c ${FOSWIKI_CHECK_SIZE}
              -x ${FOSWIKI_MAX_REQUESTS}
              -s ${FOSWIKI_MAX_SIZE}
              -p ${pidfile}
              -w ${FOSWIKI_WARMING}
              -a ${FOSWIKI_PNAME}
              -q "

depend() {
        need net
}
EOF
chmod +x $foswiki_rc_file
rc-update add foswiki default
service foswiki restart >/dev/null
