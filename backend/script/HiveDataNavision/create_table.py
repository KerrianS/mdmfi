import pyodbc

# === CONFIGURATION SQL SERVER ===
SQL_SERVER = 'srvnavsql'
SQL_DATABASE = 'NAV2017RECETTE'
SQL_USER = 'aitec'
SQL_PASSWORD = 'mobaitec'
SQL_DRIVER = 'ODBC Driver 17 for SQL Server'

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

# Mapping SQL Server -> PostgreSQL
type_map = {
    'int': 'integer',
    'bigint': 'bigint',
    'smallint': 'smallint',
    'tinyint': 'smallint',
    'bit': 'boolean',
    'nvarchar': 'text',
    'varchar': 'text',
    'nchar': 'text',
    'char': 'text',
    'datetime': 'timestamp',
    'date': 'date',
    'float': 'double precision',
    'decimal': 'numeric',
    # Ajoute d'autres types si besoin
}

# Connexion SQL Server
conn_str = (
    f"DRIVER={{{SQL_DRIVER}}};"
    f"SERVER={SQL_SERVER};"
    f"DATABASE={SQL_DATABASE};"
    f"UID={SQL_USER};"
    f"PWD={SQL_PASSWORD}"
)
sql_conn = pyodbc.connect(conn_str)
cursor = sql_conn.cursor()

for table in TABLES:
    table_name = table.replace(' ', '_').replace('dbo_', '').lower()
    print(f"-- Création de la table {table_name}")
    # Correction ici :
    table_name_sql = table[4:] if table.startswith('dbo_') else table
    table_name_sql = table_name_sql.strip()
    cursor.execute(f"""
        SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = '{table_name_sql}'
    """)
    columns = cursor.fetchall()
    col_defs = []
    for col in columns:
        col_name = col[0].lower()
        col_type = type_map.get(col[1], 'text')
        col_defs.append(f'"{col_name}" {col_type}')
    create_sql = f'CREATE TABLE IF NOT EXISTS "{table_name}" (\n  {", ".join(col_defs)}\n);'
    print(create_sql)
    print()

cursor.close()
sql_conn.close()
