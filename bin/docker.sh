#!/bin/bash
# SPDX-FileCopyrightText: 2022 Michael Erdely <mike@erdelynet.com>
# SPDX-License-Identifier: MIT

# shellcheck disable=SC1091
. "$(dirname "$0")"/common.sh

assertHaveCommand docker
assertHaveCommand bc
assertHaveCommand ip
assertHaveCommand awk

declare -A pids
declare -A time_start
declare -A cpu_start
declare -A rx_start
declare -A tx_start
declare -A br_start
declare -A bw_start

[[ $0 =~ .*_metric.sh ]] && mode=metric

# Either add the splunk user to the docker group or add the following to /etc/sudoers:
#   splunk ALL=(root) NOPASSWD: /usr/bin/docker stats --no-stream --no-trunc --all
#   splunk ALL=(root) NOPASSWD: /usr/bin/docker ps --all --no-trunc --format *
#   splunk ALL=(root) NOPASSWD: /usr/bin/docker inspect -f *

docker_cmd=docker
if [ $(id -u) != 0 ]; then
  ! groups | grep -q "\bdocker\b" && docker_cmd="sudo -n $docker_cmd"
fi
docker_list=$($docker_cmd ps --all --no-trunc --format '{{ .ID }}')

header_string="ContainerId Name CPUPct MemUsage MemTotal MemPct NetRX RXps NetTX TXps BlockRead BRps BlockWrite BWps Pids"
metric_string=""
header_format="%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
string_format="%s\t%s\t%s\t%.2f\t%s\t%s\t%.2f\t%s\t%.2f\t%s\t%.2f\t%s\t%.2f\t%s\t%.2f\t%s\n"
json_format='{ "time": "%s", "ContainerId": "%s", "Name": "%s", "CPUPct": %.2f, "MemUsage": %s, "MemTotal": %s, "MemPct": %.2f, "NetRX": %s, "RXps": %.2f, "NetTX": %s, "TXps": %.2f, "BlockRead": %s, "BRps": %.2f, "BlockWrite": %s, "BWps": %.2f, "Pids": %s }\n'

