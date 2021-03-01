packages=$*

echo "installing alpine packages"

if test -n "$packages"; then
  apk add $packages
fi
