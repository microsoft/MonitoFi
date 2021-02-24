#!/bin/bash
# set +x
# // Copyright (c) Microsoft Corporation.
# // Licensed under the MIT license.
NiFi_API_URL='http://localhost:8080/nifi-api/'
USE_AZURE=false
USE_TEAMS=false
AppInsights_InstrumentationKey="dhjfbjsbsjk-sdbfhjas-random-guid" #"Please Replace with Azure AppInsights Instrumentation Key"
GRAFANA_USERNAME=root
GRAFANA_PASSWORD=root

if [ -x "$(command -v docker)" ]; then
    echo "Checking Prerequisites.... : Docker is Installed"
else
    echo "Installing docker"
    sudo apt-get update
    sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    jq \
    software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $(whoami)
fi

if [ -x "$(command -v jq)" ]; then
    echo "Checking Prerequisites.... : Jq is Installed"
else
    echo "Installing Jq"
    sudo apt-get update
    sudo apt-get install -y jq
fi

#Create Folders for Grafana & Influxdb
echo "Creating necessary volumes for Grafana and InfluxDB..."
mkdir -p /home/$(whoami)/nifimonitor/{influx,grafana}

#Run Grafana & InfluxDB Container
#Note in below command since host netowrking is used, -p flags are ignored. They are kept there to show user which ports are running applications. User can access them with localhost:PORT on host machine directly.
echo "Launching InfluxDB & Grafana Container"
docker run -d   --name influxdb-grafana   --network=host   -p 3003:3003   -p 3004:8083   -p 8086:8086   -v /home/$(whoami)/nifimonitor/influx:/var/lib/influxdb   -v /home/$(whoami)/nifimonitor/grafana:/var/lib/grafana   dtushar/docker-influxdb-grafana:latest

#This Is necessary to provide enough time to Grafana to spin up before making API Calls.
sleep 30

if [ "$USE_AZURE" = true ] ; then
    echo "Adding AzureMonitor Datasource to Grafana"
    #Add AzureMonitor Datasource
    curl -X "POST" "http://localhost:3003/api/datasources"     -H "Content-Type: application/json"      --user $GRAFANA_USERNAME:$GRAFANA_PASSWORD    --data-binary @Grafana/Datasources/azuremonitor.json | jq
fi

echo "Adding InfluxDB with InfluxQL Datasource to Grafana"
#Adding InfluxDB with InfluxQL DataSource
curl -X "POST" "http://localhost:3003/api/datasources"     -H "Content-Type: application/json"      --user $GRAFANA_USERNAME:$GRAFANA_PASSWORD      --data-binary @Grafana/Datasources/influxql.json | jq

echo "Adding InfluxDB with FluxQL Datasource to Grafana"
#Adding InfluxDb with FluxQL Datasource
curl -X "POST" "http://localhost:3003/api/datasources"     -H "Content-Type: application/json"      --user $GRAFANA_USERNAME:$GRAFANA_PASSWORD      --data-binary @Grafana/Datasources/influxflux.json | jq


if [ "$USE_TEAMS" = true ] ; then
    echo "Adding Microsft Teams Alerts - Notification channel. to Grafana"
    #Add Microsft Teams Alerts - Notification channel.
    curl -X "POST" "http://localhost:3003/api/alert-notifications"     -H "Content-Type: application/json"      --user $GRAFANA_USERNAME:$GRAFANA_PASSWORD    --data-binary @Grafana/NotificationChannels/MicrosoftTeams.json | jq
fi


if [ "$USE_AZURE" = true ] ; then
    #Run NiFi Monitor container
    echo "Running MiFi 1.0 Container with Azure AppInsights & InfluxDB Enabled..."
    echo "Please Make sure to add Instrumentation Key for your Application Insights Resource in the IKEY Variable"
    docker run --name=mifi1 --network=host -d -e INFLUXDB_SERVER="localhost" -e ENDPOINT_LIST="controller/cluster,flow/cluster/summary,flow/process-groups/root,flow/status,counters,system-diagnostics,system-diagnostics?nodewise=true" -e SLEEP_INTERVAL=300 -e API_URL=$NiFi_API_URL -e IKEY=$AppInsights_InstrumentationKey --restart unless-stopped dtushar/mifi:1.0
elif [ "$USE_AZURE" = false ] ; then
    #Run NiFi Monitor container
    echo "Running MiFi 1.0 Container..."
    docker run --name=mifi1 --network=host -d -e INFLUXDB_SERVER="localhost" -e ENDPOINT_LIST="controller/cluster,flow/cluster/summary,flow/process-groups/root,flow/status,counters,system-diagnostics,system-diagnostics?nodewise=true" -e SLEEP_INTERVAL=300 -e API_URL=$NiFi_API_URL --restart unless-stopped dtushar/mifi:1.0
fi

echo "Importing NiFi Monitor Dashboard to Grafana"
#Please Adjust the queries according to number of nodes in your NiFi cluster after deployment.
#Adding Dashboard For NiFI Monitor
curl -X "POST" "http://localhost:3003/api/dashboards/db"     -H "Content-Type: application/json"      --user $GRAFANA_USERNAME:$GRAFANA_PASSWORD   --data-binary @Grafana/Dashboards/NiFiMonitorDashboard.json | jq

if [ "$USE_AZURE" = true ] ; then
    echo "Importing Azure Application Insights Dashboard to Grafana"
    #Creating App Registration for use with Azure Monitor & Client Secret And API Key for App Insights is needed.
    #Please refer to following links and populate correct IDs in GrafanaDashboards/AIDashboard.json file
    # https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal
    # https://dev.applicationinsights.io/quickstart/
    #Adding Dashboard For Application Insights
    curl -X "POST" "http://localhost:3003/api/dashboards/db"     -H "Content-Type: application/json"      --user $GRAFANA_USERNAME:$GRAFANA_PASSWORD    --data-binary @Grafana/Dashboards/AIDashboard.json | jq
fi
