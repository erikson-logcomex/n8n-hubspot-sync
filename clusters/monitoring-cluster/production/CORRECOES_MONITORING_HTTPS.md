# Correções do Cluster de Monitoring HTTPS

## Problemas Identificados

### 1. **Conflito de Configurações HTTPS**
- Múltiplas configurações HTTPS conflitantes
- Domínios inconsistentes entre arquivos
- Certificados duplicados

### 2. **Configuração de Serviços Inadequada**
- Serviços configurados como `LoadBalancer` em vez de `ClusterIP`
- Conflito com configuração de Ingress

### 3. **Inconsistência nos Domínios**
- Diferentes IPs nos arquivos de configuração
- Certificados não alinhados com os domínios

## Soluções Aplicadas

### 1. **Configuração HTTPS Unificada**
- Arquivo único: `monitoring-https-fixed.yaml`
- Domínios consistentes:
  - Prometheus: `prometheus-logcomex.35-198-21-170.nip.io`
  - Grafana: `grafana-logcomex.34-95-167-174.nip.io`

### 2. **Serviços Corrigidos**
- Arquivo: `monitoring-services-fixed.yaml`
- Tipo alterado de `LoadBalancer` para `ClusterIP`
- Compatível com Ingress HTTPS

### 3. **Script de Aplicação**
- Script PowerShell: `fix-monitoring-https.ps1`
- Remove configurações conflitantes
- Aplica correções automaticamente
- Verifica status dos recursos

## Como Aplicar as Correções

### Opção 1: Script Automático (Recomendado)
```powershell
cd clusters/monitoring-cluster/production
.\fix-monitoring-https.ps1
```

### Opção 2: Manual
```powershell
# 1. Remover configurações conflitantes
kubectl delete ingress monitoring-https-ingress -n monitoring-new --ignore-not-found=true
kubectl delete managedcertificate monitoring-https-cert -n monitoring-new --ignore-not-found=true

# 2. Aplicar serviços corrigidos
kubectl apply -f monitoring-services-fixed.yaml

# 3. Aplicar configuração HTTPS
kubectl apply -f monitoring-https-fixed.yaml
```

## Verificação

Após aplicar as correções, verifique:

1. **Status dos Serviços:**
   ```powershell
   kubectl get services -n monitoring-new
   ```

2. **Status do Certificado:**
   ```powershell
   kubectl get managedcertificate -n monitoring-new
   kubectl describe managedcertificate monitoring-ssl-cert -n monitoring-new
   ```

3. **Status do Ingress:**
   ```powershell
   kubectl get ingress -n monitoring-new
   ```

## URLs de Acesso

- **Prometheus:** https://prometheus-logcomex.35-198-21-170.nip.io
- **Grafana:** https://grafana-logcomex.34-95-167-174.nip.io

## Notas Importantes

- O certificado pode levar alguns minutos para ser provisionado
- Verifique se os pods estão rodando antes de acessar
- Se houver problemas, verifique os logs: `kubectl logs -n monitoring-new -l app=prometheus`
