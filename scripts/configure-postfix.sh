echo "configuring postfix"

hostname=$1
mail_relay_host=$2
mail_root_alias=$3
domain=${hostname#*.}
postfix_conf="/etc/postfix/main.cf"

if grep -q "added by vagrant" $postfix_conf; then
  echo "... already configured, skipping"
  exit
fi

cat <<HERE>> $postfix_conf

### added by vagrant
alias_maps = hash:/etc/postfix/aliases
alias_database = hash:/etc/postfix/aliases
myhostname = $hostname
mydomain = $domain
biff = no

# relayhost = todo
HERE

newaliases
service postfix restart >/dev/null
rc-update -q add postfix default
