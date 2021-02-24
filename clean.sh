#!/bin/bash
# // Copyright (c) Microsoft Corporation.
# // Licensed under the MIT license.
sudo rm -rf /home/$(whoami)/nifimonitor
docker stop influxdb-grafana
docker rm influxdb-grafana
docker stop mifi1
docker rm mifi1