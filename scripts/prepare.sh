echo "preparing image"

if ! grep -q testing /etc/apk/repositories; then
  echo "adding testing repository"
  echo "https://sjc.edge.kernel.org/alpine/edge/testing" >> /etc/apk/repositories
fi

if test -n "$(find /var/cache/apk -daystart -mtime +1 -name '*tar.gz')"; then
  echo "updating alpine packages"
  apk update && 
  apk upgrade && 
  apk add --update 
fi

# random admin config settings
rm -f /etc/skel/.screenrc
screen_rc_file="/home/vagrant/.screenrc"

if test ! -f $screen_rc_file; then
  echo "creating $screen_rc_file" 
  cat <<"EOF"> $screen_rc_file
startup_message off
deflogin on
defscrollback 1024
defutf8 on
hardstatus alwayslastline
hardstatus string "%{= KW} %H %{= Kw}|%{-} %-Lw%{= BW}%n%f %t%{-} %+Lw%="
EOF
  chown vagrant:vagrant $screen_rc_file
fi

chmod -R go+rX /tmp/packages
