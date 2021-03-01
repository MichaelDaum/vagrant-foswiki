hostname=$1

key_file=/etc/nginx/$hostname.key
cert_file=/etc/nginx/$hostname.crt

echo "creating ssl certificate for $hostname"

if test -f $key_file; then
  echo "... key file already exists, skipping"
else 
  echo "... generating key file $key_file"
  openssl genrsa -out $key_file 2048 >/dev/null 2>&1 && 
  chown nginx:nginx $key_file
fi

if test -f $cert_file; then
  echo "... cert file already exists, skipping"
else
  echo "... generating cert file $cert_file";
  openssl req -new -x509 -key $key_file -out $cert_file -days 3650 -subj /CN=$hostname >/dev/null &&
  chown nginx:nginx $cert_file
fi
