#!/usr/bin/env bash
#
# Sets and removes the k8s coreDNS entry hack that allows us to access buckets via subdomain
#

set -e

MINIO_DNS_REWRITE_RULE="rewrite name bucket1.minio minio.default.svc.cluster.local"

help() {
  echo
  echo "$0"
  echo "Configure the k8s coreDNS server to resolve the minio subdomains to the minio service"
  echo
  echo "Usage:"
  echo "    $0 <OPTION>"
  echo
  echo "Options:"
  echo "    set    Will set the k8s coreDNS configuration to resolve minio subdomains"
  echo "    clear  Will remove the minio specific coreDNS configuration"
  echo
}

resetPods() {
  echo "Restarting coreDNS pods"
  kubectl -n kube-system rollout restart deploy/coredns
  sleep 1
}

clearDNSEntry() {
  echo "Clearing coreDNS configuration entry"
  kubectl -n kube-system get cm coredns -o yaml | grep -v minio | kubectl -n kube-system apply -f -
}

printArray() {
  array=("$1")
  for i in "${array[@]}"
  do
    echo "$i"
  done
}

setDNSEntry() {
  echo "Setting coreDNS configuration entry"
  configmap=()
  while IFS='' read -r line; do configmap+=("$line"); done < <(kubectl -n kube-system get cm coredns -o yaml)

  len=${#configmap[@]}
  for ((i=len; i != 0; i--))
  do
    str="${configmap[((i - 1))]}"

    if echo "$str" | grep -q minio
    then
      echo "Entry already set"
      exit 0
    fi

    if [[ "$str" =~ ^\ +ready$ ]]
    then
      found="true"
      configmap[$i]="$(echo -ne "$str" | sed "s/ready/${MINIO_DNS_REWRITE_RULE}/g")"
      break
    fi

    configmap[$i]="$str"
  done

  if [ -z "$found" ]
  then
    echo "Failed to set DNS entry"
    exit 2
  fi

  kubectl -n kube-system apply -f - < <(for i in "${configmap[@]}"; do echo "$i"; done)
}

case $1 in
clear)
  clearDNSEntry
  resetPods
  ;;
set)
  setDNSEntry
  resetPods
  ;;
*)
  [ "$1" ] && echo "Unsupported option: $1"
  help
  exit 1
  ;;
esac

echo "Done"
