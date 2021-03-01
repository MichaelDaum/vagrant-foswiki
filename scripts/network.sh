hostname=$1

interfaces_file="/etc/network/interfaces"

if grep -q "hostname $hostname" $interfaces_file; then
  # already configured, skipping
  exit
fi

echo "fixing hostname"
sed -i "/^ *hostname /d;/^iface eth/a\\ \\ \\ hostname $hostname" $interfaces_file
#cat $interfaces_file

echo "HOSTNAME=\"$hostname\"" > /etc/sysconfig/network

service networking restart
