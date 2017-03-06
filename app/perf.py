# coding: utf-8
from flask import Flask
from pymongo import MongoClient
from bson.binary import Binary
from safe_db_proxy import SafeMongoProxy
import random
from cy.make_set_cython import detect_users_densehash
import time

mongo_client = MongoClient('some-mongo', 27017, connect=False)
# mongo_client = SafeMongoProxy(_mongo_client, n_tries=3)
mdb = mongo_client['some-db']


def check_users(u1, u2):
    users = mdb['users']
    t_read = time.time()
    nets1 = users.find_one({"user": u1})['subnets']
    nets2 = users.find_one({"user": u2})['subnets']
    t_read = time.time() - t_read

    t_calc = time.time()
    check_result = detect_users_densehash(nets1, nets2)
    t_calc = time.time() - t_calc
    return check_result, t_read, t_calc


def check_perf():
    N = 10000
    t_total_all = 0
    t_read_all = 0
    t_calc_all = 0
    for i in range(N):
        u1 = random.randint(0, 9)
        u2 = (u1 + 1) % 10
        check_result, t_read, t_calc = check_users(u1, u2)
        t_total = t_read + t_calc
        t_total_all += t_total
        t_read_all += t_read
        t_calc_all += t_calc
    print("Check in {}sec (read: {}, calc: {})"
          .format(t_total_all, t_read_all, t_calc_all))
    print("Check in {}sec (read: {}, calc: {})"
          .format(t_total_all/N, t_read_all/N, t_calc_all/N))

check_perf()