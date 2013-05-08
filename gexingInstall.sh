#!/bin/bash
#####################################################
# Last modified:    2013-01-16
# Filename:    GexingInstall.sh
#####################################################
PROGNAME=`basename $0`
VERSION="Version 1.0"
AUTHOR="zhhmj (tgariltg@gmail.com)"
export PATH=/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
Scripts=GexingInstall.sh

#变量定义

DATE=`date +%Y-%m-%d`
HOST=`hostname -s`
USER=`whoami`

#---------------------------------------------菜单函数------------------------------------------------------------------------   
#主菜单函数
mainchose()
{
    clear
    cat <<MAYDAY0
   __________________________________________________________________________
                                Redatoms
                   System environment deployment shell
                           （系统环境部署脚本）
   __________________________________________________________________________
  
          User:$USER            Host:$HOST              Date=$DATE
   __________________________________________________________________________
                   
                       1 : System parameter setting （系统参数设置）
                       2 : software install （应用软件安装）
                       q : quit shell (退出脚本)
   __________________________________________________________________________
MAYDAY0
echo "please input your chose:"
}

#软件选择安装菜单
softchose()
{
    clear
    cat <<MAYDAY0
   __________________________________________________________________________
                                Redatoms
                         Software Install List
                            （软件选择安装）
   __________________________________________________________________________
          User:$USER            Host:$HOST              Date=$DATE
   __________________________________________________________________________
                        1 : set yum source      安装yum源
                        2 ：rely                安装php依赖包
                        3 : php install         安装php
                        4 : nginx install       安装nginx
                        5 ：memcached install   安装memcache
                        6 ：apc install         安装apc
                        7 ：mysql install       安装mysql
                        8 ：varnish install     安装varnish
                        9 ：squid install       安装squid
                       10 ：nrpe install        安装nrpe
                        q ：back menu           返回主菜单
   __________________________________________________________________________
MAYDAY0
echo "please input your chose:"
}

#系统参数设置菜单
setchose()
{
    clear
    cat <<MAYDAY0
   __________________________________________________________________________
                                Redatoms
                      System parameter setting List
                           （系统参数设置选择）
   __________________________________________________________________________
          User:$USER            Host:$HOST              Date=$DATE
   __________________________________________________________________________
                        1 : sysctl setting      sysctl设置
                        2 : ulimut setting      ulimit设置
                        q ：back menu           返回主菜单
   __________________________________________________________________________
MAYDAY0
echo "please input your chose:"
}

#yum源选择设置菜单
yumchose()
{
    clear
    cat <<MAYDAY0
   __________________________________________________________________________
                                Redatoms
                            Yum Install List
                            （yum源选择安装）
   __________________________________________________________________________
          User:$USER            Host:$HOST              Date=$DATE
   __________________________________________________________________________
                        1 : epel yum source      安装epel源
                        2 ：percona yum source   安装mysql源
                        3 : webtatic yum source  安装php源
                        4 : puppet yum source    安装puppet源
                        5 ：nginx yum source     安装nginx源
                        q ：back menu            返回主菜单
   __________________________________________________________________________
MAYDAY0
echo "please input your chose:"
}

#---------------------------------------------执行函数------------------------------------------------------------------------   
#软件安装函数

