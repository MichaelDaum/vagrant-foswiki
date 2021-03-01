packages=$*

echo "installing cpan packages"

if test -n "$packages"; then
  cpanm --notest --quiet $packages
fi

