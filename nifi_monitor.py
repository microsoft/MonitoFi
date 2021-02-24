# // Copyright (c) Microsoft Corporation.
# // Licensed under the MIT license.
import logging
import time
import sys
import os
import urllib3
import requests
import json
import json_log_formatter
from requests_pkcs12 import get, post
from applicationinsights.logging import LoggingHandler
from applicationinsights.exceptions import enable
from influxdb import InfluxDBClient
from datetime import datetime

API_URL = os.getenv('API_URL', "http://localhost:8080/nifi-api/")  # complete api-endpoint
ENDPOINT_LIST = os.getenv('ENDPOINT_LIST', "controller/cluster,flow/cluster/summary,flow/process-groups/root,flow/status,counters,system-diagnostics?nodewise=true").split(',')
MODE = os.getenv('MODE', "unlimited")  # In limited mode, only NUMBEROFITERATIONS API calls are made before exiting.
NUMBER_OF_ITERATIONS = int(os.getenv('NUMBER_OF_ITERATIONS', 2))
IKEY = os.getenv('IKEY', "REPLACE_ME")
SLEEP_INTERVAL = int(os.getenv('SLEEP_INTERVAL', 300))

SECURE = os.getenv('SECURE', False)  # Is NiFi Cluster Secure
CERT_FILE = os.getenv('CERT_FILE', '/opt/nifimonitor/cert.pkcs12')
CERT_PASS = os.getenv('CERT_PASS', 'REPLACE_ME')

INFLUXDB_SERVER = os.getenv('INFLUXDB_SERVER', "127.0.0.1") # IP or hostname to InfluxDB server
INFLUXDB_PORT = int(os.getenv('INFLUXDB_PORT', 8086)) # Port on InfluxDB server
INFLUXDB_USERNAME = os.getenv('INFLUXDB_USERNAME', "root")
INFLUXDB_PASSWORD = os.getenv('INFLUXDB_PASSWORD', "root")
INFLUXDB_DATABASE = os.getenv('INFLUXDB_DATABASE', "nifi")

count = 0
urllib3.disable_warnings()
conditions = {
    "limited": lambda: count < NUMBER_OF_ITERATIONS,
    "unlimited": lambda: True
    }

# Sysout Logging Setup
logger = logging.getLogger("nifi-monitor")
logger.setLevel(logging.INFO)
syshandler = logging.StreamHandler(sys.stdout)
syshandler.setLevel(logging.INFO)
formatter = json_log_formatter.JSONFormatter()
syshandler.setFormatter(formatter)
logger.addHandler(syshandler)

if IKEY != "REPLACE_ME":
    # Logging unhandled exceptions with Appinsights
    enable(IKEY)
    # Applications Insights Logging Setup
    handler = LoggingHandler(IKEY)
    handler.setFormatter(formatter)
    logger.addHandler(handler)

iclient = InfluxDBClient(INFLUXDB_SERVER, INFLUXDB_PORT, INFLUXDB_USERNAME, INFLUXDB_PASSWORD, INFLUXDB_DATABASE)
iclient.create_database(INFLUXDB_DATABASE) 

def flattening(nested, prefix, ignore_list):
    field = {}

    flatten(True, nested, field, prefix, ignore_list)

    return field


def flatten(top, nested, flatdict, prefix, ignore_list):
    def assign(newKey, data, toignore):
        if toignore:
            if isinstance(data, (dict, list, tuple,)):
                json_data = json.dumps(data)
                flatdict[newKey] = json_data
            else:
                flatdict[newKey] = data
        else:
            if isinstance(data, (dict, list, tuple,)):
                flatten(False, data, flatdict, newKey, ignore_list)
            else:
                flatdict[newKey] = data

    if isinstance(nested, dict):
        for key, value in nested.items():
            ok = match_key(ignore_list, key)
            if ok and prefix == "":
                assign(key, value, True)
            elif ok and prefix != "":
                newKey = create_key(top, prefix, key)
                assign(newKey, value, True)
            else:
                newKey = create_key(top, prefix, key)
                assign(newKey, value, False)

    elif isinstance(nested, (list, tuple,)):
        for index, value in enumerate(nested):
            if isinstance(value, dict):
                for key1, value1 in value.items():
                    ok = match_key(ignore_list, key1)
                    if ok:
                        subkey = str(index) + "." + key1
                        newkey = create_key(top, prefix, subkey)
                        assign(newkey, value1, True)
                    else:
                        newkey = create_key(top, prefix, str(index))
                        assign(newkey, value, False)

            else:
                newkey = create_key(top, prefix, str(index))
                assign(newkey, value, False)

    else:
        return ("Not a Valid input")


def create_key(top, prefix, subkey):
    key = prefix
    if top:
        key += subkey
    else:
        key += "." + subkey

    return key


def match_key(ignorelist, value):
    for element in ignorelist:
        if element == value:
            return True

    return False


while conditions[MODE]():
    try:
        for ENDPOINT in ENDPOINT_LIST:
            r = requests.get(url=API_URL + ENDPOINT) if SECURE == False else get(url=API_URL + ENDPOINT, headers={
                'Content-Type': 'application/json'}, verify=False, pkcs12_filename=CERT_FILE, pkcs12_password=CERT_PASS)
            received_response = r.json()
            flat_response = flattening(received_response, "", [])
            current_time = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
            points = [{
            "measurement": ENDPOINT,
            "tags": {},
            "time": current_time,
            "fields": flat_response 
            }]
            logger.info(ENDPOINT, extra=received_response)
            iclient.write_points(points)
        if IKEY != "REPLACE_ME":
            handler.flush()
        count += 1
    except Exception as e:
        # this will send an exception to the Application Insights Logs
        logging.exception("Code ran into an unforseen exception!", sys.exc_info()[0])

    time.sleep(SLEEP_INTERVAL)

# logging shutdown will cause a flush of all un-sent telemetry items
logging.shutdown()

