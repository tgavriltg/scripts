#!/usr/bin/env python
# coding:utf-8
import sys
import urllib2
import time
import json
import requests

reload(sys)
sys.setdefaultencoding('utf-8')

title = "zabbix"   # 位置参数获取title 适用于zabbix
content = "test123test" # 位置参数获取content 适用于zabbix

class Token(object):
    # 获取token
    def __init__(self, corpid, corpsecret):
        self.baseurl = 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid={0}&corpsecret={1}'.format(
            corpid, corpsecret)
        self.expire_time = sys.maxint

    def get_token(self):
        if self.expire_time > time.time():
            request = urllib2.Request(self.baseurl)
            response = urllib2.urlopen(request)
            ret = response.read().strip()
            ret = json.loads(ret)
            if 'errcode' in ret.keys():
                print >> ret['errmsg'], sys.stderr
                sys.exit(1)
            self.expire_time = time.time() + ret['expires_in']
            self.access_token = ret['access_token']
        return self.access_token

def send_msg(title, content):
    # 发送消息
    qs_token = Token(corpid=corpid, corpsecret=corpsecret).get_token()
    url = "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token={0}".format(
        qs_token)
    payload = {
        "touser": "zhanghe5|masen",
        "msgtype": "text",
        "agentid": "1",
        "text": {
                   "content": "标题:{0}\n 内容:{1}".format(title, content)

        },
        "safe": "0"
    }
    ret = requests.post(url, data=json.dumps(payload, ensure_ascii=False))
    print ret.json()

#获取所有的openid，然后根据openid获取用户信息，提取出用户名，最后输出用户名与openid的对应关系。
class get_user():
    def __init__(self):
        self.access_token = Token(corpid, corpsecret).get_token()

    def get_userid_list(self):
        userid_list_url = 'https://qyapi.weixin.qq.com/cgi-bin/user/list?access_token={0}&department_id=1&fetch_child=1&status=0'.format(self.access_token)
        user_list = []
        #获取所有简单的用户信息
        #https://qyapi.weixin.qq.com/cgi-bin/user/simplelist?access_token=ACCESS_TOKEN&department_id=DEPARTMENT_ID&fetch_child=1&status=0
        request = urllib2.Request(userid_list_url)
        response = urllib2.urlopen(request)
        ret = response.read().strip()
        userid_list = json.loads(ret)
        for info in userid_list['userlist']:
            user_list.append(info['userid'])
        return user_list

    def verify_userid(self, user_list):
        for userid in user_list:
            user_info_url = 'https://qyapi.weixin.qq.com/cgi-bin/user/get?access_token={0}&userid={1}'.format(self.access_token, userid)
            user_info_request = urllib2.Request(user_info_url)
            user_info_response = urllib2.urlopen(user_info_request).read().strip()
            user_info = json.loads(user_info_response)
            if user_info['errcode'] != 0:
                print "userid:{0} verify faile, error info:{1}".format(userid, user_info)
            else:
                print "userid:{0} is ok.".format(user_info['userid'])

if __name__ == '__main__':
    corpid = "wxad3f0acdd3103911"  # 填写自己应用的
    corpsecret = "QSpww4U4kDetdpR9RDv-FBzTS_9lNzaJCsc4-mo4Dp2yVjMaXfaVHFuoJr_SisdfJ" # 填写自己应用的
    # print title, content
    send_msg(title, content)
    get_user().get_userid_list()
    get_user().verify_userid(['test','zhangsan'])
