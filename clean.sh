#!/bin/bash
# // Copyright (c) Microsoft Corporation.
# // Licensed under the MIT license.
sudo rm -rf /home/$(whoami)/monitofi
docker stop influxdb-grafana
docker rm influxdb-grafana
docker stop monitofi1
docker rm monitofi1