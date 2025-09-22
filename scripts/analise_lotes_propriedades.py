#!/usr/bin/env python3
"""
Análise de propriedades em lotes para evitar erro 414
"""

import requests
import time
import os
from dotenv import load_dotenv
import json
from datetime import datetime
from collections import defaultdict

# Carregar variáveis de ambiente
load_dotenv()

# Configurações
HUBSPOT_TOKEN = os.getenv('HUBSPOT_PRIVATE_APP_TOKEN')
AMOSTRA_SIZE = 2000  # 2000 contatos por lote
DELAY_BETWEEN_REQUESTS = 1.0
PROPRIEDADES_POR_LOTE = 50  # Máximo 50 propriedades por request

def make_hubspot_request(url, headers, params, retry_count=0):
    """Fazer request para API do HubSpot com retry"""
    
    try:
        time.sleep(DELAY_BETWEEN_REQUESTS)
        response = requests.get(url, headers=headers, params=params, timeout=30)
        
        if response.status_code == 200:
            return response.json()
        elif response.status_code == 429:  # Rate limit
            retry_after = int(response.headers.get('Retry-After', 10))
            print(f"⚠️ Rate limit. Aguardando {retry_after}s...")
            time.sleep(retry_after)
            
            if retry_count < 3:
                return make_hubspot_request(url, headers, params, retry_count + 1)
            else:
                print("❌ Máximo de tentativas atingido")
                return None
        else:
            print(f"❌ Erro na API: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        if retry_count < 3:
            time.sleep(5)
            return make_hubspot_request(url, headers, params, retry_count + 1)
        return None

def obter_todas_propriedades():
    """Obter todas as propriedades do schema"""
    
    print("📋 Obtendo todas as propriedades do schema...")
    
    url = "https://api.hubapi.com/crm/v3/properties/contacts"
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    params = {
        'limit': 1000
    }
    
    data = make_hubspot_request(url, headers, params)
    
    if not data:
        return []
    
    propriedades = []
    for prop in data.get('results', []):
        propriedades.append(prop.get('name'))
    
    print(f"✅ {len(propriedades)} propriedades obtidas do schema")
    return propriedades

def dividir_em_lotes(lista, tamanho_lote):
    """Dividir lista em lotes menores"""
    return [lista[i:i + tamanho_lote] for i in range(0, len(lista), tamanho_lote)]

def analisar_lote_propriedades(propriedades_lote, amostra_size):
    """Analisar um lote específico de propriedades"""
    
    url = "https://api.hubapi.com/crm/v3/objects/contacts"
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    # Estatísticas
    total_contatos = 0
    propriedades_stats = defaultdict(lambda: {'count': 0, 'values': set()})
    
    page = 1
    after_token = None
    
    while total_contatos < amostra_size:
        params = {
            'limit': min(100, amostra_size - total_contatos),
            'properties': propriedades_lote
        }
        
        if after_token:
            params['after'] = after_token
        
        data = make_hubspot_request(url, headers, params)
        
        if not data:
            print("❌ Falha ao buscar dados")
            break
        
        contacts = data.get('results', [])
        if not contacts:
            print("✅ Nenhum contato encontrado")
            break
        
        # Analisar contatos
        for contact in contacts:
            total_contatos += 1
            properties = contact.get('properties', {})
            
            # Contar propriedades com dados
            for prop in propriedades_lote:
                value = properties.get(prop)
                if value and str(value).strip():
                    propriedades_stats[prop]['count'] += 1
                    propriedades_stats[prop]['values'].add(str(value)[:50])  # Primeiros 50 chars
        
        # Verificar se há mais páginas
        paging = data.get('paging', {})
        next_page = paging.get('next', {})
        after_token = next_page.get('after')
        
        if not after_token:
            break
        
        page += 1
    
    return propriedades_stats, total_contatos

def analisar_em_lotes():
    """Analisar propriedades em lotes"""
    
    print(f"🔍 ANÁLISE EM LOTES DE PROPRIEDADES")
    print("=" * 60)
    print(f"📊 Amostra: {AMOSTRA_SIZE:,} contatos por lote")
    print(f"📋 Propriedades por lote: {PROPRIEDADES_POR_LOTE}")
    print("=" * 60)
    
    # 1. Obter todas as propriedades
    todas_propriedades = obter_todas_propriedades()
    
    if not todas_propriedades:
        print("❌ Falha ao obter propriedades")
        return
    
    # 2. Dividir em lotes
    lotes = dividir_em_lotes(todas_propriedades, PROPRIEDADES_POR_LOTE)
    print(f"📦 Total de lotes: {len(lotes)}")
    
    # 3. Analisar cada lote
    resultados_completos = []
    total_contatos_analisados = 0
    
    for i, lote in enumerate(lotes, 1):
        print(f"\n📦 LOTE {i}/{len(lotes)} - {len(lote)} propriedades")
        print("-" * 40)
        
        start_time = time.time()
        stats, contatos = analisar_lote_propriedades(lote, AMOSTRA_SIZE)
        lote_time = time.time() - start_time
        
        print(f"✅ Lote {i}: {contatos} contatos em {lote_time/60:.1f} min")
        
        # Converter stats para resultados
        for prop in lote:
            prop_stats = stats[prop]
            count = prop_stats['count']
            percentual = (count / contatos) * 100 if contatos > 0 else 0
            
            resultados_completos.append({
                'propriedade': prop,
                'total_preenchidos': count,
                'percentual': percentual,
                'amostras': list(prop_stats['values'])[:5]
            })
        
        total_contatos_analisados = contatos  # Usar o último lote como referência
    
    # 4. Ordenar resultados
    resultados_completos.sort(key=lambda x: x['percentual'], reverse=True)
    
    # 5. Mostrar resultados (top 50)
    print(f"\n🎯 TOP 50 PROPRIEDADES MAIS USADAS:")
    print("-" * 60)
    
    for i, resultado in enumerate(resultados_completos[:50], 1):
        prop = resultado['propriedade']
        count = resultado['total_preenchidos']
        percentual = resultado['percentual']
        amostras = resultado['amostras']
        
        print(f"{i:2d}. {prop:35s} | {count:5d}/{total_contatos_analisados:5d} ({percentual:5.1f}%)")
        
        if amostras:
            print(f"     Amostras: {', '.join(amostras[:3])}")
    
    # 6. Salvar resultados
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"analysis/analise_lotes_{AMOSTRA_SIZE}_{timestamp}.json"
    
    os.makedirs('analysis', exist_ok=True)
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump({
            'timestamp': datetime.now().isoformat(),
            'amostra_size': total_contatos_analisados,
            'propriedades_analisadas': len(todas_propriedades),
            'lotes_utilizados': len(lotes),
            'propriedades_por_lote': PROPRIEDADES_POR_LOTE,
            'resultados': resultados_completos
        }, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 Resultados salvos em: {filename}")
    
    # 7. Recomendações
    print("\n🎯 RECOMENDAÇÕES BASEADAS NA ANÁLISE:")
    print("-" * 60)
    
    essenciais = [r for r in resultados_completos if r['percentual'] >= 80]
    importantes = [r for r in resultados_completos if 20 <= r['percentual'] < 80]
    opcionais = [r for r in resultados_completos if r['percentual'] < 20]
    
    print(f"✅ ESSENCIAIS (80%+): {len(essenciais)} propriedades")
    for r in essenciais:
        print(f"   • {r['propriedade']} ({r['percentual']:.1f}%)")
    
    print(f"\n📊 IMPORTANTES (20-80%): {len(importantes)} propriedades")
    for r in importantes[:20]:  # Top 20 importantes
        print(f"   • {r['propriedade']} ({r['percentual']:.1f}%)")
    
    print(f"\n🗑️ OPCIONAIS (<20%): {len(opcionais)} propriedades")
    
    return resultados_completos

if __name__ == "__main__":
    analisar_em_lotes()

