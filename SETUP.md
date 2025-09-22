# 🚀 **Setup do Projeto n8n HubSpot Sync**

## 📋 **PRÉ-REQUISITOS**

- Python 3.8+
- kubectl configurado
- Acesso ao cluster GKE
- Token HubSpot
- Acesso ao PostgreSQL

## ⚙️ **CONFIGURAÇÃO INICIAL**

### **1. Clone o repositório**
```bash
git clone <repository-url>
cd n8n
```

### **2. Configure as variáveis de ambiente**
```bash
# Copie o arquivo de exemplo
cp env.example .env

# Edite o arquivo .env com suas credenciais
nano .env
```

### **3. Instale as dependências Python**
```bash
pip install -r requirements.txt
```

### **4. Configure o kubectl**
```bash
# Configure o contexto do GKE
gcloud container clusters get-credentials n8n-cluster --zone=southamerica-east1-a
```

## 🔧 **DEPLOY**

### **1. Deploy do cluster n8n**
```bash
cd n8n-kubernetes-hosting
kubectl apply -f n8n-config-consolidated.yaml
```

### **2. Verificação de saúde**
```bash
cd scripts
.\health-check.ps1
```

## 📊 **USO**

### **Primeira carga de dados**
```bash
cd scripts
python primeira_carga_hubspot_final.py
```

## 🔐 **SEGURANÇA**

- **NUNCA** commite o arquivo `.env`
- **NUNCA** commite secrets do Kubernetes
- Use variáveis de ambiente para credenciais
- Configure o `.gitignore` adequadamente

## 📚 **DOCUMENTAÇÃO**

- [README.md](README.md) - Documentação principal
- [docs/](docs/) - Documentação técnica detalhada
- [analysis/](analysis/) - Análises e relatórios
