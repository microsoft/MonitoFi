# MiFi : A Monitoring Tool for NiFi

  One Place for monitoring Health and Performance of your NiFi Cluster!

  MiFi runs as an external program to NiFi Cluster and monitors the health and performance of the cluster using Data polled using Apache NiFi-API.
  MiFi container can be deployed anywhere as long as it is able to access the NiFi Cluster (in same vnet or publicly exposed NiFi Cluster).
  
  There are 2 configurations in which this application can be deployed. 
  One is storing data on prem and another is in Azure Application Insights.
  
  On premises :
  MiFi uses InfluxDB for storing the monitoring data locally and uses Grafana to plot various Graphs in Dashboards & Send Timely Alerts incase anomalies are detected.

  Application Insights: Using a Simple Instrumentation Key Received when creating an Application Insights Resource in Azure, all the NiFi monitoring data can be pushed to Azure. Using Grafana & AIDashboard various graphs are plotted using Kusto Query Language.

  Visit https://github.com/tushardhadiwal/docker-influxdb-grafana for Grafana And InfludDB Support.

## Architecture

![](./Docs/NiFiMonitorArch400ppi.png)

#### Quick Start

To run NiFi Monitor along with InfluxDb & Grafana:

```sh
docker network create mifinet
```

```sh
docker run -d \
  --name influxdb-grafana \
  --network=mifinet \
  -p 3003:3003 \
  -p 3004:8083 \
  -p 8086:8086 \
  -v /home/centos/nifimonitor/influx:/var/lib/influxdb \
  -v /home/centos/nifimonitor/grafana:/var/lib/grafana \
  dtushar/docker-influxdb-grafana:latest
```

```sh
docker run \
--name=mifi \
--network=mifinet \
-d \
-e INFLUXDB_SERVER="influxdb-grafana" \
-e ENDPOINT_LIST="controller/cluster,flow/cluster/summary,flow/process-groups/root,flow/status,counters,system-diagnostics" \
-e SLEEP_INTERVAL=300 \
-e API_URL='http://10.251.0.8:8080/nifi-api/' \
-e SECURE=True \
-v $(pwd)/keystore.pkcs12:/opt/nifimonitor/cert.pkcs12 \
-e CERT_PASS="PasswordForCertificate" \
-e IKEY="Optional AppInsights Instrumentation Key" \ 
--add-host <URL_Of_NiFi_Cluster>:<Public_IP_of_Cluster> \
--restart unless-stopped \
dtushar/mifi:1.0
```

Now Visit http://localhost:3003 Login to Grafana with root & root as default username & password.  Add datasources for InfluxDB,InfluxDB-Flux & Azure Monitor. Import Dashboards available in this repository to Grafana. You may need to slightly modify the queries to adjust to number of nodes in your Apache NiFi cluster.
Configure alerts as Needed. Microsoft Teams alerts are tested.

To run NiFi Monitor along with InfluxDb & Grafana & Push Monitoring Data to Application Insights, Please create a Application Insights Resource, and provide the Instrumentation Key while running the container. An Azure Log Analytics Dashboard can be created using similar KQL Queries and Using Grafana can be skipped if desired.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
