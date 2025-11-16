import duckdb
import random
from datetime import datetime, timedelta
import uuid


# --------------------------
# Configs
# --------------------------
db_path = '../db_simulado.duckdb'
ddl_path = '../03_Docs/der.sql'

# --------------------------
# Funcs
# --------------------------
def cria_banco(ddl_path, db_path):
    """
    Cria um banco de dados DuckDB a partir de um arquivo DDL.

    Lê o arquivo SQL especificado em `ddl_path`, conecta ao banco
    DuckDB em `db_path` (criando-o se não existir) e executa os
    comandos DDL para criar as tabelas.

    Args:
        ddl_path (str): Caminho para o arquivo contendo os comandos DDL.
        db_path (str): Caminho para o arquivo do banco DuckDB que será criado ou conectado.

    Returns:
        duckdb.DuckDBPyConnection: Objeto de conexão ao banco DuckDB criado ou existente.

    Raises:
        FileNotFoundError: Se o arquivo `ddl_path` não existir.
        duckdb.Error: Se ocorrer algum erro ao executar os comandos SQL.
    
    Example:
        >>> con = cria_banco("schema.sql", "meu_banco.duckdb")
        Criando banco DuckDB...
        Banco criado com sucesso!
    """
    print("Criando banco DuckDB...")

    with open(ddl_path, "r", encoding="utf-8") as f:
        ddl_sql = f.read()

    con = duckdb.connect(db_path)
    con.execute(ddl_sql)

    print("Banco criado com sucesso!")
    return con

def popula_banco(con):
    """
    Popula o banco DuckDB com dados fictícios para todas as tabelas principais.

    Gera registros de clientes, categorias, itens, pedidos, itens de pedido,
    faturas e cálculos de impostos, garantindo consistência mínima entre as tabelas
    (ex.: issued_date da fatura é 1 dia após order_date do pedido).

    Args:
        con (duckdb.DuckDBPyConnection): Conexão ativa com o banco DuckDB.

    Returns:
        None

    Example:
        >>> con = duckdb.connect("meu_banco.duckdb")
        >>> seed_data(con)
        Populando dados fake...
        Dados inseridos!
    """
    print("Populando dados fake...")

    # ------ 1. CLIENTE ------
    clientes = []
    for i in range(10):
        clientes.append((
            i+1,
            f"Cliente {i+1}",
            f"cliente{i+1}@email.com",
            f"CPF",
            f"{10000000000+i}"
        ))

    con.executemany("""
        INSERT INTO Cliente (customer_id, name, email, tax_id_type, document)
        VALUES (?, ?, ?, ?, ?)
    """, clientes)

    # ------ 2. CATEGORIA ------
    categorias = [
        ("Eletrônicos", "Produtos eletrônicos e gadgets"),
        ("Roupas", "Vestuário masculino e feminino"),
        ("Casa", "Produtos para casa"),
        ("Esportes", "Equipamentos esportivos")
    ]

    con.executemany("""
        INSERT INTO Categoria (category_id, name, description)
        VALUES (?, ?, ?)
    """, [(i+1, c[0], c[1]) for i, c in enumerate(categorias)])

    # ------ 3. ITEM ------
    itens = []
    for i in range(10):
        itens.append((
            i+1,
            f"Item {i+1}",
            random.choice(range(1, 5)),  # categoria
            round(random.uniform(50, 2000), 2)
        ))

    con.executemany("""
        INSERT INTO Item (item_id, name, category_id, price)
        VALUES (?, ?, ?, ?)
    """, itens)

    # ------ 4. PEDIDO ------
    pedidos = []
    for i in range(200):
        pedidos.append((
            i+1,
            random.choice(range(1, 11)),  # customer_id
            datetime.now() - timedelta(days=random.randint(1, 400)), # Garantindo que tenhamos pelo menos 1 ano de pedidos
            round(random.uniform(100, 1500), 2),
            random.choice(["criado", "pago", "cancelado"])
        ))

    con.executemany("""
        INSERT INTO Pedido (order_id, customer_id, order_date, total_paid, status)
        VALUES (?, ?, ?, ?, ?)
    """, pedidos)

    # ------ 5. PEDIDO_ITEM ------
    pedido_items = []
    pedido_item_id = 1

    for pedido in pedidos:
        qtd_itens = random.randint(1, 4)
        for _ in range(qtd_itens):
            item_id = random.choice(range(1, 11))
            preco_unitario = con.execute(
                "SELECT price FROM Item WHERE item_id = ?", [item_id]
            ).fetchone()[0]

            pedido_items.append((
                pedido_item_id,
                pedido[0],
                item_id,
                random.randint(1, 3),
                preco_unitario
            ))
            pedido_item_id += 1

    con.executemany("""
        INSERT INTO PedidoItem (order_item_id, order_id, item_id, quantity, unit_price)
        VALUES (?, ?, ?, ?, ?)
    """, pedido_items)


    # ------ 6. FATURA ------
    invoices = []
    for pedido in pedidos:
        valor_faturado = pedido[3] + random.uniform(-20, 20)  # simula divergência

        invoices.append((
            pedido[0],                                # invoice_id = igual ao pedido
            pedido[0],                                # order_id
            pedido[2] + timedelta(days=1),            # issued_date = 1 dia após data do pedido.
            round(valor_faturado, 2),                 # issued_amount
            random.choice(["emitida", "pendente", "anulada"]),  # status
            f"NF-{uuid.uuid4().hex[:8]}",             # invoice_number
            "CNPJ",                                   # seller_tax_id_type
            "CPF"                                     # buyer_tax_id_type
        ))

    con.executemany("""
        INSERT INTO Invoice (invoice_id, order_id, issued_date, issued_amount, status, invoice_number, seller_tax_id_type, buyer_tax_id_type)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, invoices)

    # ------ 7. CÁLCULO DE IMPOSTOS ------
    tax_rows = []
    for inv in invoices:
        taxa = random.choice([0.05, 0.12, 0.18])
        tax_rows.append((
            inv[0],
            inv[0],
            random.choice(range(1, 5)),
            round(inv[3] * taxa, 2),
            taxa,
            inv[2]
        ))

    con.executemany("""
        INSERT INTO TaxCalculation (tax_id, invoice_id, category_id, tax_amount, tax_rate, calculation_date)
        VALUES (?, ?, ?, ?, ?, ?)
    """, tax_rows)

    print("Dados inseridos!")

# ------------------------------------------------------
# MAIN
# ------------------------------------------------------

if __name__ == "__main__":
    con = cria_banco(ddl_path, db_path)
    popula_banco(con)

    print("Tabelas no banco:")
    print(con.execute("SHOW TABLES").fetchall())

    print("\nExemplo de SELECT em Cliente:")
    print(con.execute("SELECT * FROM Cliente LIMIT 5").fetchdf())

    print("Fechando conexão com o banco...")
    con.close()
