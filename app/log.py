# coding: utf-8
import logging
import os
import sys
# import graypy
import inspect

class Logger(logging.Logger):
    # @staticmethod
    # def graypy_handler(host, port):
    #     handler = graypy.GELFHandler(host, port)
    #     return handler

    @staticmethod
    def stdout_handler():
        handler = logging.StreamHandler(sys.stdout)
        fmt = '%(asctime)s %(levelname)s %(message)s'
        handler.setFormatter(logging.Formatter(fmt))
        return handler

    @staticmethod
    def file_handler(file_name):
        handler = logging.FileHandler(file_name)
        fmt = '%(asctime)s %(levelname)s %(filename)s.%(lineno)d %(message)s'
        handler.setFormatter(logging.Formatter(fmt))
        return handler

    # def __init__(self, graylog_host=None, graylog_port=None):
    def __init__(self):
        super().__init__('log', level=logging.DEBUG)
        # if graylog_host is not None:
        #     self.addHandler(self.graypy_handler(graylog_host, graylog_port))
        self.addHandler(self.stdout_handler())

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass


logger = Logger()