if [ "$mode" = "metric" ]; then
  metric_name=docker_metric
  if [ ! -f "/etc/os-release" ] ; then
    OSName=$(cat /etc/*release | head -n 1| awk -F" release " '{print $1}'| tr ' ' '_')
    OS_version=$(cat /etc/*release | head -n 1| awk -F" release " '{print $2}' | cut -d\. -f1)
    IP_address=$(ip addr show dev $(ip route show | awk 'BEGIN{m=1000}$1=="default"$0!~/ metric /{print $5;exit}$1=="default"{if($NF<m){m=$NF;i=$5}}END{print i}') | awk '$1=="inet"{print gensub(/\/[0-9]+/,"","g",$2)}')
  else
    OSName=$(cat /etc/*release | grep '\bNAME=' | cut -d\= -f2 | tr ' ' '_' | cut -d\" -f2)
    OS_version=$(cat /etc/*release | grep '\bVERSION_ID=' | cut -d\= -f2 | cut -d\" -f2)
    IP_address=$(ip addr show dev $(ip route show | awk 'BEGIN{m=1000}$1=="default"$0!~/ metric /{print $5;exit}$1=="default"{if($NF<m){m=$NF;i=$5}}END{print i}') | awk '$1=="inet"{print gensub(/\/[0-9]+/,"","g",$2)}')
  fi
  [ -z "$OSName" ] && OSName="?"
  [ $OSName = Arch_Linux ] && OS_version=rolling
  [ -z "$OS_version" ] && OS_version="?"
  header_string="$header_string OSName OS_version IP_address"
  metric_string=" $OSName $OS_version $IP_address"
  header_format="${header_format::-2}\t%s\t%s\t%s\n"
  string_format="${string_format::-2}\t%s\t%s\t%s\n"
  json_format='{ "time": "%s", "ContainerId": "%s", "Name": "%s", "CPUPct": %.2f, "MemUsage": %.2f, "MemTotal": %.2f, "MemPct": %.2f, "NetRX": %.2f, "RXps": %.2f, "NetTX": %.2f, "TXps": %.2f, "BlockRead": %.2f, "BRps": %.2f, "BlockWrite": %.2f, "BWps": %.2f, "Pids": %s, "OSName": "%s", "OS_version": "%s", "IP_address": "%s", "event": "metric" }\n'
fi

# Currently calculates CPU % over time; not right now
for id in $docker_list; do
  [ ! -d /sys/fs/cgroup/system.slice/docker-$id.scope ] && continue
  pids[$id]=$($docker_cmd inspect -f '{{ .State.Pid }}' $id)
  read time_start[$id] _ < /proc/uptime
  read _ cpu_start[$id] < /sys/fs/cgroup/system.slice/docker-$id.scope/cpu.stat
  while read _if _rx _ _ _ _ _ _ _ _tx _ _ _ _ _ _ _ ; do
    [ -z "$_if" ] && continue
    [ -z "$_rx" ] && _rx=0
    [ -z "$_tx" ] && _tx=0
    if=$_if rx_start[$id]=$_rx tx_start[$id]=$_tx
  done < /proc/${pids[$id]}/net/dev
  br_start[$id]=0;bw_start[$id]=0
  while read _ _br _bw _ _ _ _; do
    [ -z "$_br" ] && _br=rbytes=0
    [ -z "$_bw" ] && _bw=wbytes=0
    br_start[$id]=$((${br_start[$id]}+${_br:7}))
    bw_start[$id]=$((${bw_start[$id]}+${_bw:7}))
  done < /sys/fs/cgroup/system.slice/docker-$id.scope/io.stat
done

sleep 2  # Sleep 2 seconds to give the script time to get CPU stats

MemTotal=$(awk '$1=="MemTotal:" {print $2*1024}' /proc/meminfo)
#printf "$header_format" $header_string
for id in $docker_list; do
  name=$($docker_cmd inspect -f '{{ .Name }}' $id)
  if [ ! -d /sys/fs/cgroup/system.slice/docker-$id.scope ]; then
    printf "$json_format" $id ${name:1} 0 0 0 0 0 0 0 0 0 0 0 0 0$metric_string
    continue
  fi
  read cpu_stop _ < /proc/uptime
  read _ proc_stop < /sys/fs/cgroup/system.slice/docker-$id.scope/cpu.stat
  while read _if _rx _ _ _ _ _ _ _ _tx _ _ _ _ _ _ _ ; do
    [ -z "$_if" ] && continue
    [ -z "$_rx" ] && _rx=0
    [ -z "$_tx" ] && _tx=0
    if=$_if NetRX=$_rx NetTX=$_tx
  done < /proc/${pids[$id]}/net/dev
  BlockRead=0;BlockWrite=0
  while read _ _br _bw _ _ _ _; do
    [ -z "$_br" ] && _br=rbytes=0
    [ -z "$_bw" ] && _bw=wbytes=0
    BlockRead=$((BlockRead+${_br:7}))
    BlockWrite=$((BlockWrite+${_bw:7}))
  done < /sys/fs/cgroup/system.slice/docker-$id.scope/io.stat
  read MemUsage < /sys/fs/cgroup/system.slice/docker-$id.scope/memory.current
  read Pids < /sys/fs/cgroup/system.slice/docker-$id.scope/pids.current
  read _ CPU < /sys/fs/cgroup/cpu.stat
  CpuUsage=$(echo "($proc_stop - ${cpu_start[$id]}) / ($cpu_stop * 1000000 - ${time_start[$id]} * 1000000) * 100" | bc -l)
  RXps=$(echo "($NetRX - ${rx_start[$id]}) / ($cpu_stop * 1000000 - ${time_start[$id]} * 1000000) * 100" | bc -l)
  TXps=$(echo "($NetTX - ${tx_start[$id]}) / ($cpu_stop * 1000000 - ${time_start[$id]} * 1000000) * 100" | bc -l)
  BRps=$(echo "($BlockRead - ${br_start[$id]}) / ($cpu_stop * 1000000 - ${time_start[$id]} * 1000000) * 100" | bc -l)
  BWps=$(echo "($BlockWrite - ${bw_start[$id]}) / ($cpu_stop * 1000000 - ${time_start[$id]} * 1000000) * 100" | bc -l)
  printf "$json_format" "$(env TZ=UTC date "+%FT%T.%NZ")" $id ${name:1} $CpuUsage $MemUsage $MemTotal $(echo "$MemUsage*100/$MemTotal"|bc -l) $NetRX $RXps $NetTX $TXps $BlockRead $BRps $BlockWrite $BWps $Pids$metric_string
done
