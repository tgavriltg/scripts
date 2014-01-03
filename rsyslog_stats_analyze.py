#!/usr/bin/env python
#coding:utf-8

import sys
import os
import re
import time

zabbix_server='127.0.0.1'

def send_zabbix(key,value,host='test.mweibo.com'):
    '''send data to zabbix use zabbix_sender'''
    print '/usr/bin/zabbix_sender -z %s -s %s -k %s -o %d' % (zabbix_server,host,key,value)
    os.system('/usr/bin/zabbix_sender -z %s -s %s -k %s -o %d' % (zabbix_server,host,key,value))

def decide_type(data,name,host='test.mweibo.com'):

    if 'processed' in data.keys():
        p_key = name+'_processed'
        f_key = name+'_failed'
        send_zabbix(p_key,int(data['processed']),host)
        send_zabbix(f_key,int(data['failed']),host)
    elif 'enqueued' in data.keys():
        s_key = name+'_size'
        e_key = name+'_enqueued'
        f_key = name+'_full'
        d_full_key = name+'_discarded.full'
        d_nf_key = name+'_discarded.nf'
        m_key = name+'_maxqsize'
        send_zabbix(s_key,int(data['size']),host)
        send_zabbix(e_key,int(data['enqueued']),host)
        send_zabbix(f_key,int(data['full']),host)
        send_zabbix(d_full_key,int(data['discarded.full']),host)
        send_zabbix(d_nf_key,int(data['discarded.nf']),host)
        send_zabbix(m_key,int(data['maxqsize']),host)
    
def get_log():

    while True:
        try:
            line = sys.stdin.readline()
        except:
            break
        if not line:
            break

        if line:
            data = re.findall(r'{.*}',line)
            if data:
                data = eval(data[0])
                host = re.findall(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',line)[0]
                name = re.match(r'action_.*',data['name'])
                if name:
                    name = name.group()
                    name = name.replace('[','_').rstrip(']')
                    name = name.replace(' ','_')
                    decide_type(data,name,host)
                elif data['name'] == 'main Q':
                    data['name'] = 'mainQ'
                    decide_type(data,data['name'],host)
                elif data['name'] == 'main Q[DA]':
                    data['name'] = 'mainQ[DA]'
                    name=data['name'].replace('[','_').rstrip(']')
                    decide_type(data,name,host)
            else:
                time.sleep(1)
        else:
            time.sleep(1)


if __name__ == '__main__':
    get_log()
