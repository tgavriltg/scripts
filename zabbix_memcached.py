#!/usr/bin/env python
# -*- coding: utf-8 -*-

from tempfile import NamedTemporaryFile
import memcache
import optparse
import os

ITEMS = (
    'accepting_conns',
    'delete_hits',
    'cas_hits',
    'incr_misses',
    'decr_misses',
    'delete_misses',
    'incr_hits',
    'total_items',
    'threads',
    'reclaimed',
    'cmd_set',
    'cmd_get',
    'curr_connections',
    'cas_misses',
    'decr_hits',
    'cmd_flush',
    'bytes',
    'limit_maxbytes',
    'bytes_written',
    'connection_structures',
    'curr_items',
    'bytes_read',
    'evictions',
    'total_connections',
    'get_misses',
    'get_hits',
)

class Item(object):
    """Simple data container"""

    def __init__(self, key, value):
        self.key = key
        self.value = value

class MemcachedStatsReader(object):
    """"""

    def __init__(self, server, port):
        self._server = server
        self._port = port
        self._stats_raw = None
        self._stats = None
        print self._server
        print self._port

    def read(self):
        self._read_stats()
        self._parse_stats()
        return self._stats

    def _read_stats(self):
        mc = memcache.Client(['%s:%d' % (self._server,self._port)],debug=0)
        self._stats_raw = mc.get_stats()

    def _parse_stats(self):
        self._stats = list()
        for key in ITEMS:
            item = Item(key,int(self._stats_raw[0][1][key]))
            self._stats.append(item)

class ZabbixSender(object):
    """"""

    def __init__(self,zabbix_server,zabbix_port,host,memcached_port):
        self._zabbix_server = zabbix_server
        self._zabbix_port = zabbix_port
        self._host = host
        self._memcached_port = memcached_port
        self._tempfile = None

    def send(self, stats):
        self._write_temporary_file(stats)
        self._send_data_to_zabbix()

    def _write_temporary_file(self, stats):
        self._tempfile = NamedTemporaryFile()
        for item in stats:
            self._tempfile.write(u'%s memcached_stats[%d,%s] %s\n' % (self._host,self._memcached_port,item.key,item.value))
        self._tempfile.flush()

        self._tempfile.seek(0)
        print self._tempfile.read()

    def _send_data_to_zabbix(self):
        cmd = "zabbix_sender -z %s -p %d -i %s" % (self._zabbix_server,self._zabbix_port,self._tempfile.name)
        #cmd = [u'zabbix_sender', u'-z',self._zabbix_server, u'-p',self._zabbix_port,u'-i', self._tempfile.name]
        #call(cmd)
	print cmd
        os.system(cmd)
        self._tempfile.close()

def get_options():
    usage = "usage: %prog [options]"
    OptionParser = optparse.OptionParser
    parse = OptionParser(usage)

    parse.add_option("-z","--zabbix-server",action="store",type="string",dest="zabbix_server",help="(REQUIRED)Hostname or IP address of Zabbix server.")
    parse.add_option("-p","--port",action="store",type="int",dest="zabbix_port",default="10051",help="(REQUIRED)Specify port number of server trapper running on the server. Default is 10051.")
    parse.add_option("-s","--host",action="store",type="string",dest="host",help="(REQUIRED)Specify host name. Host IP address and DNS name will not work.")
    parse.add_option("--memcached-server",action="store",type="string",dest="memcached_server",default="127.0.0.1",help="(REQUIRED)Specify memcached server.Default is 127.0.0.1")
    parse.add_option("--memcached-port",action="store",type="int",dest="memcached_port",default="11211",help="(REQUIRED)Specify memcached port.Default is 11211.")

    options,args = parse.parse_args()

    if not options.zabbix_server:
        options.zabbix_server = raw_input("Zabbix Server IP:")

    return options,args

def main():
    options,args = get_options()
    zabbix_server = options.zabbix_server
    zabbix_port = options.zabbix_port
    host = options.host
    memcached_server = options.memcached_server
    memcached_port = options.memcached_port

    reader = MemcachedStatsReader(memcached_server,memcached_port)
    items = reader.read()

    sender = ZabbixSender(zabbix_server,zabbix_port,host,memcached_port)
    sender.send(items)

if __name__ == '__main__':
    main()
