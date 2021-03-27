from flask import Flask, jsonify
from redis import Redis


REDIS_HOST = 'localhost'
REDIS_PORT = 6379
REDIS_DB = 0
REDIS_KEY = 'nspl'

app = Flask(__name__)
r = Redis(host=REDIS_HOST, port=REDIS_PORT, db=REDIS_DB)


@app.route('/radius/<postcode>/<distance>/<unit>', methods=['GET'])
def radius(postcode, distance, unit):

    try:
        results = r.georadiusbymember(REDIS_KEY,
                                      postcode, distance, unit,
                                      withdist=True)
    except Exception as e:
        results = {}

    return jsonify([{
        'postcode': result[0],
        'distance':result[1]
    } for result in results])


app.run()
