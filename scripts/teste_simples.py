#!/usr/bin/env python3
"""
Teste simples para verificar execução
"""

import os
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

print("🚀 TESTE SIMPLES INICIADO")
print(f"Token: {os.getenv('HUBSPOT_PRIVATE_APP_TOKEN')[:10]}...")
print(f"Host: {os.getenv('PG_HOST')}")
print(f"Database: {os.getenv('PG_DATABASE')}")
print("✅ TESTE CONCLUÍDO")

