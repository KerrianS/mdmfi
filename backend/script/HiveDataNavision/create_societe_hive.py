#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour générer des fichiers .hive par société depuis SQL Server Navision
"""

import os
import json
import pyodbc
from datetime import datetime

# === CONFIGURATION SQL SERVER ===
SQL_SERVER = 'srvnavsql'
SQL_DATABASE = 'NAV2017RECETTE'
SQL_USER = 'aitec'
SQL_PASSWORD = 'mobaitec'
SQL_DRIVER = 'ODBC Driver 17 for SQL Server'

# Mapping des sociétés
SOCIETE_MAPPING = {
    'BGS': 'rsp-bgs',
    'NEG': 'rsp-neg', 
    'SB': 'rsp-sb'
}

# Tables Entry à traiter
ENTRY_TABLES = [
    'dbo_BGS$G_L Entry',
    'dbo_NEG$G_L Entry', 
    'dbo_SB$G_L Entry'
]

def connect_sql_server():
    """Connexion à SQL Server"""
    conn_str = (
        f"DRIVER={{{SQL_DRIVER}}};"
        f"SERVER={SQL_SERVER};"
        f"DATABASE={SQL_DATABASE};"
        f"UID={SQL_USER};"
        f"PWD={SQL_PASSWORD}"
    )
    return pyodbc.connect(conn_str)

def fetch_entry_data(cursor, table_name: str) -> list:
    """Récupère les données Entry d'une table spécifique"""
    print(f"📊 Récupération des données depuis {table_name}...")
    
    # Requête convertie de PostgreSQL vers SQL Server
    query = f"""
    WITH annees_top4 AS (
        SELECT TOP 3
            YEAR([Posting Date]) as annee
        FROM [{table_name}]
        GROUP BY YEAR([Posting Date])
        ORDER BY YEAR([Posting Date]) DESC
    )
    SELECT 
        [Entry No_] as id,
        [Posting Date] as date_ecriture,
        [G_L Account No_] as code_compte,
        [Description] as description,
        [Document No_] as document,
        [Amount] as montant,
        [User ID] as utilisateur,
        [Source Code] as source,
        [Global Dimension 1 Code] as dimension_1,
        [Global Dimension 2 Code] as dimension_2,
        [Debit Amount] as debit,
        [Credit Amount] as credit,
        DATEPART(QUARTER, [Posting Date]) as trimestre
    FROM [{table_name}]
    WHERE YEAR([Posting Date]) IN (
        SELECT annee FROM annees_top4
    )
    """
    
    cursor.execute(query)
    columns = [column[0] for column in cursor.description]
    rows = cursor.fetchall()
    
    data = []
    for row in rows:
        row_dict = {}
        for col, value in zip(columns, row):
            if isinstance(value, datetime):
                row_dict[col] = value.isoformat()
            elif isinstance(value, (int, float)):
                row_dict[col] = value
            else:
                row_dict[col] = str(value) if value is not None else None
        data.append(row_dict)
    
    print(f"✅ {len(data)} lignes récupérées de {table_name}")
    return data

def create_societe_hive():
    print("🚀 Génération des fichiers .hive par société depuis SQL Server")
    
    try:
        # Connexion à SQL Server
        print("🔌 Connexion à SQL Server...")
        sql_conn = connect_sql_server()
        cursor = sql_conn.cursor()
        
        # Dictionnaire pour stocker les données par société
        societes_data = {
            "rsp-bgs": [],
            "rsp-neg": [],
            "rsp-sb": []
        }
        
        # Traitement de chaque table Entry
        for table_name in ENTRY_TABLES:
            # Extraire le code société du nom de table
            societe_code = table_name.split('$')[0].replace('dbo_', '')
            societe_name = SOCIETE_MAPPING.get(societe_code, societe_code)
            
            print(f"\n📊 Société: {societe_name}")
            
            # Récupération des données
            lignes = fetch_entry_data(cursor, table_name)
            societes_data[societe_name].extend(lignes)
        
        # Générer un fichier hive par société
        print(f"\n📝 Génération des fichiers .hive par société...")
        
        for societe, lignes in societes_data.items():
            if not lignes:
                print(f"⚠️  Aucune donnée pour {societe}")
                continue
                
            print(f"\n📊 Société {societe}: {len(lignes)} lignes")
            
            # Construction du fichier .hive pour cette société
            hive_data = {
                "metadata": {
                    "generation_date": datetime.now().isoformat(),
                    "societe": societe,
                    "total_lines": len(lignes),
                    "description": f"Données Navision SQL Server pour {societe}"
                },
                "donnees_brutes": {
                    "lignes": lignes
                }
            }
            
            # Sauvegarder le fichier
            filename = f"{societe}_data.hive"
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(hive_data, f, ensure_ascii=False, indent=2)
            
            print(f"✅ Fichier généré: {filename}")
        
        # Fermeture de la connexion
        cursor.close()
        sql_conn.close()
        
        print(f"\n🎉 Génération terminée !")
        print(f"📁 Fichiers créés:")
        for societe in societes_data.keys():
            filename = f"{societe}_data.hive"
            if os.path.exists(filename):
                size = os.path.getsize(filename)
                print(f"   📄 {filename} ({size:,} bytes)")
                
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(create_societe_hive()) 