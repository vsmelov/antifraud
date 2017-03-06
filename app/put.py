# coding: utf-8

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


def put():
    users = mdb['users']
    N = 10000
    N_NETS = 3000
    for i in range(N):
        subnets = bytes(random.randrange(256) for i in range(3*N_NETS))
        dat = {"user": random.randrange(10),
               "subnets": Binary(subnets)}
        _id = users.insert_one(dat).inserted_id
        print('_id: {}'.format(_id))
    return "Added {N} records with 10000 nets"

put()