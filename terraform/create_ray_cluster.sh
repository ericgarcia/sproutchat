kubectl apply -f -
apiVersion: ray.io/v1alpha1
kind: RayCluster
metadata:
  name: ray-cluster
  namespace: ray-system
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