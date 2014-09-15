import socket
import struct
import json
import os
import time
import sys
import re

ZABBIX_SERVER="127.0.0.1"
ZABBIX_PORT=10051

class ZSend:
   def __init__(self, server=ZABBIX_SERVER, port=ZABBIX_PORT):
      self.zserver = server
      self.zport = port
      self.list = []
      self.inittime = int(round(time.time()))
      self.header = '''ZBXD\1%s%s'''
      self.datastruct = '''
{ "host":"%s",
  "key":"%s",
  "value":"%s",
  "clock":%s }'''

   def add_data(self,host,key,value,evt_time=None):
      if evt_time is None:
         evt_time = self.inittime
      self.list.append((host,key,value,evt_time))

   def print_vals(self):
      for (h,k,v,t1) in self.list:
         print "Host: %s, Key: %s, Value: %s, Event: %s" % (h,k,v,t1)

   def build_all(self):
      tmpdata = "{\"request\":\"sender data\",\"data\":["
      count = 0
      for (h,k,v,t1) in self.list:
         tmpdata = tmpdata + self.datastruct % (h,k,v,t1)
         count += 1
         if count < len(self.list):
            tmpdata = tmpdata + ","
      tmpdata = tmpdata + "], \"clock\":%s}" % self.inittime
      return (tmpdata)

   def build_single(self,dataset):
      tmpdata = "{\"request\":\"sender data\",\"data\":["
      (h,k,v,t1) = dataset
      tmpdata = tmpdata + self.datastruct % (h,k,v,t1)
      tmpdata = tmpdata + "], \"clock\":%s}" % self.inittime
      return (tmpdata)

   def send(self,mydata):
      socket.setdefaulttimeout(5)
      data_length = len(mydata)
      data_header = struct.pack('i', data_length) + '\0\0\0\0'
      data_to_send = self.header % (data_header, mydata)
      try:
         sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
         sock.connect((self.zserver,self.zport))
         sock.send(data_to_send)
      except Exception as err:
         sys.stderr.write("Error talking to server: %s\n" % err)
         return (255,err)

      response_header = sock.recv(5)
      if not response_header == 'ZBXD\1':
         sys.stderr.write("Invalid response from server." + \
                          "Malformed data?\n---\n%s\n---\n" % mydata)
         return (254,err)
      response_data_header = sock.recv(8)
      response_data_header = response_data_header[:4]
      response_len = struct.unpack('i', response_data_header)[0]
      response_raw = sock.recv(response_len)
      sock.close()
      response = json.loads(response_raw)
      match = re.match("^.*Failed\s(\d+)\s.*$",str(response))
      '''if match is None:
         sys.stderr.write("Unable to parse server response - " + \
                          "\n%s\n" % response)
      else:
         fails = int(match.group(1))
         if fails > 0:
            sys.stderr.write("Failures reported by zabbix when sending:" + \
                             "\n%s\n" % mydata)
            return (1,response)'''
      return (0,response)


#####################################
# --- Examples of usage ---
#####################################
#
# Initiating a Zsend object -
# z = ZSend(server="10.0.0.10")
# z = ZSend(server="server1",port="10051")
# z = ZSend("server1","10051")
# z = ZSend() # Defaults to using ZABBIX_SERVER,ZABBIX_PORT
#

# --- Adding data to send later ---
# Host, Key, Value are all necessary
# z.add_data("host1","cpu.usage","12")
#
# Optionally you can provide a specific timestamp for the sample
# z.add_data("host1","cpu.usage","13","1365787627")
#
# If you provide no timestamp, the initialization time of the class
# is used.

# --- Printing values ---
# Not that useful, but if you would like to see your data in tuple form
# with assumed timestamps
# z.print_vals()

# --- Building well formatted data to send ---
# You can send all of the data in one batch -
# z.build_all() will return a string of packaged data ready to send
# z.build_single((host,key,value,timestamp)) will return a packaged single

# --- Sending data ---
# Typical example - build all the data and send it in one batch -
#
# z.send(z.build_all())
#
# Alternate example - build the data individually and send it one by one
# so that we can see errors for anything that doesnt send properly -
#
# for i in z.list:
#    (code,ret) = z.send(z.build_single(i))
#    if code == 1:
#       print "Problem during send!\n%s" % ret
#    elif code == 0:
#       print ret
#
#
#####################################
# Mini example of a working program #
#####################################
#
# z = ZSend() # Defaults to using ZABBIX_SERVER,ZABBIX_PORT
# z.add_data("host1","cpu.usage","12")
# z.print_vals()
# for i in z.list:
#    (code,ret) = z.send(z.build_single(i))
#    if code == 1:
#       print "Problem during send!\n%s" % ret
#    elif code == 0:
#       print ret
#
#####################################
