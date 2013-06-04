#!/usr/bin/python
import smtplib
import string
import sys
import getopt

def usage():
    print """sendmail is a send mail Plugins
    Usage:

    sendmail [-h|--help][-t|--to][-s|--subject][-m|--message]

    Options:
   	--help|-h)
            print sendmail help.
        --to|-t)
            Sets sendmail to email.
        --subject|-s)
            Sets the mail subject.
        --message|-m)
            Sets the mail body
    Example:
     	only one to email  user
        ./sendmail -t 'eric@nginxs.com' -s 'hello eric' -m 'hello eric,this is sendmail test!
        many to email  user
        ./sendmail -t 'eric@nginxs.com,yangzi@nginxs.com,zhangsan@nginxs.com' -s 'hello eric' -m 'hello eric,this is sendmail test!"""
    sys.exit(3)

try:
    options,args = getopt.getopt(sys.argv[1:],"ht:s:m:",["help","to=","subject=","message="])
except getopt.GetoptError:
    usage()
for name,value in options:
    if name in ("-h","--help"):
        usage()
    if name in ("-t","--to"):
# accept message user
        TO = value
        TO = TO.split(",")
    if name in ("-s","--title"):
        SUBJECT = value
    if name in ("-m","--message"):
        MESSAGE = value
        MESSAGE = MESSAGE.split('\\n')
        MESSAGE = '\n'.join(MESSAGE)

#smtp HOST
HOST = "service.gexing.com"          
#smtp port
PORT = "25"                      
#FROM mail user
USER = 'monitor@service.gexing.com'                 
#FROM mail password
PASSWD = 'b34620330544f7132fe4e6617c4051b5'  
#FROM EMAIL
FROM = "monitor@service.gexing.com"   

try:
    BODY = string.join((
      	"From: %s" % FROM,
       	"To: %s" % TO,
      	"Subject: %s" % SUBJECT,
      	"",
      	MESSAGE),"\r\n")

    smtp = smtplib.SMTP()
    smtp.connect(HOST,PORT)
    smtp.login(USER,PASSWD)
    smtp.sendmail(FROM,TO,BODY)
    print "Send Ok!!!"
    smtp.quit()
except:
    print "UNKNOWN ERROR"
    print "please look help"
    print "./sendmail.py -h"
