echo "installing root cronjobs"

ngxblocker_cron="/etc/periodic/daily/update-ngxblocker"

cat <<HERE> $ngxblocker_cron
#!/bin/sh

update-ngxblocker -q -n
HERE
chmod +x $ngxblocker_cron

echo "installing foswiki cronjobs"

foswiki_root="/var/www/foswiki"
foswiki_crontabs="$foswiki_root/crontabs"
foswiki_crontabs_quarter_hourly="$foswiki_crontabs/15min"
foswiki_crontabs_hourly="$foswiki_crontabs/hourly"
foswiki_crontabs_daily="$foswiki_crontabs/daily"
foswiki_crontabs_weekly="$foswiki_crontabs/weekly"
foswiki_crontabs_monthly="$foswiki_crontabs/monthly"

su nginx <<SUDO

if test ! -d $foswiki_crontabs; then
  test -d $foswiki_crontabs || mkdir $foswiki_crontabs
  test -d $foswiki_crontabs_quarter_hourly || mkdir $foswiki_crontabs_quarter_hourly
  test -d $foswiki_crontabs_hourly || mkdir $foswiki_crontabs_hourly
  test -d $foswiki_crontabs_daily || mkdir $foswiki_crontabs_daily
  test -d $foswiki_crontabs_weekly || mkdir $foswiki_crontabs_weekly
  test -d $foswiki_crontabs_monthly || mkdir $foswiki_crontabs_monthly

  cat <<HERE | crontab -
# do daily/weekly/monthly maintenance
# min   hour    day     month   weekday command
*/15    *       *       *       *       run-parts $foswiki_crontabs_quarter_hourly
0       *       *       *       *       run-parts $foswiki_crontabs_hourly
0       2       *       *       *       run-parts $foswiki_crontabs_daily
0       3       *       *       6       run-parts $foswiki_crontabs_weekly
0       5       1       *       *       run-parts $foswiki_crontabs_monthly
HERE
fi

### weekly
if test ! -f $foswiki_crontabs_weekly/SolrPlugin; then
cat <<"HERE"> $foswiki_crontabs_weekly/SolrPlugin
export FOSWIKI_ROOT=$foswiki_root
cd $foswiki_root/tools

test -f solrjob && ./solrjob --mode full
HERE
chmod +x $foswiki_crontabs_weekly/SolrPlugin
fi

### daily
if test ! -f $foswiki_crontabs_daily/CacheContrib; then
cat <<HERE> $foswiki_crontabs_daily/CacheContrib
cd $foswiki_root/tools
test -f purgeCache && ./purgeCache
HERE
chmod +x $foswiki_crontabs_daily/CacheContrib
fi

if test ! -f $foswiki_crontabs_daily/TrashPlugin; then
cat <<HERE> $foswiki_crontabs_daily/TrashPlugin
cd $foswiki_root/bin
./rest /TrashPlugin/cleanUp >/dev/null
HERE
chmod +x $foswiki_crontabs_daily/TrashPlugin
fi

if test ! -f $foswiki_crontabs_daily/core; then
cat <<"HERE"> $foswiki_crontabs_daily/core
cd $foswiki_root/tools
./mailnotify -q
./tick_foswiki.pl
cd $foswiki_root/bin
./statistics subwebs=1 autocreate=1 >/dev/null
HERE
chmod +x $foswiki_crontabs_daily/core
fi

if test ! -f $foswiki_crontabs_daily/ImagePlugin; then
cat <<"HERE"> $foswiki_crontabs_daily/ImagePlugin
find -L $foswiki_root/pub/ -name "_igp*" -delete
HERE
chmod +x $foswiki_crontabs_daily/ImagePlugin
fi

### hourly
if test ! -f $foswiki_crontabs_hourly/SolrPlugin; then
cat <<"HERE"> $foswiki_crontabs_hourly/SolrPlugin
export FOSWIKI_ROOT=$foswiki_root
cd $foswiki_root/tools
test -f solrjob && ./solrjob --mode delta
HERE
chmod +x $foswiki_crontabs_hourly/SolrPlugin
fi

SUDO

