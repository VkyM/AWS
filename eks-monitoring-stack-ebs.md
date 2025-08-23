# Monitoring Stack Deployment on EKS with Persistent Storage (EBS CSI)

This guide explains how to deploy Prometheus, Grafana, and Loki on an Amazon EKS cluster with persistent storage backed by **Amazon EBS CSI Driver**.

---

## Prerequisites

- A running **EKS cluster** (`dev-cluster` in this example)
- **Helm 3** installed
- **eksctl** and **kubectl** configured
- IAM permissions to create roles and add-ons

---

## Step 1: Install Prometheus & Grafana (kube-prometheus-stack)

```bash
helm install monitoring prometheus-community/kube-prometheus-stack   --namespace monitoring   --create-namespace

# Port-forward Grafana UI
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring" -o name)
kubectl --namespace monitoring port-forward $POD_NAME 3000
```

---

## Step 2: Install Loki + Promtail

```bash
helm install loki grafana/loki-stack   --namespace monitoring   --set grafana.enabled=false   --set prometheus.enabled=false   --set promtail.enabled=true
```

In Grafana, add a **Loki datasource** with URL:

```
http://loki.monitoring:3100
```

---

## Step 3: Create StorageClass for gp3 Volumes

`gp3-sc.yaml`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com   # <-- must be CSI driver
parameters:
  type: gp3
  fsType: ext4
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

Apply it:

```bash
kubectl apply -f gp3-sc.yaml
```

---

## Step 4: Configure IAM OIDC Provider

```bash
eksctl utils associate-iam-oidc-provider   --region ap-south-1   --cluster dev-cluster   --approve
```

Verify IAM identity:

```bash
aws sts get-caller-identity --region ap-south-1
```

Check service account:

```bash
kubectl -n kube-system get sa ebs-csi-controller-sa -o yaml | grep eks.amazonaws.com/role-arn
```

---

## Step 5: Create IAM Service Account for EBS CSI Driver

```bash
eksctl create iamserviceaccount   --cluster dev-cluster   --region ap-south-1   --namespace kube-system   --name ebs-csi-controller-sa   --role-name dev-cluster-ebs-csi-controller-role   --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy   --approve
```

If already installed, update add-on:

```bash
aws eks delete-addon   --cluster-name dev-cluster   --addon-name aws-ebs-csi-driver   --region ap-south-1

aws eks create-addon   --cluster-name dev-cluster   --addon-name aws-ebs-csi-driver   --service-account-role-arn arn:aws:iam::<ACCOUNT_ID>:role/dev-cluster-ebs-csi-controller-role   --region ap-south-1
```

---

## Step 6: Enable Persistence in Prometheus & Grafana

`prometheus.yml`:

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

Upgrade Helm release:

```bash
helm upgrade monitoring prometheus-community/kube-prometheus-stack   --namespace monitoring   -f prometheus.yml
```

---

## Step 7: Enable Persistence in Loki

`loki-values.yml`:

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

Upgrade Helm release:

```bash
helm upgrade loki grafana/loki   --namespace monitoring   -f loki-values.yml
```

---

## Step 8: Verify Persistence

```bash
kubectl --namespace monitoring get pods -l "release=monitoring"
kubectl describe pod <grafana-pod-name> -n monitoring
kubectl exec -it <grafana-pod-name> -n monitoring -- df -h
```

---

## ✅ Summary

- **Prometheus, Grafana, Loki** deployed via Helm
- **Persistent storage** backed by **EBS CSI gp3 volumes**
- **OIDC + IAM role** configured for the EBS CSI driver
- Safe to scale workloads with durable storage

