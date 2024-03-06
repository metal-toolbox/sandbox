#!/bin/sh
#

#incase the crdb pvc is stuck in terminating
# kubectl patch pvc db -p '{"metadata":{"finalizers":null}}'

while kubectl get pods | egrep '(Running|Terminating)'; do
	kubectl get pods
	echo "waiting for pods to terminate..."
	sleep 3
done

echo "All done!"
