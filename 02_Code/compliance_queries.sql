-- =================================================================================
-- compliance_queries.sql
-- Contém:
--  2.1 Identificação de discrepâncias (DuckDB + BigQuery)
--  2.2 Anomalias em impostos por categoria (DuckDB + BigQuery)
--  2.3 Snapshot reprocessável (DuckDB script + BigQuery procedure)
-- =================================================================================

/* ============================================================================
   NOTE:
   - As versões DuckDB (para testes locais) estão habilitadas (sem comentários).
   - As versões BigQuery estão logo abaixo de cada bloco, comentadas e prontas para copiar/colar em BigQuery (ajuste project.dataset).
   - As versões BigQuery não foram testadas, recomenda-se teste antes de sua utilização.
   - Ajuste nomes de tabelas se necessário.
   - Como na tabela item não tem status, foi assumido que se item existe na tabela seu status é ativo, caso contrário não pode ser assumido o status dele.
   ============================================================================ */

-- =====================================================================
-- 2.1 IDENTIFICAÇÃO DE DISCREPÂNCIAS (DuckDB)
-- Lista os 10 pedidos com maior diferença entre total_paid (Pedido)
-- e issued_amount (Invoice) para o último trimestre.
-- Obs.: Foi feito a listagem e ordenação pelo valor absoluto mas também há possibilidade de ser considerando o sinal da diferença.
-- Testado usando duckdb, para adequação ao BigQuery observar comentários linha a linha
-- =====================================================================
-- >>> BLOCK 2.1 START
SELECT
  p.order_id,
  p.order_date,
  p.total_paid,
  i.issued_amount AS issued_amount,
  (COALESCE(p.total_paid,0.0) - COALESCE(i.issued_amount,0.0)) AS diferenca, -- BigQuery adapt: SAFE_SUBTRACT(p.total_paid, i.issued_amount) AS diferenca,
  ABS(COALESCE(p.total_paid,0.0) - COALESCE(i.issued_amount,0.0)) AS abs_diferenca -- BigQuery adapt: ABS(SAFE_SUBTRACT(p.total_paid, i.issued_amount)) AS abs_diferenca,
FROM (
    SELECT *
    FROM Pedido -- BigQuery adapt: FROM `project.dataset.Pedido`
    WHERE order_date >= (current_date - INTERVAL '3 months') -- BigQuery adapt: DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)
) p -- Filtrando Pedido para otimizar o join.
LEFT JOIN Invoice i -- BigQuery adapt: LEFT JOIN 'project.dataset.Invoice' i
  ON p.order_id = i.order_id
-- considerar faturas emitidas; também mostra pedidos sem invoice (i.issue IS NULL)
WHERE (i.status = 'emitida' OR i.invoice_id IS NULL)
ORDER BY abs_diferenca DESC
LIMIT 10;
-- >>> BLOCK 2.1 END

-- =====================================================================
-- 2.2 ANOMALIAS EM IMPOSTOS POR CATEGORIA (DuckDB)
-- Calcula taxa média (tax_rate) por categoria no último mês e compara
-- com média do ano anterior. Mostra 3 categorias com maior desvio absoluto.
-- Obs.: Testado usando duckdb, para adequação ao BigQuery observar comentários linha a linha
-- Não há limitações para caso não tenha os dados de categoria e itens nos intervalos pedidos.
-- =====================================================================
-- >>> BLOCK 2.2 START
SELECT
    tm.category_id,
    c.name AS category_name,
    tm.avg_tax_month,
    py.avg_tax_prev_year,
    (tm.avg_tax_month - py.avg_tax_prev_year) AS desvio, -- BigQuery adapt: SAFE_SUBTRACT(tm.avg_tax_month, py.avg_tax_prev_year) AS desvio
    ABS(tm.avg_tax_month - py.avg_tax_prev_year) AS abs_desvio -- BigQuery adapt: ABS(SAFE_SUBTRACT(tm.avg_tax_month, py.avg_tax_prev_year)) AS abs_desvio