#安装php及附属模块
rely()
{
    rpm -e perl-Net-SSLeay-1.30-4.fc6
    rpm -e perl-IO-Socket-SSL-1.01-1.fc6
    rpm -ivh perl-Net-SSLeay-1.36-1.el5.rfx.x86_64.rpm
    rpm -ivh perl-IO-Socket-SSL-1.34-1.el5.rfx.noarch.rpm
    yum -y install gcc  pcre pcre-devel perl perl-common-sense  perl-JSON-XS perl-JSON.noarch perl-Guard perl-EV perl-TermReadKey perl-YAML.noarch php-pear libmemcached libmemcached-devel
    pecl channel-update pecl.php.net
    exit 0
}
#安装php
php_install()
{
    yum -y install php php-pdo php-mbstring php-cli php-pear php-gd php-common php-mysql php-fpm php-devel
    exit 0
}
#安装nginx
nginx_install()
{
    yum -y install nginx
    exit 0
}
#安装memcached
memcached_install()
{
    yum -y install memcached
    exit 0
}
#安装php-memcached模块
php_memcached()
{
    tar zxvf memcached-1.0.2.tgz
    cd memcached-1.0.2
    /usr/bin/phpize
    ./configure && make && make install
    echo 'extension=memcached.so' > /etc/php.d/memcached.ini
    exit 0
}
#安装php-memcache模块
php_memcache()
{
    pecl install memcache << EOF
        no
EOF
    exit 0
}
#安装apc
php_apc()
{
    pecl install apc << EOF
yes
yes
yes
yes
yes
EOF
    /bin/cp -a apc.ini /etc/php.d/
    exit 0
}
#Mysql安装文件rpm版本为5.5.28
mysql_install()
{
    yum -y remove mysql
    rpm -ivh MySQL-server-5.5.28-1.linux2.6.x86_64.rpm
    exit 0
}
#检查php模块
check_php()
{
    /usr/bin/php -m
    exit 0
}


#安装yum源 
function yum_install
{
    while true
    do
      yumchose
      read LINE3
      case ${LINE3} in
          1)
          rpm -ivh http://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/epel-release-6-5.noarch.rpm
          exit 0
          ;;
          2)
          rpm -Uhv http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm 
          exit 0
          ;;
	  3)
	  rpm -ivh http://repo.webtatic.com/yum/el6/x86_64/webtatic-release-6-2.noarch.rpm
          exit 0
	  ;;
	  4)
	  rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-1.noarch.rpm
          exit 0
	  ;;
	  5)
	  rpm -ivh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
          exit 0
	  ;;
          q)
          break
          ;;
      esac
    done
}

function softinstall
{
    while true
    do
      softchose
      read LINE1
      case ${LINE1} in
          1)
          yum_install
          ;;
          2)
          rely
          ;;
          3)
          php_install
          ;;
          4)
          nginx_install
          ;;
          5)
          memcached_install
          ;;
          6)
          php_apc
          ;;
          7)
          mysql_install
          ;;
          8)
          php_memcached
          ;;
          9)
          php_memcache
          ;;
          q)
          break
          ;;
      esac
    done
}


#系统参数设置函数

function setmain
{
    while true
    do
      setchose
      read LINE2
      case ${LINE2} in
          1)
          sysctlset
          ;;
          2)
          ulimitset
          ;;
          q)
          break
          ;;
      esac
    done
}



#ha-sysctl参数设置
function sysctlset
{
cp /etc/sysctl.conf /etc/sysctl.conf-$(date +%F)
cat << EOF >> /etc/sysctl.conf
###############
net.ipv4.tcp_fin_timeout = 1
net.netfilter.nf_conntrack_max = 655360
net.ipv4.conf.default.arp_ignore = 1
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.ip_forward = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024    65000
net.ipv4.tcp_max_tw_buckets = 262140
net.ipv4.tcp_rfc1337 = 1
net.netfilter.nf_conntrack_max = 655360
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 1
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 1
net.netfilter.nf_conntrack_tcp_timeout_last_ack = 1
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 1
net.netfilter.nf_conntrack_tcp_timeout_close = 1
net.ipv4.tcp_timestamps = 1
EOF
/sbin/sysctl -p
exit 0
}

#ulimit参数设置
function ulimitset
{
cat << EOF >> /etc/security/limits.conf
*                soft   nofile          65536
*                hard   nofile          65536
EOF
exit 0
}

#----------------------------------------------主程序------------------------------------------------------------------------   

while true
do
    mainchose
    read LINE
    case $LINE in
        1)
        setmain
        ;;
        2)
        softinstall
        ;;
        q)
        break
        ;;
    esac
done
clear
