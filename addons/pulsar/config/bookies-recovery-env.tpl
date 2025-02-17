httpServerEnabled: "true"
httpServerPort: "8000"
prometheusStatsHttpPort: "8000"
useHostNameAsBookieID: "true"
# how long to wait, in seconds, before starting autorecovery of a lost bookie.
# TODO: set to 0 after opsRequest for rollingUpdate supports hooks
lostBookieRecoveryDelay: "300"
PULSAR_GC: -XX:+UseG1GC -XX:MaxGCPauseMillis=10 -XX:+ParallelRefProcEnabled -XX:+UnlockExperimentalVMOptions -XX:+DoEscapeAnalysis -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -XX:G1NewSizePercent=50 -XX:+DisableExplicitGC -XX:-ResizePLAB -XX:+ExitOnOutOfMemoryError -XX:+PerfDisableSharedMem -Xlog:gc* -Xlog:gc::utctime -Xlog:safepoint -Xlog:gc+heap=trace -verbosegc
{{- $MaxDirectMemorySize := "" }}
{{- $phy_memory := getContainerMemory ( index $.podSpec.containers 0 ) }}
{{- if gt $phy_memory 0 }}
  {{- $MaxDirectMemorySize = printf "-XX:MaxDirectMemorySize=%dm" (div $phy_memory ( mul 1024 1024 2 )) }}
{{- end }}
PULSAR_MEM: -XX:MinRAMPercentage=25 -XX:MaxRAMPercentage=50 {{ $MaxDirectMemorySize }}

{{- $clusterName := $.cluster.metadata.name }}
{{- $namespace := $.cluster.metadata.namespace }}
{{- $pulsar_zk_from_service_ref := fromJson "{}" }}
{{- $pulsar_zk_from_component := fromJson "{}" }}

{{- if index $.component "serviceReferences" }}
  {{- range $i, $e := $.component.serviceReferences }}
    {{- if eq $i "pulsarZookeeper" }}
      {{- $pulsar_zk_from_service_ref = $e }}
      {{- break }}
    {{- end }}
  {{- end }}
{{- end }}
{{- range $i, $e := $.cluster.spec.componentSpecs }}
  {{- if index $e "componentDef" }}
    {{- if eq $e.componentDef "zookeeper" }}
      {{- $pulsar_zk_from_component = $e }}
    {{- end }}
  {{- end }}
{{- end }}

# Try to get zookeeper from service reference first, if zookeeper service reference is empty, get default zookeeper componentDef in ClusterDefinition
{{- $zk_server := "" }}
{{- if $pulsar_zk_from_service_ref }}
  {{- if index $pulsar_zk_from_service_ref.spec "endpoint" }}
     {{- $zk_server = $pulsar_zk_from_service_ref.spec.endpoint.value }}
  {{- else }}
     {{- $zk_server = printf "%s-zookeeper.%s.svc:2181" $clusterName $namespace }}
  {{- end }}
{{- else }}
  {{- $zk_server = printf "%s-zookeeper.%s.svc:2181" $clusterName $namespace }}
{{- end }}
zkServers: {{ $zk_server }}
