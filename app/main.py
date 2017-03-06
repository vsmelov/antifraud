from flask import Flask
from pymongo import MongoClient
from bson.binary import Binary
from safe_db_proxy import SafeMongoProxy
import random
from cy.make_set_cython import detect_users_densehash
import time

app = Flask(__name__)
app._mongo_client = MongoClient('some-mongo', 27017, connect=False)
app.mongo_client = SafeMongoProxy(app._mongo_client, n_tries=3)
app.mdb = app.mongo_client['some-db']


@app.route("/")
def hello():
    return "Hello World"


def check_users(u1, u2):
    users = app.mdb['users']
    t_read = time.time()
    nets1 = users.find_one({"user": u1})['subnets']
    nets2 = users.find_one({"user": u2})['subnets']
    t_read = time.time() - t_read

    t_calc = time.time()
    check_result = detect_users_densehash(nets1, nets2)
    t_calc = time.time() - t_calc
    return check_result, t_read, t_calc


@app.route("/check/")
def check():
    check_result, t_read, t_calc = check_users(1, 2)
    t_total = t_read + t_calc
    return "Check result: {} in {}sec (read: {}, calc: {})"\
        .format(check_result, t_total, t_read, t_calc)


@app.route("/put/")
def put():
    users = app.mdb['users']
    N = 100000
    N_NETS = 3000
    for i in range(N):
        subnets = bytes(random.randrange(256) for i in range(3*N_NETS))
        dat = {"user": random.randrange(10),
               "subnets": Binary(subnets)}
        _id = users.insert_one(dat).inserted_id
        print('_id: {}'.format(_id))
    return "Added {N} records with 10000 nets"


if __name__ == "__main__":
    app.run(host='0.0.0.0', debug=True, port=80)