FROM (
    SELECT
        category_id,
        AVG(tax_rate) AS avg_tax_month
    FROM TaxCalculation
    WHERE calculation_date >= date_trunc('month', current_date - INTERVAL '1 month') -- BigQuery adapt: calculation_date >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH)
      AND calculation_date < date_trunc('month', current_date) -- BigQuery adapt: calculation_date < DATE_TRUNC(CURRENT_DATE(), MONTH)
    GROUP BY category_id
) AS tm
LEFT JOIN (
    SELECT
        category_id,
        AVG(tax_rate) AS avg_tax_prev_year
    FROM TaxCalculation -- BigQuery adapt: FROM `project.dataset.TaxCalculation`
    WHERE EXTRACT(year FROM calculation_date) = EXTRACT(year FROM current_date) - 1 -- BigQuery adapt: WHERE EXTRACT(YEAR FROM DATE(calculation_date)) = EXTRACT(YEAR FROM CURRENT_DATE()) - 1 -- BigQuery adapt
    GROUP BY category_id
) AS py
    ON tm.category_id = py.category_id
LEFT JOIN Categoria c -- BigQuery adapt: LEFT JOIN `project.dataset.Categoria` c
    ON tm.category_id = c.category_id
ORDER BY abs_desvio DESC
LIMIT 3;
-- >>> BLOCK 2.2 END

-- =====================================================================
-- 2.3 ESTADO DE ITENS REPROCESSÁVEL (DuckDB script)
-- Cria a sequência de audit (se não existir)
-- Cria tabela audit (se não existir), remove snapshot do dia e insere novo
-- (DELETE + INSERT = idempotente). Usa CURRENT_DATE como data_snapshot.
-- Obs. Testado usando duckdb, para adequação ao BigQuery observar bloco de código após bloco existente
-- Escolha: Ao remover o dia e inserir novamente garante que não terá duplicados ou inconsistências. Entretanto, perdemos as variações ao longo do dia.
-- Dada a abertura do enunciado, foi escolhido manter registros diários para evitar crescimento exponencial da tabela mesmo que
-- tenha perdas de variações dentro do mesmo dia.
-- Limitações: Para tabelas muito grandes, o processo de deletar e inserir pode ser demorado e custoso. Há outras limitações, por exemplo,
-- reprocessamento em horários distintos.
-- =====================================================================
-- >>> BLOCK 2.3 START
-- Criação da tabela sequencial
CREATE SEQUENCE IF NOT EXISTS item_audit_seq START 1; -- BigQuery adapt: Can be erased.

CREATE TABLE IF NOT EXISTS item_audit ( 
  audit_id INTEGER PRIMARY KEY DEFAULT nextval('item_audit_seq'), -- BigQuery adapt: audit_id STRING DEFAULT GENERATE_UUID(),
  item_id INTEGER,
  unit_price REAL,
  status TEXT,
  data_snapshot DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- BigQuery adapt: created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Operação idempotente: apagar snapshot do dia e inserir novo
BEGIN TRANSACTION; -- BigQuery adapt: pode ser omitido (BigQuery não suporta BEGIN/COMMIT dessa forma)

DELETE FROM item_audit
WHERE data_snapshot = current_date; -- BigQuery adapt: CURRENT_DATE()

-- Inserção de todos os itens (ativos e unknown) em um único scan
INSERT INTO item_audit (item_id, unit_price, status, data_snapshot)
SELECT
    i.item_id,
    i.price AS unit_price,
    'ativo' AS status,
    current_date AS data_snapshot -- BigQuery adapt: CURRENT_DATE()
FROM Item i -- BigQuery adapt: FROM `project.dataset.Item`

UNION ALL

SELECT
    pi.item_id,
    NULL AS unit_price,
    'unknown' AS status, 
    current_date AS data_snapshot -- BigQuery adapt: CURRENT_DATE()
FROM (
    SELECT DISTINCT item_id
    FROM PedidoItem -- BigQuery adapt: FROM `project.dataset.PedidoItem`
    EXCEPT
    SELECT item_id FROM Item -- BigQuery adapt: SELECT item_id FROM `project.dataset.Item`
) pi;

COMMIT; -- BigQuery adapt: pode ser omitido
-- >>> BLOCK 2.3 END