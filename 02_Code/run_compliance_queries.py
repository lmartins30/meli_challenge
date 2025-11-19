import duckdb
from pathlib import Path

# --------------------------
# Configs
# --------------------------
db = "../db_simulado.duckdb"
sql_file = "compliance_queries.sql"

# --------------------------
# Funcs
# --------------------------
def load_block(sql_path, block_name):
    """
    Lê um bloco SQL delimitado por:
        -- >>> BLOCK X START
        -- >>> BLOCK X END

    Exemplo:
        query = load_sql_block("compliance_queries.sql", "2.1")
    """
    start = f"-- >>> BLOCK {block_name} START"
    end = f"-- >>> BLOCK {block_name} END"

    with open(sql_path, "r", encoding="utf-8") as f:
        text = f.read()

    if start not in text:
        raise ValueError(f"Start tag não encontrado: {start}")

    if end not in text:
        raise ValueError(f"End tag não encontrado: {end}")

    start_index = text.index(start) + len(start)
    end_index = text.index(end)

    # Extrai o bloco e remove quebras de linha extras
    block_sql = text[start_index:end_index].strip()

    return block_sql

def run_block(con, sql_text: str, block_name: str):
    """
    Executes a SQL block and prints its tabular result if available.

    Args:
        con: Database connection object with an `.execute()` method.
        sql_text (str): SQL statement to run.
        block_name (str): Label used to identify the executed block.

    Returns:
        None
    """
    print(f"\n==============================")
    print(f" Executando bloco {block_name}")
    print(f"==============================\n")

    try:
        result = con.execute(sql_text)
        try:
            df = result.df()
            print(df)
        except:
            print("(Sem retorno tabular)")
    except Exception as e:
        print(f"Erro ao executar o bloco {block_name}: {e}")

# ------------------------------------------------------
# MAIN
# ------------------------------------------------------
con = duckdb.connect(db)
blocos = ["2.1", "2.2", "2.3"] # Para rodar individualmente apenas altera a lista de blocos para rodar.

for bloco in blocos:
    sql_text = load_block(sql_file, bloco)
    run_block(con,sql_text,bloco)

con.close()