#!/bin/bash

echo "🧹 LIMPEZA DO CLUSTER MONITORING-NEW"
echo "======================================"

# Conectar ao cluster
echo "📡 Conectando ao monitoring-cluster..."
gcloud container clusters get-credentials monitoring-cluster --zone southamerica-east1 --project datatoopenai

# Deletar recursos desnecessários
echo "🗑️ Deletando Ingress duplicado..."
kubectl delete ingress monitoring-https-ingress -n monitoring-new

echo "🗑️ Deletando certificado duplicado..."
kubectl delete managedcertificate monitoring-https-cert -n monitoring-new

echo "🗑️ Deletando IP não utilizado..."
gcloud compute addresses delete monitoring-https-ip --global --quiet

echo "✅ Limpeza concluída!"
echo ""
echo "📊 STATUS FINAL:"
kubectl get all -n monitoring-new
echo ""
kubectl get ingress -n monitoring-new
echo ""
kubectl get managedcertificate -n monitoring-new
