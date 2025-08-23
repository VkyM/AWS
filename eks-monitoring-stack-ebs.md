# Setting Up Persistent Prometheus, Grafana, and Loki on EKS with gp3 EBS Storage

This guide explains how to enable persistent storage for **Prometheus**, **Grafana**, and **Loki** on an Amazon EKS cluster using **gp3 EBS volumes**. Each step includes an explanation for beginners.

---

## 1. Create a StorageClass (`gp3-sc.yaml`)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com   # <-- Uses AWS EBS CSI driver
parameters:
  type: gp3
  fsType: ext4
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

### Explanation:

- **StorageClass**: Defines how Kubernetes should provision storage.
- **provisioner**: `ebs.csi.aws.com` tells Kubernetes to use the AWS EBS CSI driver.
- **type**: EBS volume type (`gp3` is performant and cost-efficient).
- **fsType**: Filesystem type for the volume.
- **reclaimPolicy**: `Delete` ensures volumes are deleted when PVCs are removed.
- **volumeBindingMode**: `WaitForFirstConsumer` ensures the volume is created in the same AZ as the pod.
- **allowVolumeExpansion**: Lets you expand the volume later if needed.

Apply it:

```bash
kubectl apply -f gp3-sc.yaml
```

---

## 2. Enable IAM OIDC Provider for EKS

```bash
eksctl utils associate-iam-oidc-provider --region ap-south-1 --cluster dev-cluster --approve
```

### Explanation:

- Enables Kubernetes to use **IAM Roles for Service Accounts (IRSA)**.
- Required for CSI drivers and other AWS services to access AWS resources securely.

---

## 3. Install AWS EBS CSI Driver with IRSA

```bash
aws eks create-addon \
  --cluster-name prod-cluster \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::<ACCOUNT_ID>:role/prod-cluster-ebs-csi-controller-role \
  --region ap-south-1
```

### Explanation:

- Installs the **EBS CSI driver** in your cluster.
- Connects a **Service Account** with an IAM role allowing dynamic volume creation.

---

## 4. Enable Persistence for Prometheus & Grafana

`prometheus.yaml`:

```yaml
grafana:
  persistence:
    enabled: true
    size: 10Gi
    storageClassName: gp3

prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi
```

### Explanation:

- Enables persistent storage for **Grafana, Prometheus, and Alertmanager**.
- Storage is dynamically provisioned using the `gp3` StorageClass.
- `ReadWriteOnce` allows one pod to write to the volume at a time.

Install Prometheus stack:

```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f prometheus.yaml
```

---

## 5. Enable Persistence for Loki

`loki-values.yaml`:

```yaml
loki:
  persistence:
    enabled: true
    storageClassName: gp3
    accessModes:
      - ReadWriteOnce
    size: 25Gi

promtail:
  enabled: true

grafana:
  enabled: false

prometheus:
  enabled: false
```

### Explanation:

- Enables persistent storage for **Loki** logs.
- Disables Grafana and Prometheus from this Helm chart since we already installed them separately.

Install Loki:

```bash
helm install loki grafana/loki-stack \
  -n monitoring \
  -f loki-values.yaml
```

---

## 6. Verify Persistence

Check pods:

```bash
kubectl --namespace monitoring get pods -l "release=monitoring"
```

Describe pod (example for Grafana):

```bash
kubectl describe pod <grafana-pod-name> -n monitoring
```

Check mounted volume:

```bash
kubectl exec -it <grafana-pod-name> -n monitoring -- df -h
```

---

## 7. Access Grafana Locally

```bash
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring" -o name)
kubectl --namespace monitoring port-forward $POD_NAME 3000
```

- Access Grafana: `http://localhost:3000`
- Add **Loki datasource** with URL: `http://loki.monitoring:3100`

> **Note:** If logs or namespaces don’t appear, restart or delete the pod.

---

### Summary:

1. Create a gp3 StorageClass.
2. Associate IAM OIDC provider for IRSA.
3. Install AWS EBS CSI driver.
4. Enable persistence for Prometheus, Grafana, and Alertmanager.
5. Enable persistence for Loki.
6. Verify volumes and pods.
7. Access Grafana and configure Loki datasource.

This guide ensures **all monitoring components in EKS have persistent storage**, so data is not lost if pods restart.

