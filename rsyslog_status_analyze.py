#!/usr/bin/env python
#coding:utf-8

import sys
import os
import re
import time
import threading

class SendZabbix(threading.Thread):
    def __init__(self,zabbixServer,zabbixPort,tmpfile,intervalTime):
        threading.Thread.__init__(self)
        self.zabbixServer = zabbixServer
        self.zabbixPort = zabbixPort
        self.tmpfile = tmpfile
        self.intervalTime = intervalTime
    def run(self):
        while True:
            time.sleep(self.intervalTime)
            cmd = "/usr/bin/zabbix_sender -z %s -p %d -i %s" % (self.zabbixServer,self.zabbixPort,self.tmpfile)
            print cmd
            os.system(cmd)
            with open(self.tmpfile,'r+') as f:
                f.truncate()

def write_file(key,value,timestamp,host,tmpfile):
    print key,value,timestamp,host
    with open(tmpfile,'a') as f:
        f.write(u'%s %s %s %d\n' % (host,key,timestamp,value))
        f.flush

def decide_type(data,name,timestamp,host,tmpfile):
    if 'processed' in data.keys():
        p_key = name+'_processed'
        f_key = name+'_failed'
        write_file(p_key,int(data['processed']),timestamp,host,tmpfile)
        write_file(f_key,int(data['failed']),timestamp,host,tmpfile)
    elif 'enqueued' in data.keys():
        s_key = name+'_size'
        e_key = name+'_enqueued'
        f_key = name+'_full'
        d_full_key = name+'_discarded.full'
        d_nf_key = name+'_discarded.nf'
        m_key = name+'_maxqsize'
        write_file(s_key,int(data['size']),timestamp,host,tmpfile)
        write_file(e_key,int(data['enqueued']),timestamp,host,tmpfile)
        write_file(f_key,int(data['full']),timestamp,host,tmpfile)
        write_file(d_full_key,int(data['discarded.full']),timestamp,host,tmpfile)
        write_file(d_nf_key,int(data['discarded.nf']),timestamp,host,tmpfile)
        write_file(m_key,int(data['maxqsize']),timestamp,host,tmpfile)
    
def get_log(tmpfile):
    while True:
        try:
            line = sys.stdin.readline()
        except:
            break
        if not line:
            break

        if line:
            data = re.findall(r'{.*}',line)
            time = line.split(' ')[0]
            timestamp = time.split('|')[0]
            host = re.findall(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',line)[0]
            if data:
                data = eval(data[0])
		name = re.match(r'(action_|webInfoLog-|omprog-|impstats-).*',data['name'])
                if name:
                    name = name.group()
                    name = name.replace(' queue','')
                    name = name.replace('[','_').rstrip(']')
                    name = name.replace(' ','_')
                    if 'action_' not in name:
                        name = "action_" + name
                    decide_type(data,name,timestamp,host,tmpfile)
                elif data['name'] == 'main Q':
                    data['name'] = 'mainQ'
                    decide_type(data,data['name'],timestamp,host,tmpfile)
                elif data['name'] == 'main Q[DA]':
                    data['name'] = 'mainQ[DA]'
                    name=data['name'].replace('[','_').rstrip(']')
                    decide_type(data,name,timestamp,host,tmpfile)
            else:
                time.sleep(1)
        else:
            time.sleep(1)

def main():
    zabbixServer = '172.16.35.66'
    zabbixPort = 10051
    intervalTime = 10
    tmpFIle = '/run/shm/impstats.ini'
    sendThread = SendZabbix(zabbixServer,zabbixPort,tmpFIle,intervalTime)
    sendThread.start()
    get_log(tmpFIle)

if __name__ == '__main__':
    main()
