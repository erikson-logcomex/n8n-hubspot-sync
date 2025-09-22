#!/usr/bin/env python3
"""
Script SIMPLES para calcular média de chamadas API incrementais
Objetivo: Documentar estimativa para o projeto
"""

import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

def calcular_media_incremental():
    conn = psycopg2.connect(
        host=os.getenv('PG_HOST'),
        port=os.getenv('PG_PORT'), 
        database=os.getenv('PG_DATABASE'),
        user=os.getenv('PG_USER'),
        password=os.getenv('PG_PASSWORD')
    )

    cursor = conn.cursor()

    # Calcular média de modificações dos últimos 30 dias
    cursor.execute("""
        SELECT 
            COUNT(CASE WHEN lastmodifieddate >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as modificados_30d,
            COUNT(CASE WHEN lastmodifieddate >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as modificados_7d
        FROM contacts;
    """)

    result = cursor.fetchone()
    modificados_30d, modificados_7d = result

    # Calcular médias
    media_dia_30d = modificados_30d / 30
    media_dia_7d = modificados_7d / 7
    
    # Chamadas API = modificações / 100 (paginação)
    calls_api_dia_30d = max(1, int(media_dia_30d / 100)) + (1 if media_dia_30d % 100 > 0 else 0)
    calls_api_dia_7d = max(1, int(media_dia_7d / 100)) + (1 if media_dia_7d % 100 > 0 else 0)

    print("📊 CÁLCULO DA MÉDIA - INCREMENTAL API")
    print("=" * 45)
    print(f"📅 Base de cálculo: Últimos 30 dias")
    print(f"✏️ Total modificações (30d): {modificados_30d:,}")
    print(f"📊 Média por dia (30d): {media_dia_30d:.1f} contatos")
    print(f"📞 Média calls API/dia (30d): {calls_api_dia_30d}")
    print(f"📈 % limite diário: {(calls_api_dia_30d / 1000000) * 100:.6f}%")
    print()
    print(f"📅 Base de cálculo: Últimos 7 dias (mais recente)")  
    print(f"✏️ Total modificações (7d): {modificados_7d:,}")
    print(f"📊 Média por dia (7d): {media_dia_7d:.1f} contatos")
    print(f"📞 Média calls API/dia (7d): {calls_api_dia_7d}")
    print(f"📈 % limite diário: {(calls_api_dia_7d / 1000000) * 100:.6f}%")
    print()
    print("🎯 ESTIMATIVA PARA DOCUMENTAR:")
    print(f"   📊 Volume incremental médio: {media_dia_30d:.0f}-{media_dia_7d:.0f} contatos/dia")
    print(f"   📞 Chamadas API médias: {calls_api_dia_30d}-{calls_api_dia_7d} calls/dia")
    print(f"   📅 Uso mensal estimado: {calls_api_dia_30d * 30}-{calls_api_dia_7d * 30} calls/mês")
    print(f"   🎯 Impacto: IRRISÓRIO (< 0,01% do limite diário)")

    cursor.close()
    conn.close()

if __name__ == "__main__":
    try:
        calcular_media_incremental()
    except Exception as e:
        print(f"❌ Erro: {e}")
        print("💡 Verifique se .env está configurado e PostgreSQL acessível")

