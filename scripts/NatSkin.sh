echo "configuring NatSkin"

foswiki_root="/var/www/foswiki"
site_preferences="$foswiki_root/data/Main/SitePreferences.txt"

(
su nginx <<HERE

cd $foswiki_root
./tools/configure -save \
  -set {Plugins}{AutoViewTemplatePlugin}{Enabled}='0' \
  -set {Plugins}{PreferencesPlugin}{Enabled}=0 \
  -set {Plugins}{PreferencesPlugin}{Enabled}=0 \
  -set {Plugins}{HomePagePlugin}{Enabled}=0 \
  -set {Plugins}{SubscribePlugin}{Enabled}='0' \
  -set {XSendFileContrib}{Header}='X-Accel-Redirect' \
  -set {XSendFileContrib}{Location}='/files' \
  -set {Plugins}{TablePlugin}{DefaultAttributes}='' \
  -set {DBCacheContrib}{Archivist}='Foswiki::Contrib::DBCacheContrib::Archivist::Sereal' \
  -set {TopicInteractionPlugin}{DefaultOfficeSuite}='msoffic' \
  -set {TopicInteractionPlugin}{WebDAVUrl}='webdav://$host/dav/$web/$topic/$attachment'

echo "cleaning up Main.WebHome"
sed -i '12,22d' $foswiki_root/data/Main/WebHome.txt

cat <<EOF>> $foswiki_root/data/Main/WebHome.txt
%META:PREFERENCE{name="ALLOWTOPICCHANGE" title="ALLOWTOPICCHANGE" type="Set" value="AdminGroup"}%
%META:PREFERENCE{name="NATSKIN_BANNERMODE" title="NATSKIN_BANNERMODE" type="Local" value="gradient"}%
%META:PREFERENCE{name="NATSKIN_BANNERCONTENT" title="NATSKIN_BANNERCONTENT" type="Local" value="text"}%
%META:PREFERENCE{name="NATSKIN_BANNERTEXT" title="NATSKIN_BANNERTEXT" type="Local" value="Welcome"}%
%META:PREFERENCE{name="NATSKIN_BANNERTEXTEFFECT" title="NATSKIN_BANNERTEXTEFFECT" type="Local" value="fadeInDown"}%
%META:PREFERENCE{name="NATSKIN_BANNERCOLOR" title="NATSKIN_BANNERCOLOR" type="Local" value="#30B7E9"}%
%META:PREFERENCE{name="NATSKIN_BANNERCOLOR2" title="NATSKIN_BANNERCOLOR2" type="Local" value="#202a6b"}%
%META:PREFERENCE{name="NATSKIN_BANNERGRADIENT" title="NATSKIN_BANNERGRADIENT" type="Local" value="radial"}%
%META:PREFERENCE{name="NATSKIN_BANNERFOREGROUND" title="NATSKIN_BANNERFOREGROUND" type="Local" value="light"}%
EOF

cd $foswiki_root/bin
./rest /DBCachePlugin/updateCache
./view refresh=all >/dev/null
HERE

) >/dev/null

if test -f /etc/init.d/foswiki; then
  echo "restarting foswiki service"
  service foswiki restart >/dev/null
fi
