#!/usr/bin/env python
#encoding:utf-8

import json, enum, time
from twisted.internet import reactor, protocol

class CameraCommand(enum.Enum):
    QUERY = 1
    FETCH_VERSION = 11
    FETCH_TOKEN = 0x101
    FETCH_STORAGE = 0x500
    FETCH_ROUTE_VIDEOS = 0x508
    FETCH_EVENT_VIDEOS = 0x509
    FETCH_IMAGES = 0x50A
    CAPTURE_VIDEO = 0x201
    CAPTURE_IMAGE = 0x301

class CameraProtocol(protocol.Protocol):
    def connectionMade(self):
        self.factory.clients.append(self)
        print 'new_connection -> num:%d'%(len(self.factory.clients))

    def connectionLost(self, reason):
        self.factory.clients.remove(self)
        print 'los_connection -> num:%d'%(len(self.factory.clients))

    def split_data(self, message):
        message_list = []
        depth, found, start = 0, False, 0
        for i in range(len(message)):
            if message[i] in ('\x5b', '\x7b'):
                found = True
                depth += 1
            elif message[i] in ('\x5d', '\x7d'):
                depth -= 1
            if found and depth == 0:
                found = False
                stop = i + 1
                message_list.append(message[start:stop])
                start = stop
        return message_list

    def respond_message(self, message):
        data = None
        try:
            data = json.loads(message)
        except BaseException as e:
            if data:
                print '%r data:%r'%(e, data)
            return
        print '+++\n%s'%message
        response = ''
        command = CameraCommand(data['msg_id'])
        if command == CameraCommand.QUERY:
            if data['type'] == 'date_time':
                response = '{ "rval": 0, "msg_id": 1, "type": "date_time", "param": "2017-06-29 19:35:34" }'
            elif data['type'] == 'app_status':
                response = '{ "rval": 0, "msg_id": 1, "type": "app_status", "param": "record" }'
            else:
                response = '{"rval": 0, "msg_id": 1}'
        elif command == CameraCommand.FETCH_VERSION:
            response = '{ "rval": 0, "msg_id": 11, "camera_type": "AE-CS2016-HZ2", "firm_ver": "V1.1.0", "firm_date": "build 161031", "param_version": "V1.3.0", "serial_num": "655136915", "verify_code": "JXYSNT" }'
        elif command == CameraCommand.FETCH_TOKEN:
            response = '{ "rval": 0, "msg_id": 257, "param": 1 }'
        elif command == CameraCommand.FETCH_STORAGE:
            response = '{ "rval": 0, "msg_id": 1280, "listing": [ { "path": "/mnt/mmc01/DCIM", "type": "nor_video" }, { "path": "/mnt/mmc01/EVENT", "type": "event_video" }, { "path": "/mnt/mmc01/PICTURE", "type": "cap_img" } ] }'
        elif command == CameraCommand.FETCH_ROUTE_VIDEOS:
            response = '{ "rval": 0, "msg_id": 1288, "totalFileNum": 207, "param": 0, "listing": [ { "name": "ch1_20170629_1923_0859.mp4" }, { "name": "ch1_20170629_1922_0858.mp4" }, { "name": "ch1_20170629_1921_0857.mp4" }, { "name": "ch1_20170629_1920_0856.mp4" }, { "name": "ch1_20170629_1919_0855.mp4" }, { "name": "ch1_20170629_0950_0854.mp4" }, { "name": "ch1_20170629_0949_0853.mp4" }, { "name": "ch1_20170629_0948_0852.mp4" }, { "name": "ch1_20170629_0947_0851.mp4" }, { "name": "ch1_20170629_0946_0850.mp4" }, { "name": "ch1_20170629_0945_0849.mp4" }, { "name": "ch1_20170629_0944_0848.mp4" }, { "name": "ch1_20170629_0943_0847.mp4" }, { "name": "ch1_20170629_0942_0846.mp4" }, { "name": "ch1_20170629_0941_0845.mp4" }, { "name": "ch1_20170629_0940_0844.mp4" }, { "name": "ch1_20170629_0939_0843.mp4" }, { "name": "ch1_20170629_0938_0842.mp4" }, { "name": "ch1_20170629_0937_0841.mp4" }, { "name": "ch1_20170629_0936_0840.mp4" } ] }'
        elif command == CameraCommand.FETCH_EVENT_VIDEOS:
            response = '{ "rval": 0, "msg_id": 1289, "totalFileNum": 43, "param": 0, "listing": [ { "name": "ch1_20170628_2004_0043.mp4" }, { "name": "ch1_20170628_2004_0042.mp4" }, { "name": "ch1_20170628_2002_0041.mp4" }, { "name": "ch1_20170628_1959_0040.mp4" }, { "name": "ch1_20170628_1956_0039.mp4" }, { "name": "ch1_20170628_1951_0038.mp4" }, { "name": "ch1_20170628_1950_0037.mp4" }, { "name": "ch1_20170628_1950_0036.mp4" }, { "name": "ch1_20170628_1947_0035.mp4" }, { "name": "ch1_20170628_1946_0034.mp4" }, { "name": "ch1_20170628_1946_0033.mp4" }, { "name": "ch1_20170628_1946_0032.mp4" }, { "name": "ch1_20170628_1945_0031.mp4" }, { "name": "ch1_20170628_1944_0030.mp4" }, { "name": "ch1_20170628_1944_0029.mp4" }, { "name": "ch1_20170628_1943_0028.mp4" }, { "name": "ch1_20170628_1941_0027.mp4" }, { "name": "ch1_20170628_1939_0026.mp4" }, { "name": "ch1_20170628_1938_0025.mp4" }, { "name": "ch1_20170628_1938_0024.mp4" } ] }'
        elif command == CameraCommand.FETCH_IMAGES:
            response = '{ "rval": 0, "msg_id": 1290, "totalFileNum": 37, "param": 0, "listing": [ { "name": "ch1_20170629_1924_0037.jpg" }, { "name": "ch1_20170628_2004_0036.jpg" }, { "name": "ch1_20170628_2004_0035.jpg" }, { "name": "ch1_20170628_2004_0034.jpg" }, { "name": "ch1_20170628_2004_0033.jpg" }, { "name": "ch1_20170628_2002_0032.jpg" }, { "name": "ch1_20170628_1951_0031.jpg" }, { "name": "ch1_20170628_1950_0030.jpg" }, { "name": "ch1_20170628_1950_0029.jpg" }, { "name": "ch1_20170628_1950_0028.jpg" }, { "name": "ch1_20170628_1947_0027.jpg" }, { "name": "ch1_20170628_1946_0026.jpg" }, { "name": "ch1_20170628_1946_0025.jpg" }, { "name": "ch1_20170628_1946_0024.jpg" }, { "name": "ch1_20170628_1945_0023.jpg" }, { "name": "ch1_20170628_1945_0022.jpg" }, { "name": "ch1_20170628_1944_0021.jpg" }, { "name": "ch1_20170628_1944_0020.jpg" }, { "name": "ch1_20170628_1943_0019.jpg" }, { "name": "ch1_20170628_1941_0018.jpg" } ] }'
        else:
            response = '{ "rval": 0, "msg_id": %d }'%(command.value)
        print '>>> %r\n'%response
        self.transport.write(response + '\n')

    def dataReceived(self, data):
        for message in self.split_data(data):
            self.respond_message(message)

def main():
    factory = protocol.Factory()
    factory.clients = []
    factory.protocol = CameraProtocol
    reactor.listenTCP(8800, factory)
    reactor.run()

if __name__ == '__main__':
    main()

