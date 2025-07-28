import pyodbc
import requests
from requests.auth import HTTPBasicAuth
import base64
import datetime
import decimal

# === CONFIGURATION ===
# SQL Server
SQL_SERVER = 'srvnavsql'
SQL_DATABASE = 'NAV2017RECETTE'
SQL_USER = 'aitec'
SQL_PASSWORD = 'mobaitec'
SQL_DRIVER = 'ODBC Driver 17 for SQL Server'

# Supabase
SUPABASE_URL = "https://sbase.aitecservice.com"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ewogICJyb2xlIjogInNlcnZpY2Vfcm9sZSIsCiAgImlzcyI6ICJzdXBhYmFzZSIsCiAgImlhdCI6IDE3MDYyMjM2MDAsCiAgImV4cCI6IDE4NjQwNzY0MDAKfQ.ox9mAvmiGJC7XRfQmgJGnWetcEaA3c6LKczw_SxZCtY"
BASIC_USER = "supabase"
BASIC_PASS = "6s7GvCfnPUhz8q9ZpfdmROwqINYGGzLcIt"

TABLES = [
    'dbo_BGS$G_L Account',
    'dbo_BGS$G_L Budget Entry',
    'dbo_BGS$G_L Budget Name',
    'dbo_BGS$G_L Entry',
    'dbo_BGS$Gen_ Journal Batch',
    'dbo_BGS$Gen_ Journal Line',
    'dbo_BGS$IC G_L Account',
    'dbo_NEG$G_L Account',
    'dbo_NEG$G_L Budget Entry',
    'dbo_NEG$G_L Budget Name',
    'dbo_NEG$G_L Entry',
    'dbo_NEG$Gen_ Journal Batch',
    'dbo_NEG$Gen_ Journal Line',
    'dbo_SB$G_L Account',
    'dbo_SB$G_L Budget Entry',
    'dbo_SB$G_L Budget Name',
    'dbo_SB$G_L Entry',
    'dbo_SB$Gen_ Journal Batch',
    'dbo_SB$Gen_ Journal Line'
]

# === CONNEXIONS SQL SERVER ===
conn_str = (
    f"DRIVER={{{SQL_DRIVER}}};"
    f"SERVER={SQL_SERVER};"
    f"DATABASE={SQL_DATABASE};"
    f"UID={SQL_USER};"
    f"PWD={SQL_PASSWORD}"
)
sql_conn = pyodbc.connect(conn_str)
cursor = sql_conn.cursor()

# === TRANSFERT ===
headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json"
}

# Mapping SQL Server -> PostgreSQL
# (peut être supprimé si non utilisé ailleurs)

for table in TABLES:
    table_name = table.replace(' ', '_').replace('dbo_', '').lower()
    print(f"Traitement de la table {table}...")
    # Vérification de la présence de données dans la table Supabase
    check_url = f"{SUPABASE_URL}/rest/v1/{table_name}?select=*&limit=1"
    check_response = requests.get(
        check_url,
        headers=headers,
        auth=HTTPBasicAuth(BASIC_USER, BASIC_PASS)
    )
    if check_response.status_code == 200 and check_response.json():
        print(f"Table {table_name} déjà remplie, import ignoré.")
        continue
    if table.startswith('dbo_'):
        schema = 'dbo'
        table_sql = table[4:].strip()
        cursor.execute(f'SELECT * FROM [{schema}].[{table_sql}]')
    else:
        cursor.execute(f'SELECT * FROM [{table}]')
    columns = [column[0] for column in cursor.description]
    rows = cursor.fetchall()
    for row in rows:
        data = {}
        for col, value in zip(columns, row):
            col_name = col.lower()
            if isinstance(value, bytes):
                data[col_name] = base64.b64encode(value).decode('utf-8')
            elif isinstance(value, (datetime.datetime, datetime.date)):
                data[col_name] = value.isoformat()
            elif isinstance(value, decimal.Decimal):
                data[col_name] = float(value)
            else:
                data[col_name] = value
        # Insertion dans Supabase via REST API
        print(f"POST URL: {SUPABASE_URL}/rest/v1/{table_name}")
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/{table_name}",
            json=data,
            headers=headers,
            auth=HTTPBasicAuth(BASIC_USER, BASIC_PASS)
        )
        if response.status_code not in (200, 201):
            print(f"Erreur d'insertion pour {data}: {response.text} (status {response.status_code})")

print("Transfert terminé.")

# Fermeture des connexions
cursor.close()
sql_conn.close()
