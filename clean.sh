#!/bin/bash

sudo rm -rf /home/$(whoami)/nifimonitor
docker stop influxdb-grafana
docker rm influxdb-grafana
docker stop mifi1
docker rm mifi1