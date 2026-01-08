# Backup Antes de Aplicar SSL
Data: 2025-12-01 10:14:06
Namespace: n8n
Cluster: gke_datatoopenai_southamerica-east1-a_n8n-cluster

## Arquivos de Backup:
- n8n-deployment.yaml - Deployment principal do n8n
- n8n-worker-deployment.yaml - Deployment dos workers

## Como Restaurar:

### Restaurar deployment n8n:
kubectl apply -f exports/backup-before-ssl-20251201-101500/n8n-deployment.yaml

### Restaurar deployment n8n-worker:
kubectl apply -f exports/backup-before-ssl-20251201-101500/n8n-worker-deployment.yaml

## Rollback Rápido:
kubectl rollout undo deployment/n8n -n n8n
kubectl rollout undo deployment/n8n-worker -n n8n
