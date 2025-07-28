# -*- coding: utf-8 -*-
import os
from dotenv import load_dotenv
import requests
from requests.auth import HTTPBasicAuth
import json

load_dotenv()

class NavisionService:
    def __init__(self):
        self.url = os.getenv("SUPABASE_URL").rstrip('/')
        self.api_key = os.getenv("SUPABASE_KEY")
        self.basic_user = os.getenv("SUPABASE_BASIC_USER")
        self.basic_pass = os.getenv("SUPABASE_BASIC_PASS")
        self.headers = {
            "apikey": self.api_key,
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json; charset=utf-8",
            "Accept": "application/json; charset=utf-8"
        }
        self.auth = HTTPBasicAuth(self.basic_user, self.basic_pass)

    def get(self, table, params=None):
        req_url = f"{self.url}/rest/v1/{table}"
        response = requests.get(req_url, headers=self.headers, auth=self.auth, params=params)
        response.encoding = 'utf-8'  # Force l'encodage UTF-8
        response.raise_for_status()
        
        # Assurer que la réponse est correctement décodée
        try:
            data = response.json()
        except json.JSONDecodeError:
            # Fallback si problème de décodage JSON
            data = json.loads(response.content.decode('utf-8'))
        
        return data

    def post(self, table, data):
        req_url = f"{self.url}/rest/v1/{table}"
        response = requests.post(req_url, headers=self.headers, auth=self.auth, json=data)
        response.encoding = 'utf-8'  # Force l'encodage UTF-8
        response.raise_for_status()
        
        try:
            result = response.json()
        except json.JSONDecodeError:
            result = json.loads(response.content.decode('utf-8'))
        
        return result

    def table_has_data(self, table):
        req_url = f"{self.url}/rest/v1/{table}?select=*&limit=1"
        response = requests.get(req_url, headers=self.headers, auth=self.auth)
        response.encoding = 'utf-8'  # Force l'encodage UTF-8
        response.raise_for_status()
        
        try:
            data = response.json()
        except json.JSONDecodeError:
            data = json.loads(response.content.decode('utf-8'))
        
        return bool(data)

if __name__ == "__main__":
    nav = NavisionService()
    if nav.table_has_data("bgs$g_l_account"):
        print("La table contient déjà des données.")
    else:
        print("La table est vide.")
