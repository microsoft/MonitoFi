## Azure AppInsights/Log Analytics KustoQueryLanguage Queries
 These Queries can be used to plot various timecharts in a Log Analytics Workspace. AI Dashboard inside Grafana supports Kusto Query Language when using Azure Monitor as a datasource.
 
### ActiveThread Counts
traces
| where client_OS == "#35~18.04.1-Ubuntu SMP Mon Jul 13 12:54:45 UTC 2020"
| where parse_json(message).message == "flow/status"
| extend activeThreadCount_ = tostring(parse_json(tostring(parse_json(message).controllerStatus)).activeThreadCount)
| summarize ActiveThreads=sum(toint(activeThreadCount_)) by bin(timestamp,5m)
| render timechart 

### ConnectedNodes Info
traces
| where client_OS == "#35~18.04.1-Ubuntu SMP Mon Jul 13 12:54:45 UTC 2020"
| where parse_json(message).message == "flow/cluster/summary"
| extend connectedNodeCount_ = toint(parse_json(tostring(parse_json(message).clusterSummary)).connectedNodeCount)
| extend totalNodeCount_ = toint(parse_json(tostring(parse_json(message).clusterSummary)).totalNodeCount)
| summarize by connectedNodeCount_,totalNodeCount_,bin(timestamp,1h)
| render timechart 

### Total KBs Queued
traces
| where client_OS == "#35~18.04.1-Ubuntu SMP Mon Jul 13 12:54:45 UTC 2020"
| where parse_json(message).message == "flow/status"
| extend bytesQueued_ = tostring(parse_json(tostring(parse_json(message).controllerStatus)).bytesQueued)
| summarize KBQueued=sum(toint(bytesQueued_)/1024) by bin(timestamp,5m)
| render timechart 

### Heap Utilisation %
traces
| where client_OS == "#35~18.04.1-Ubuntu SMP Mon Jul 13 12:54:45 UTC 2020"
| where parse_json(message).message == "system-diagnostics?nodewise=true"
| extend heapUtilization_ = todouble(substring(tostring(parse_json(tostring(parse_json(tostring(parse_json(message).systemDiagnostics)).aggregateSnapshot)).heapUtilization),0,4))
| summarize avg(heapUtilization_) by bin(timestamp,5m)
| render timechart

### Flow Files In Queue
traces
| where client_OS == "#35~18.04.1-Ubuntu SMP Mon Jul 13 12:54:45 UTC 2020"
| where parse_json(message).message == "flow/status"
| extend flowFilesQueued_ = tostring(parse_json(tostring(parse_json(message).controllerStatus)).flowFilesQueued)
| summarize sum(toint(flowFilesQueued_)) by bin(timestamp,5m)
| render timechart 

### Flow Files Processed
traces
| where client_OS == "#35~18.04.1-Ubuntu SMP Mon Jul 13 12:54:45 UTC 2020"
| where parse_json(message).message == "flow/process-groups/root"
| extend flowFilesOut_ = tostring(parse_json(tostring(parse_json(tostring(parse_json(tostring(parse_json(tostring(parse_json(tostring(parse_json(message).processGroupFlow)).flow)).connections))[0].status)).aggregateSnapshot)).flowFilesOut)
| summarize sum(toint(flowFilesOut_)) by bin(timestamp,5m)
| render timechart 

### Flow Files In
traces
| where client_OS == "#35~18.04.1-Ubuntu SMP Mon Jul 13 12:54:45 UTC 2020"
| where parse_json(message).message == "flow/process-groups/root"
| extend flowFilesIn_ = tostring(parse_json(tostring(parse_json(tostring(parse_json(tostring(parse_json(tostring(parse_json(tostring(parse_json(message).processGroupFlow)).flow)).connections))[0].status)).aggregateSnapshot)).flowFilesIn)
| summarize sum(toint(flowFilesIn_)) by bin(timestamp,5m)
| render timechart 

### Running,Stopped,Disabled Count
traces
| where client_OS == "#35~18.04.1-Ubuntu SMP Mon Jul 13 12:54:45 UTC 2020"
| where parse_json(message).message == "flow/status"
| extend disabledCount_ = toint(parse_json(tostring(parse_json(message).controllerStatus)).disabledCount)
| extend runningCount_ = toint(parse_json(tostring(parse_json(message).controllerStatus)).runningCount)
| extend syncFailureCount_ = toint(parse_json(tostring(parse_json(message).controllerStatus)).syncFailureCount)
| extend stoppedCount_ = toint(parse_json(tostring(parse_json(message).controllerStatus)).stoppedCount)
| summarize by runningCount_,stoppedCount_,syncFailureCount_,disabledCount_,bin(timestamp,5m)
| render timechart

### Used Space & Total Space
traces
| where client_OS == "#35~18.04.1-Ubuntu SMP Mon Jul 13 12:54:45 UTC 2020"
| where parse_json(message).message == "system-diagnostics?nodewise=true"
| extend usedSpace_ = todouble(split(tostring(parse_json(tostring(parse_json(tostring(parse_json(tostring(parse_json(message).systemDiagnostics)).aggregateSnapshot)).flowFileRepositoryStorageUsage)).usedSpace)," ")[0])
| extend totalSpace_ = (todouble(split(tostring(parse_json(tostring(parse_json(tostring(parse_json(tostring(parse_json(message).systemDiagnostics)).aggregateSnapshot)).flowFileRepositoryStorageUsage)).totalSpace)," ")[0])*1024)
| summarize avg(usedSpace_) by totalSpace_,bin(timestamp,5m)
| render timechart

### Endpoint Types
traces
| where client_OS == "#35~18.04.1-Ubuntu SMP Mon Jul 13 12:54:45 UTC 2020"
| extend message_ = tostring(parse_json(message).message)
| summarize count() by message_