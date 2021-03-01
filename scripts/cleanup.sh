echo "cleaning up"

foswiki_root="/var/www/foswiki"

rm -fr $foswiki_root/working/configure/download/* \
       $foswiki_root/working/configure/backup \
       $foswiki_root/working/tmp/* \
       /tmp/packages \
       /var/cache/apk/*apk
