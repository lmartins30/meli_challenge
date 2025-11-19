import duckdb
import os

# ----------------------------
# CONFIGURAÇÕES
# ----------------------------
DB_PATH = "../db_simulado.duckdb"   # caminho para seu banco
OUTPUT_DIR = "../03_docs/export_parquet"    # pasta onde salvar os .parquet

# ----------------------------
# EXPORTA TODAS AS TABELAS
# ----------------------------
def exporta_tabelas():
    """
    Exports all DuckDB tables to Parquet files.

    Scans the connected DuckDB database, lists all tables, and writes each
    one into the output directory as a Parquet file using COPY.

    Returns:
        None
    """
    print("Conectando ao banco DuckDB...")
    con = duckdb.connect(DB_PATH)

    # Criar a pasta de saída, se não existir
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("Listando tabelas...")
    tabelas = [t[0] for t in con.execute("SHOW TABLES").fetchall()]

    print(f"Tabelas encontradas: {tabelas}")

    for tabela in tabelas:
        caminho_parquet = os.path.join(OUTPUT_DIR, f"{tabela}.parquet")

        print(f"Exportando tabela {tabela} → {caminho_parquet}")

        query = f"""
            COPY (SELECT * FROM {tabela})
            TO '{caminho_parquet}'
            (FORMAT PARQUET);
        """

        con.execute(query)

    print("\nExportação concluída com sucesso!")
    con.close()


if __name__ == "__main__":
    exporta_tabelas()
