#!/bin/bash
##################################
# Zabbix monitoring script
#
# nginx:
#  - anything available via nginx stub-status module
#
##################################
# Contact:
#  tgavriltg@gmail.com
##################################
# ChangeLog:
#  2014-03-28	VV	initial creation
##################################

# Zabbix default parameter
ZABBIX_SENDER="/usr/bin/zabbix_sender"
ZABBIX_SERVER="172.16.35.92"
if [ -x /usr/bin/zabbix_sender ];then
    ZABBIX_SENDER="/usr/bin/zabbix_sender"
elif [ -x /usr/local/sinawap/zabbix/bin/zabbix_sender ];then
    ZABBIX_SENDER="/usr/local/sinawap/zabbix/bin/zabbix_sender"
else
    echo "do not find zabbix_sender."
    exit 1
fi

# Nginx defaults
URL="http://127.0.0.1:80/nginx_status"
WGET="/usr/bin/wget"

#tmp file
TMP_FILE="/tmp/nginx_status"
#error info
ERROR_DATA="either can not connect / bad host / bad port, or cat not get intranet ip"

usage(){
cat << EOF
Usage:
This program is extract data from nginx stats to zabbix.
Options:
  --help|-h)
    Print help info.
  --zabbix-server|-z)
    Hostname or IP address of Zabbix server(default=172.16.35.92).
  --url|-u)
    nginx status default URL(default:http://127.0.0.1:80/nginx_status).
Example:
  ./$0 -z 172.16.35.92 -u http://localhost:80/nginx_status
EOF
}

while test -n "$1"; do
    case "$1" in
    -z|--zabbix-server)
        ZABBIX_SERVER=$2
        shift 2
        ;;
    -u|--url)
        URL=$2
	shift 2
	;;
    -h|--help)
        usage
        exit
        ;;
    *)
        echo "Unknown argument: $1"
        usage
        exit
        ;;
    esac
done

# Get localhost intranet ip
IP=$(ifconfig | grep addr: | grep -E "10\.|172\.16" | awk -F\: '{print $2}' | cut -d' ' -f 1)

# save the nginx stats in a variable for future parsing
NGINX_STATS=$($WGET -q $URL -O - 2)

# error during retrieve
if [ -z "$NGINX_STATS" -o -z "$IP" ]; then
  echo $ERROR_DATA
  exit 1
fi

# Extract data from nginx stats
active_connections=$(echo "$NGINX_STATS" | head -1 | cut -f3 -d' ')
accepted_connections=$(echo "$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f2 -d' ')
handled_connections=$(echo "$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f3 -d' ')
handled_requests=$(echo "$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f4 -d' ')
reading=$(echo "$NGINX_STATS" | tail -1 | cut -f2 -d' ')
writing=$(echo "$NGINX_STATS" | tail -1 | cut -f4 -d' ')
waiting=$(echo "$NGINX_STATS" | tail -1 | cut -f6 -d' ')

/bin/cat > $TMP_FILE << EOF
$IP active_connections $active_connections
$IP accepted_connections $accepted_connections
$IP handled_connections $handled_connections
$IP handled_requests $handled_requests
$IP reading $reading
$IP writing $writing
$IP waiting $waiting
EOF

$ZABBIX_SENDER -z $ZABBIX_SERVER -i $TMP_FILE

exit 0
