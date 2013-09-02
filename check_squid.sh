#!/bin/bash
# 这个脚本主要是检测squid的每分钟http的请求熟、cpu的使用率、可用的文件描述符、5min的请求命中率、5min的内存请求命中率和5min的硬盘请求命中率。
# 并且可以通过pnp4nagios画图。

PROGNAME=`basename $0`
VERSION="Version 1.1"
AUTHOR="zhhmj (tgariltg@gmail.com)"

#DEFINES
ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3
#VARS
hostname="localhost"
port=8001
running=0
warn_descriptors=100
crit_descriptors=30
warn_hits=70
crit_hits=50

print_version() {
	echo "$PROGNAME $VERSION $AUTHOR"
}

print_help() {
	echo ""
	print_version
	echo ""
	echo "Description:"
	echo "Gets percentage of hits  for a squid reverse proxy"
	echo "Options:"
	echo "  -h|--help"
	echo "	 Print help info."
	echo "  -H|--hostname)"
	echo "   Sets the hostname, default is localhost"
	echo "  -P|--port)"
	echo "   Sets the port, default is 8001"
	echo "  -wd)"
	echo "   Sets the number of available file descriptors to warn at, default 100"
	echo "  -cd)"
	echo "   Sets the number of available file descriptors to go critical at, default 30"
	echo "  -wh)"
	echo "   Sets the percentage of hits to warn at, default 70"
	echo "  -ch)"
	echo "   Sets the percentage of hits to go critical at, default 50"
	echo ""
	echo "Example:"
	echo "	./check_squid -H 127.0.0.1 -P 8001 -wd 100 -cd 30 -wh 70 -ch 50"
	echo "	WARNING - Squid is serving an average of 7.2 per minute since start with 655349 file descriptors left and 0.04 percent of CPU use and Hits as 64% of all requests"
	exit $ST_UK
}

#获取squid的信息
get_status_text() {
	status_text=$(squidclient -h ${hostname} -p ${port} mgr:info 2>&1)
}

#确保服务器回复正常
is_replying() {
	case "$status_text" in
		*Denied.*)
			echo "Error gettings metrics.(Access control on squid?)"
			exit $ST_CR
			;;
		*ERROR*)
			echo "Error connecting to host"
			exit $ST_CR
			;;
	esac
}

#下面是获取有用的信息：
#Available file descriptors
#CPU Usage
#Average HTTP requests per minute
#Hits as % of all requests by 5min
#Memory hits as % of hit requests by 5min
#Disk hits as % of hit requests by 5min
get_statistics() {
	available_descriptors=$(echo "${status_text}" | grep "Available number of file descriptors" | cut -d: -f 2 | sed -e 's/^[ \t]*//')
	cpu_usage=$(echo "${status_text}" | grep "CPU Usage:" | cut -d: -f2 | cut -d% -f 1 | sed -e 's/^[ \t]*//')
	avg_http_requests=$(echo "${status_text}" | grep "Average HTTP requests per minute since start" | cut -d: -f2 | cut -d% -f 1 | sed -e 's/^[ \t]*//')
	all_requests_hits=$(echo "${status_text}" | grep "Hits as % of all requests" | awk '{print $8}' | awk -F\. '{print $1}')
	memory_hits=$(echo "${status_text}" | grep "Memory hits as % of hit requests" | awk '{print $9}' | awk -F\. '{print $1}')
	disk_hits=$(echo "${status_text}" | grep "Disk hits as % of hit requests" | awk '{print $9}' | awk -F\. '{print $1}')
	#buid perfdata string
	perfdata="'avail_descriptors'=$available_descriptors 'cpu_usage'=$cpu_usage 'avg_http_requests'=$avg_http_requests 'all_requests_hits'=$all_requests_hits% 'memory_hits'=$memory_hits% 'disk_hits'=$disk_hits%"
}

#报警对比的判断
build_output() {
#	out="Squid is serving an average of $avg_http_requests per minute since start with $available_descriptors file descriptors left and $cpu_usage percent of CPU use and Hits as $all_requests_hits% of all requests"
	out="avg:$avg_http_requests fd:$available_descriptors cpu:$cpu_usage hits:$all_requests_hits%"
#	if [ $available_descriptors -le $crit_descriptors ] || [ $all_requests_hits -le $crit_hits ]
	if [ $available_descriptors -le $crit_descriptors ]
	then
		echo "CRITICAL - ${out} | ${perfdata}"
		exit $ST_CR
#	elif [ $available_descriptors -le $warn_descriptors ] || [ $all_requests_hits -le $warn_hits ]
	elif [ $available_descriptors -le $warn_descriptors ]
	then
		echo "WARNING - ${out} | ${perfdata}"
		exit $ST_WR
	else
		echo "OK - ${out} | ${perfdata}"
		exit $ST_OK
	fi
}

#主程序
#获取参数
while test -n "$1"; do
	case "$1" in
		--help|-h)
			print_help
			exit $ST_UK
			;;
		--version|-v)
			print_version
			exit $ST_UK
			;;
		--hostname|-H)
			hostname=$2
			shift
			;;
		--port|-P)
			port=$2
			shift
			;;
		-wd)
			warn_descriptors=$2
			shift
			;;
		-cd)
			crit_descriptors=$2
			shift
			;;
		-wh)
			warn_hits=$2
			shift
			;;
		-ch)
			crit_hits=$2
			shift
			;;
		*)
			echo "Unknown argument: $1"
			print_help
			exit $ST_UK
			;;	
	esac
	shift
done

#sanity
if [ $warn_descriptors -lt $crit_descriptors ] || [ $warn_hits -lt $crit_hits ]
then
   echo "Warn descriptors must not be lower than critical and crit hits must not be lower than warn hits!"
   print_help
fi

get_status_text
is_replying
get_statistics
build_output
