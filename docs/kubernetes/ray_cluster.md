The error you're encountering indicates that the Kubernetes API server is not accessible at `localhost:8080`. This typically happens if your `kubectl` context is not correctly configured or if the Kubernetes cluster is not running.

1. **Ensure Kubernetes Cluster is Running**:
   ```bash
   aws eks describe-cluster --name ray-cluster --region us-east-1
   ```

2. **Configure kubectl Context**:
   ```bash
   aws eks update-kubeconfig --name ray-cluster --region us-east-1
   ```

3. **Verify kubectl Context**:
   ```bash
   kubectl config current-context
   ```

4. **Apply the YAML File**:
   ```bash
   kubectl apply -f ray-cluster.yaml
   ```

   If validation errors occur:
   ```bash
   kubectl apply -f ray-cluster.yaml --validate=false
   ```

By following these steps, you should be able to resolve the connection issue and successfully apply the 

ray-cluster.yaml

 file to your Kubernetes cluster.