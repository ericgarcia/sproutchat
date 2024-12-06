### Step-by-Step Guide

1. **Set Up Kubernetes Cluster**: Ensure you have a Kubernetes cluster set up with GPU nodes.
2. **Install Ray on Kubernetes**: Use Ray's Kubernetes operator to manage Ray clusters.
3. **Create Ray Cluster Configuration**: Define the Ray cluster configuration with two GPU nodes.
4. **Create Command-Line Script**: Create a script to manage the Ray cluster and run the inference.

### Step 1: Set Up Kubernetes Cluster

Ensure you have a Kubernetes cluster with GPU nodes. You can use a managed Kubernetes service like Google Kubernetes Engine (GKE), Amazon EKS, or Azure AKS, or set up your own cluster.

### Step 2: Install Ray on Kubernetes

Install the Ray Kubernetes operator to manage Ray clusters on Kubernetes.

#### Install Ray Kubernetes Operator

```sh
kubectl apply -k "github.com/ray-project/kuberay/ray-operator/config/default"
```

### Step 3: Create Ray Cluster Configuration

Create a Ray cluster configuration file (

ray-cluster.yaml

) with two GPU nodes.

#### 

ray-cluster.yaml



```yaml
apiVersion: ray.io/v1alpha1
kind: RayCluster
metadata:
  name: ray-cluster
spec:
  rayVersion: "2.0.0"
  headGroupSpec:
    serviceType: ClusterIP
    replicas: 1
    rayStartParams:
      dashboard-host: "0.0.0.0"
    template:
      spec:
        containers:
        - name: ray-head
          image: rayproject/ray:latest
          resources:
            limits:
              nvidia.com/gpu: 1
          ports:
          - containerPort: 6379  # Redis port
          - containerPort: 8265  # Dashboard port
          - containerPort: 10001 # Ray internal port
  workerGroupSpecs:
  - groupName: worker-group
    replicas: 2
    rayStartParams: {}
    template:
      spec:
        containers:
        - name: ray-worker
          image: rayproject/ray:latest
          resources:
            limits:
              nvidia.com/gpu: 1
```

### Step 4: Create Command-Line Script

Create a script (`manage_ray_cluster.sh`) to manage the Ray cluster and run the inference.

#### `manage_ray_cluster.sh`

```bash
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
```

### Explanation

1. **Ray Cluster Configuration**: The 

ray-cluster.yaml

 file defines a Ray cluster with one head node and two worker nodes, each with one GPU.
2. **Command-Line Script**: The `manage_ray_cluster.sh` script manages the Ray cluster:
   - `start`: Starts the Ray cluster.
   - `run`: Runs the inference script on the Ray cluster.
   - `stop`: Stops the Ray cluster.

### Running the Script

1. **Start the Cluster**:

```sh
./manage_ray_cluster.sh start
```

2. **Run the Inference**:

```sh
./manage_ray_cluster.sh run
```

3. **Stop the Cluster**:

```sh
./manage_ray_cluster.sh stop
```

By following these steps, you can set up a Kubernetes cluster with Ray, run your model inference, and manage the cluster lifecycle using a command-line script.

ericgarcia: why am I getting this error?
```
kubectl apply -k "github.com/ray-project/kuberay/ray-operator/config/default"
error: error validating "github.com/ray-project/kuberay/ray-operator/config/default": error validating data: failed to download openapi: Get "http://localhost:8080/openapi/v2?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused; if you choose to ignore these errors, turn validation off with --validate=false
```

GitHub Copilot: The error you're encountering indicates that `kubectl` is unable to connect to the Kubernetes API server running on `localhost:8080`. This typically happens if your `kubectl` context is not set correctly or if the Kubernetes cluster is not running.

### Step-by-Step Guide to Resolve the Issue

1. **Ensure Kubernetes Cluster is Running**: Make sure your Kubernetes cluster is up and running.
2. **Set the Correct `kubectl` Context**: Ensure that `kubectl` is configured to use the correct context for your Kubernetes cluster.
3. **Apply the Ray Kubernetes Operator**: Use the correct command to apply the Ray Kubernetes operator.

### Step 1: Ensure Kubernetes Cluster is Running

Make sure your Kubernetes cluster is up and running. If you are using a managed Kubernetes service like GKE, EKS, or AKS, ensure that the cluster is active.

### Step 2: Set the Correct `kubectl` Context

Ensure that `kubectl` is configured to use the correct context for your Kubernetes cluster. You can check the current context with the following command:

```sh
kubectl config current-context
```

If the context is not set correctly, you can switch to the correct context using:

```sh
kubectl config use-context <your-context-name>
```

### Step 3: Apply the Ray Kubernetes Operator

Use the correct command to apply the Ray Kubernetes operator. If you encounter validation issues, you can bypass validation using the `--validate=false` flag.

#### Apply the Ray Kubernetes Operator

```sh
kubectl apply -k "github.com/ray-project/kuberay/ray-operator/config/default" --validate=false
```

### Example Commands

1. **Check Current Context**:

```sh
kubectl config current-context
```

2. **Switch Context**:

```sh
kubectl config use-context <your-context-name>
```

3. **Apply Ray Kubernetes Operator**:

```sh
kubectl apply -k "github.com/ray-project/kuberay/ray-operator/config/default" --validate=false
```

### Additional Troubleshooting

If you are still encountering issues, you can try the following:

1. **Check Cluster Status**:

```sh
kubectl cluster-info
```

2. **Check Nodes**:

```sh
kubectl get nodes
```

3. **Check Pods**:

```sh
kubectl get pods --all-namespaces
```

By ensuring that your Kubernetes cluster is running and `kubectl` is configured correctly, you should be able to apply the Ray Kubernetes operator without encountering connection issues.