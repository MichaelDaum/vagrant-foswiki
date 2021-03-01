hostname=$1
foswiki_password=$2
http_proxy=$3
foswiki_version=$4
foswiki_root="/var/www/foswiki"

echo "installing foswiki $foswiki_version"

if test -d $foswiki_root; then
  echo "... already installed, skipping"
  exit
fi

cd /tmp/packages

unzip -q /tmp/packages/Foswiki-$foswiki_version.zip -d /tmp || exit
mv /tmp/Foswiki-$foswiki_version $foswiki_root || exit

echo "fixing file permissions"
chown -R nginx:nginx $foswiki_root
usermod -s /bin/bash nginx

cd $foswiki_root
su nginx <<HERE
  touch data/.htpasswd
  sh tools/fix_file_permissions.sh >/dev/null 2>&1
HERE

echo "confuring foswiki"
(
su nginx <<HERE

  cd $foswiki_root
  ./tools/configure -save -noprompt 
  ./tools/configure -save \
      -set {Password}='$foswiki_password' \
      -set {DefaultUrlHost}='https://$hostname' \
      -set {ScriptUrlPath}='/bin' \
      -set {ScriptUrlPaths}{view}='' \
      -set {PubUrlPath}='/pub' \
      -set {SafeEnvPath}='/bin:/usr/bin' \
      -set {PermittedRedirectHostUrls}='http://$hostname,https://$hostname' \
      -set {Htpasswd}{GlobalCache}=1 \
      -set {Htpasswd}{DetectModification}=1 \
      -set {EnableEmail}=1 \
      -set {Email}{MailMethod}='MailProgram' \
      -set {WebMasterEmail}='www@$hostname' \
      -set {Store}{SearchAlgorithm}='Foswiki::Store::SearchAlgorithms::PurePerl' \
      -set {Extensions}{PlainFileStoreContrib}{CheckForRCS}=0 \
      -set {Register}{UniqueEmail}=1 \
      -set {FastCGIContrib}{CheckLocalSiteCfg}=0 \
      -set {PROXY}{HOST}='$http_proxy' \
      -set {Stats}{AutoCreateTopic}='Always' \
      -set {Sessions}{EnableGuestSessions}=0 \
      -set {Sessions}{ExpireAfter}='-21600' \
      -set {HttpCompress}=1 \
      -set {LanguageFileCompression}=1 \
      -set {UserInterfaceInternationalisation}=1 \
      -set {Languages}{de}{Enabled}=1 \
      -set {JQueryPlugin}{DefaultPlugins}='chili' \
      -set {AuthScripts}='attach,compareauth,configure,edit,manage,previewauth,rdiffauth,rename,restauth,save,statistics,upload,viewauth,viewfileauth,diffauth';

  cp data/System/UsersTemplate.txt data/Main/WikiUsers.txt
  echo '%META:PREFERENCE{name="NOWYSIWYG" title="NOWYSIWYG" type="Set" value="on"}%' >> $foswiki_root/data/Main/AdminUser.txt

  test -f /var/www/foswiki/working/logs/events.log || touch /var/www/foswiki/working/logs/events.log
HERE
) >/dev/null 

if test -f /etc/init.d/foswiki; then
  echo "restarting foswiki service"
  service foswiki restart >/dev/null
fi
