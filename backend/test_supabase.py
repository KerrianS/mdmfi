#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour tester la connexion Supabase et voir les vues disponibles
"""

import os
from dotenv import load_dotenv
import requests
from requests.auth import HTTPBasicAuth
import json

load_dotenv()

def test_supabase():
    print("=== Test de connexion Supabase ===")
    
    # Vérifier les variables d'environnement
    print("\n🔍 Vérification des variables d'environnement...")
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")
    basic_user = os.getenv("SUPABASE_BASIC_USER")
    basic_pass = os.getenv("SUPABASE_BASIC_PASS")
    
    print(f"   📊 SUPABASE_URL: {'✅ Configuré' if supabase_url else '❌ Manquant'}")
    print(f"   📊 SUPABASE_KEY: {'✅ Configuré' if supabase_key else '❌ Manquant'}")
    print(f"   📊 SUPABASE_BASIC_USER: {'✅ Configuré' if basic_user else '❌ Manquant'}")
    print(f"   📊 SUPABASE_BASIC_PASS: {'✅ Configuré' if basic_pass else '❌ Manquant'}")
    
    if not all([supabase_url, supabase_key]):
        print("\n❌ Variables d'environnement manquantes!")
        print("   Créez un fichier .env avec:")
        print("   SUPABASE_URL=votre_url_supabase")
        print("   SUPABASE_KEY=votre_clé_api")
        return
    
    # Tester la connexion
    print("\n🔄 Test de connexion...")
    try:
        headers = {
            "apikey": supabase_key,
            "Authorization": f"Bearer {supabase_key}",
            "Content-Type": "application/json; charset=utf-8",
            "Accept": "application/json; charset=utf-8"
        }
        # Utiliser Basic Auth seulement si configuré
        if basic_user and basic_pass:
            auth = HTTPBasicAuth(basic_user, basic_pass)
        else:
            auth = None
        
        # Test simple
        req_url = f"{supabase_url.rstrip('/')}/rest/v1/"
        response = requests.get(req_url, headers=headers, auth=auth)
        print(f"   📊 Status: {response.status_code}")
        
        if response.status_code == 200:
            print("   ✅ Connexion réussie!")
        else:
            print(f"   ❌ Erreur de connexion: {response.text}")
            return
            
    except Exception as e:
        print(f"   ❌ Erreur de connexion: {e}")
        return
    
    # Tester les vues disponibles
    print("\n📋 Test des vues disponibles...")
    vues_a_tester = [
        "neg_view_entry",
        "sb_view_entry",
        "bgs_view_entry",
    ]
    
    for vue in vues_a_tester:
        try:
            req_url = f"{supabase_url.rstrip('/')}/rest/v1/{vue}?select=*&limit=1"
            response = requests.get(req_url, headers=headers, auth=auth)
            
            if response.status_code == 200:
                data = response.json()
                if data:
                    print(f"   ✅ {vue}: Données disponibles")
                else:
                    print(f"   📊 {vue}: Vue vide")
            else:
                print(f"   ❌ {vue}: Erreur {response.status_code}")
                
        except Exception as e:
            print(f"   ❌ {vue}: Erreur - {e}")
    
    # Tester une vue spécifique avec plus de données
    print("\n🔍 Test détaillé de neg_view_entry...")
    try:
        req_url = f"{supabase_url.rstrip('/')}/rest/v1/neg_view_entry?select=id,date_ecriture,code_compte,description&limit=10"
        response = requests.get(req_url, headers=headers, auth=auth)
        
        if response.status_code == 200:
            data = response.json()
            print(f"   📊 {len(data)} lignes trouvées")
            
            if data:
                print("   📋 Exemples:")
                for i, ligne in enumerate(data[:3]):
                    print(f"      {i+1}. ID: {ligne.get('id', 'N/A')}, Date: {ligne.get('date_ecriture', 'N/A')}, Compte: {ligne.get('code_compte', 'N/A')}")
        else:
            print(f"   ❌ Erreur: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"   ❌ Erreur: {e}")

    # Test détaillé de toutes les vues disponibles
    print("\n🔍 Test détaillé de toutes les vues...")
    vues_disponibles = [
        "neg_view_entry",
        "sb_view_entry",
        "bgs_view_entry",
    ]
    
    for vue in vues_disponibles:
        print(f"\n📊 Test de {vue}...")
        try:
            # D'abord, voir la structure de la vue
            req_url = f"{supabase_url.rstrip('/')}/rest/v1/{vue}?select=*&limit=1"
            response = requests.get(req_url, headers=headers, auth=auth)
            
            if response.status_code == 200:
                data = response.json()
                if data:
                    print(f"   ✅ Vue accessible avec {len(data)} ligne(s) d'exemple")
                    
                    # Afficher les colonnes disponibles
                    if data:
                        colonnes = list(data[0].keys())
                        print(f"   📋 Colonnes disponibles: {', '.join(colonnes[:10])}{'...' if len(colonnes) > 10 else ''}")
                        
                        # Tester avec plus de données
                        req_url_count = f"{supabase_url.rstrip('/')}/rest/v1/{vue}?select=*&limit=100"
                        response_count = requests.get(req_url_count, headers=headers, auth=auth)
                        
                        if response_count.status_code == 200:
                            data_count = response_count.json()
                            print(f"   📊 Total disponible: {len(data_count)} lignes")
                            
                            # Afficher quelques exemples
                            if data_count:
                                print("   📋 Exemples:")
                                for i, ligne in enumerate(data_count[:3]):
                                    # Afficher les colonnes importantes
                                    if 'id' in ligne:
                                        print(f"      {i+1}. ID: {ligne['id']}")
                                    if 'date_ecriture' in ligne:
                                        print(f"         Date: {ligne['date_ecriture']}")
                                    if 'code_compte' in ligne:
                                        print(f"         Compte: {ligne['code_compte']}")
                                    if 'description' in ligne:
                                        print(f"         Description: {ligne['description'][:50]}...")
                                print()
                else:
                    print(f"   📊 Vue accessible mais vide")
            else:
                print(f"   ❌ Erreur {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"   ❌ Erreur: {e}")

if __name__ == "__main__":
    test_supabase() 