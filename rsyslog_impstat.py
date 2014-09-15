#!/usr/bin/env python
#coding:utf-8

import sys
import os
import re
import time
import threading
import zabbixSender

zabbixServer = '172.16.35.66'
zabbixPort = 10051
debug = False

def send_zabbix(z,key,value,timestamp,host):
    z.add_data(host,key,value,timestamp)
    if len(z.list) == 6:
        print z.list
        (code,ret) = z.send(z.build_all())
        if code == 1:
            print "Problem during send!\n%s" % ret
        elif code == 0:
            print ret
        z.list = []

def decide_type(z,data,name,timestamp,host):

    if 'processed' in data.keys():
        p_key = name+'_processed'
        f_key = name+'_failed'
        send_zabbix(z,p_key,int(data['processed']),timestamp,host)
        send_zabbix(z,f_key,int(data['failed']),timestamp,host)
    elif 'enqueued' in data.keys():
        s_key = name+'_size'
        e_key = name+'_enqueued'
        f_key = name+'_full'
        d_full_key = name+'_discarded.full'
        d_nf_key = name+'_discarded.nf'
        m_key = name+'_maxqsize'
        send_zabbix(z,s_key,int(data['size']),timestamp,host)
        send_zabbix(z,e_key,int(data['enqueued']),timestamp,host)
        send_zabbix(z,f_key,int(data['full']),timestamp,host)
        send_zabbix(z,d_full_key,int(data['discarded.full']),timestamp,host)
        send_zabbix(z,d_nf_key,int(data['discarded.nf']),timestamp,host)
        send_zabbix(z,m_key,int(data['maxqsize']),timestamp,host)

def get_log(z):
    while True:
        try:
            line = sys.stdin.readline()
        except:
            break
        if not line:
            break

        if debug == True:
            with open('/tmp/impstats_debug.log','a') as f:
                f.write(line)

        if line:
            data = re.findall(r'{.*}',line)
            if data:
                times = line.split(' ')[0]
                timestamp = times.split('|')[0]
                host = re.findall(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',line)[0]
                data = eval(data[0])
		name = re.match(r'(action_|webInfoLog-|omprog-|impstats-).*',data['name'])
                if name:
                    name = name.group()
                    name = name.replace(' queue','')
                    name = name.replace('[','_').rstrip(']')
                    name = name.replace(' ','_')
                    if 'action_' not in name:
                        name = "action_" + name
                    decide_type(z,data,name,timestamp,host)
                elif data['name'] == 'main Q':
                    data['name'] = 'mainQ'
                    decide_type(z,data,data['name'],timestamp,host)
                elif data['name'] == 'main Q[DA]':
                    data['name'] = 'mainQ[DA]'
                    name=data['name'].replace('[','_').rstrip(']')
                    decide_type(z,data,name,timestamp,host)
            else:
                time.sleep(1)
        else:
            time.sleep(1)

def main():
    z = zabbixSender.ZSend(zabbixServer,zabbixPort)
    get_log(z)

if __name__ == '__main__':
    main()
