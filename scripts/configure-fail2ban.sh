echo "configuring fail2ban"

cat <<HERE> /etc/fail2ban/jail.d/defaults.conf
[DEFAULT]
maxretry = 3
bantime = 1w
HERE

cat <<HERE> /etc/fail2ban/jail.d/nginx.conf
[nginx-http-auth]
enabled = true

[nginx-botsearch]
enabled = true
HERE

cat <<HERE> /etc/fail2ban/jail.d/foswiki.conf
[foswiki]
enabled = true
action = iptables-multiport[name="foswiki", port="http,https"]
filter = foswiki
maxretry = 4
logpath = /var/www/foswiki/working/logs/events.log
HERE

cat <<HERE> /etc/fail2ban/filter.d/foswiki.conf
# Fail2Ban configuration file
#
# Author: George Clark
#
# $Revision: 1.9 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failure messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>[\w\-.^_]+)
# Values:  TEXT
#
#| 2010-06-25T16:16:04Z info | guest | login | Web.Topic | AUTHENTICATION FAILURE - asdfasdf -  Firefox | 192.168.1.30 |
#
failregex = .* \| AUTHENTICATION FAILURE - .* - .* \| <HOST> \|$

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
HERE

wget -q https://raw.githubusercontent.com/mitchellkrogza/Fail2Ban.WebExploits/master/webexploits.conf -O /etc/fail2ban/filter.d/webexploits.conf

cat <<HERE> /etc/fail2ban/jail.d/webexploits.conf
[webexploits]
enabled  = true
port     = http,https
filter   = webexploits
logpath = %(nginx_access_log)s
maxretry = 3
HERE

rc-update add fail2ban default
service fail2ban restart
