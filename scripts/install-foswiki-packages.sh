packages=$*

foswiki_root="/var/www/foswiki"
package_dir="/tmp/packages"
need_restart=false

is_installed() {
  local pkg=$1
  local pkg_stub=

  case $pkg in
    *Skin)
      pkg_stub="$foswiki_root/lib/Foswiki/Contrib/$pkg.pm"
      ;;
    *Contrib)
      pkg_stub="$foswiki_root/lib/Foswiki/Contrib/$pkg.pm"
      ;;
    *Plugin)
      pkg_stub="$foswiki_root/lib/Foswiki/Plugins/$pkg.pm"
      ;;
    *)
      echo "ERROR: unknown foswiki package type $pkg"
  esac

  test -n "$pkg_stub" -a -f "$pkg_stub"
}

install_plugin() {
  local pkg=$1

  if test -f $package_dir/$pkg.zip; then
    echo "... found locally"
    su nginx <<HERE 
      cd $foswiki_root
      test -d $foswiki_root/working/configure/download || mkdir -p $foswiki_root/working/configure/download
      unzip -o $package_dir/$pkg.zip 
      ./tools/extension_installer $pkg -r -enable -o -x $foswiki_root install  >/dev/null
HERE

  else
    echo "... downloading from foswiki.org"
    su nginx <<HERE
      ./tools/extension_installer $pkg -r -enable install  >/dev/null
HERE

  fi
}

for pkg in $packages; do
  if is_installed $pkg; then
    true #echo "... $pkg already installed, skipping"
  else
    echo "installing $pkg"
    install_plugin $pkg
    need_restart=true
  fi
done

if test -f /etc/init.d/foswiki -a $need_restart = true; then
  echo "restarting foswiki service"
  service foswiki restart >/dev/null
fi
