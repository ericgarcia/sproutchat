#!/bin/bash

COMMAND=$1

start_cluster() {
    echo "Starting Ray cluster..."
    kubectl apply -f ray-cluster.yaml
    echo "Waiting for Ray cluster to be ready..."
    kubectl wait --for=condition=Ready pod -l ray.io/node-type=head --timeout=300s
    echo "Ray cluster started."
}

run_inference() {
    echo "Running inference..."
    kubectl cp ray_inference.py $(kubectl get pod -l ray.io/node-type=head -o jsonpath='{.items[0].metadata.name}'):/root/ray_inference.py
    kubectl exec -it $(kubectl get pod -l ray.io/node-type=head -o jsonpath='{.items[0].metadata.name}') -- python /root/ray_inference.py
}

stop_cluster() {
    echo "Stopping Ray cluster..."
    kubectl delete -f ray-cluster.yaml
    echo "Ray cluster stopped."
}

case $COMMAND in
    start)
        start_cluster
        ;;
    run)
        run_inference
        ;;
    stop)
        stop_cluster
        ;;
    *)
        echo "Usage: $0 {start|run|stop}"
        exit 1
        ;;
esac