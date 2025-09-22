#!/usr/bin/env python3
"""
Análise de amostra de 10.000 contatos para determinar campos essenciais
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
AMOSTRA_SIZE = 10000  # 10.000 contatos para análise mais precisa
DELAY_BETWEEN_REQUESTS = 1.0  # 1 segundo entre requests

# Propriedades para analisar (todas as possíveis)
HUBSPOT_PROPERTIES = [
    # Dados pessoais
    'firstname', 'lastname', 'email', 'phone', 'mobilephone',
    
    # Dados empresariais
    'company', 'jobtitle', 'website',
    
    # Endereço
    'address', 'city', 'state', 'zip', 'country',
    
    # Dados HubSpot
    'lifecyclestage', 'hs_lead_status', 'createdate', 'lastmodifieddate',
    
    # Campos específicos da Logcomex
    'codigo_do_voucher', 'hubspot_owner_id',
    
    # Campos de telefone adicionais
    'hs_whatsapp_phone_number', 'govcs_i_phone_number',
    'hs_calculated_phone_number', 'hs_calculated_mobile_number',
    'hs_calculated_phone_number_country_code', 'hs_calculated_phone_number_area_code',
    'telefone_ravena_classificado__revops_', 'celular1_gerador_de_personas', 'celular2_gerador_de_personas',
    
    # Campos específicos
    'atendimento_ativo_por', 'buscador_ncm', 'cnpj_da_empresa_pesquisada',
    'contato_por_whatsapp', 'criado_whatsapp', 'whatsapp_api', 'whatsapp_error_spread_chat'
]

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

def analisar_amostra_10k():
    """Analisar amostra de 10.000 contatos"""
    
    print(f"🔍 ANALISANDO AMOSTRA DE {AMOSTRA_SIZE:,} CONTATOS")
    print("=" * 60)
    print(f"📊 Representatividade: {AMOSTRA_SIZE/300000*100:.1f}% da base total")
    print(f"⏱️ Tempo estimado: {AMOSTRA_SIZE/100*1/60:.1f} minutos")
    print("=" * 60)
    
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
    start_time = time.time()
    
    while total_contatos < AMOSTRA_SIZE:
        params = {
            'limit': min(100, AMOSTRA_SIZE - total_contatos),
            'properties': HUBSPOT_PROPERTIES
        }
        
        if after_token:
            params['after'] = after_token
        
        print(f"📄 Página {page:3d} - Buscando contatos...")
        
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
            for prop in HUBSPOT_PROPERTIES:
                value = properties.get(prop)
                if value and str(value).strip():
                    propriedades_stats[prop]['count'] += 1
                    propriedades_stats[prop]['values'].add(str(value)[:50])  # Primeiros 50 chars
        
        # Mostrar progresso a cada 1000 contatos
        if total_contatos % 1000 == 0:
            elapsed = time.time() - start_time
            rate = total_contatos / elapsed * 60  # contatos por minuto
            remaining = (AMOSTRA_SIZE - total_contatos) / rate  # minutos restantes
            print(f"✅ Página {page:3d}: {len(contacts):3d} contatos. Total: {total_contatos:5d}/{AMOSTRA_SIZE:,} ({total_contatos/AMOSTRA_SIZE*100:5.1f}%)")
            print(f"   ⏱️ Velocidade: {rate:.1f} contatos/min | Tempo restante: {remaining:.1f} min")
        
        # Verificar se há mais páginas
        paging = data.get('paging', {})
        next_page = paging.get('next', {})
        after_token = next_page.get('after')
        
        if not after_token:
            print("✅ Última página alcançada")
            break
        
        page += 1
    
    # Calcular estatísticas
    total_time = time.time() - start_time
    print(f"\n📊 ANÁLISE COMPLETA: {total_contatos:,} contatos em {total_time/60:.1f} minutos")
    print(f"📈 Velocidade média: {total_contatos/total_time*60:.1f} contatos/minuto")
    print("=" * 60)
    
    resultados = []
    for prop in HUBSPOT_PROPERTIES:
        stats = propriedades_stats[prop]
        count = stats['count']
        percentual = (count / total_contatos) * 100 if total_contatos > 0 else 0
        
        resultados.append({
            'propriedade': prop,
            'total_preenchidos': count,
            'percentual': percentual,
            'amostras': list(stats['values'])[:5]  # Primeiras 5 amostras
        })
    
    # Ordenar por percentual
    resultados.sort(key=lambda x: x['percentual'], reverse=True)
    
    # Mostrar resultados
    print("\n🎯 PROPRIEDADES ORDENADAS POR USO:")
    print("-" * 60)
    
    for i, resultado in enumerate(resultados, 1):
        prop = resultado['propriedade']
        count = resultado['total_preenchidos']
        percentual = resultado['percentual']
        amostras = resultado['amostras']
        
        print(f"{i:2d}. {prop:35s} | {count:5d}/{total_contatos:5d} ({percentual:5.1f}%)")
        
        if amostras:
            print(f"     Amostras: {', '.join(amostras[:3])}")
    
    # Salvar resultados
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"analysis/analise_amostra_{AMOSTRA_SIZE}_{timestamp}.json"
    
    os.makedirs('analysis', exist_ok=True)
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump({
            'timestamp': datetime.now().isoformat(),
            'amostra_size': total_contatos,
            'propriedades_analisadas': len(HUBSPOT_PROPERTIES),
            'tempo_total_minutos': total_time/60,
            'velocidade_contatos_por_minuto': total_contatos/total_time*60,
            'resultados': resultados
        }, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 Resultados salvos em: {filename}")
    
    # Recomendações
    print("\n🎯 RECOMENDAÇÕES BASEADAS NA ANÁLISE:")
    print("-" * 60)
    
    essenciais = [r for r in resultados if r['percentual'] >= 80]
    importantes = [r for r in resultados if 20 <= r['percentual'] < 80]
    opcionais = [r for r in resultados if r['percentual'] < 20]
    
    print(f"✅ ESSENCIAIS (80%+): {len(essenciais)} propriedades")
    for r in essenciais:
        print(f"   • {r['propriedade']} ({r['percentual']:.1f}%)")
    
    print(f"\n📊 IMPORTANTES (20-80%): {len(importantes)} propriedades")
    for r in importantes:
        print(f"   • {r['propriedade']} ({r['percentual']:.1f}%)")
    
    print(f"\n🗑️ OPCIONAIS (<20%): {len(opcionais)} propriedades")
    for r in opcionais:
        print(f"   • {r['propriedade']} ({r['percentual']:.1f}%)")
    
    return resultados

if __name__ == "__main__":
    analisar_amostra_10k()

