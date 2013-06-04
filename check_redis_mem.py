#!/usr/bin/env python
#encoding=utf8

import redis
import os
import sys
import getopt

def usage():
	print """
Usage:

check_redis_mem [-h|--help][-H|--hostname][-P|--port][-w|--warning][-c|--critical]

Options:
	--help|-h)
		print check_redis_mem help.
	--host|-H)
		Sets connect host.
	--port|-P)
		Sets connect port.
	--warning|-w)
		Sets a warning level for redis mem userd. Default is: off
	--critical|-c)
		Sets a critical level for redis mem userd. Default is: off
Example:
	./check_redis_mem -H 127.0.0.1 -P 6379 -w 80 -c 90
	This should output: mem is ok and used 10.50%"""
	sys.exit(3)

#if __name__ == "__main__":

try:
	options,args = getopt.getopt(sys.argv[1:],"hH:P:w:c:",["help","host=","port=","warning=","critical="])
	#print options
	#print args
except getopt.GetoptError as e:
	#print e.args
	usage()

warning = 75
critical = 85
host = ''
port = 0

for name,value in options:
	if name in ("-h","--help"):
		usage()
	if name in ("-H","--host"):
		host = value
	if name in ("-P","--port"):
		port = int(value)
	if name in ("-w","--warning"):
		warning = int(value)
	if name in ("-c","--critical"):
		critical = int(value)

if host == '' or port == 0:
	usage()

try:
	r = redis.Redis(host=host,port=port)
	if r.ping() == True:
		maxmem = r.config_get(pattern='maxmemory').get('maxmemory')
		usedmem = r.info().get('used_memory')
		temp=float(usedmem) / float(maxmem)
		tmp = temp*100
		used=int(usedmem) / 1024 / 1024
		max=int(maxmem) / 1024 / 1024
		temp=int(tmp)

		if int(tmp) >= warning and int(tmp) < critical:
			print "warning  mem is used %.2f%% | mem-used=%dMB;;%d;0;" % (tmp,used,max)
			sys.exit(1)
		elif int(tmp) >= critical:
			print "critical  mem is used %.2f%% | mem-used=%dMB;;%d;0;" % (tmp,used,max)
			sys.exit(2)
		else:
			print "ok  mem is used %.2f%% | mem-used=%dMB;;%d;0;" % (tmp,used,max)
			sys.exit(0)
	else:
		print "can't connect."
		sys.exit(2)
except Exception as e:
	print e.message
	usage()
