-- =================================================================================
-- compliance_queries.sql
-- Contém:
--  2.1 Identificação de discrepâncias (DuckDB + BigQuery)
--  2.2 Anomalias em impostos por categoria (DuckDB + BigQuery)
--  2.3 Snapshot reprocessável (DuckDB script + BigQuery procedure)
-- =================================================================================

/* ============================================================================
   NOTE:
   - As versões DuckDB estão em arquivo apartado - _duckdb.
   - As versões BigQuery estão logo abaixo.
   - As versões BigQuery foram testadas em dataset nomeado meli.
   - Ajuste nomes de tabelas se necessário.
   - Como na tabela item não tem status, foi assumido que se item existe na tabela seu status é ativo, caso contrário não pode ser assumido o status dele.
   ============================================================================ */

-- =====================================================================
-- 2.1 IDENTIFICAÇÃO DE DISCREPÂNCIAS (DuckDB)
-- Lista os 10 pedidos com maior diferença entre total_paid (Pedido) e issued_amount (Invoice) para o último trimestre.
-- Obs.: Foi feito a listagem e ordenação pelo valor absoluto mas também há possibilidade de ser considerando o sinal da diferença.
-- ============================================
-- ÚLTIMOS 3 MESES E DIFERENÇAS DE PREÇO
-- ============================================
SELECT
  p.order_id,
  p.order_date,
  p.total_paid,
  i.issued_amount AS issued_amount,
  SAFE_SUBTRACT(p.total_paid, i.issued_amount) AS diferenca,
  ABS(SAFE_SUBTRACT(p.total_paid, i.issued_amount)) AS abs_diferenca
FROM (
    SELECT *
    FROM `meli.Pedido` AS p
    WHERE DATE(p.order_date) >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)
) p
-- ============================================
-- CRUZANDO COM INVOICE EMITIDA OU PEDIDO SEM INVOICE
-- ============================================
LEFT JOIN `meli.Invoice` i
  ON p.order_id = i.order_id
-- considerar faturas emitidas; também mostra pedidos sem invoice (i.issue IS NULL)
WHERE (i.status = 'emitida' OR i.invoice_id IS NULL)
-- ============================================
-- ORDENANDO E SELECIONANDO TOP 10
-- ============================================
ORDER BY abs_diferenca DESC
LIMIT 10;

-- =====================================================================
-- 2.2 ANOMALIAS EM IMPOSTOS POR CATEGORIA (DuckDB)
-- Calcula taxa média (tax_rate) por categoria no último mês e compara com média do ano anterior. Mostra 3 categorias com maior desvio absoluto.
-- Não há limitações para caso não tenha os dados de categoria e itens nos intervalos pedidos.
-- ============================================
-- MÉDIA DO MÊS ANTERIOR POR CATEGORIA (tm)
-- ============================================
SELECT
    tm.category_id,
    c.name AS category_name,
    tm.avg_tax_month,
    py.avg_tax_prev_year,
    SAFE_SUBTRACT(tm.avg_tax_month, py.avg_tax_prev_year) AS desvio,
    ABS(SAFE_SUBTRACT(tm.avg_tax_month, py.avg_tax_prev_year)) AS abs_desvio
FROM (
    SELECT
        category_id,
        AVG(tax_rate) AS avg_tax_month
    FROM `meli.TaxCalculation`
    WHERE DATE(calculation_date) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH)
      AND DATE(calculation_date) < DATE_TRUNC(CURRENT_DATE(), MONTH)
    GROUP BY category_id
) AS tm
-- ============================================
-- MÉDIA DO ANO ANTERIOR POR CATEGORIA (py)
-- ============================================
LEFT JOIN (
    SELECT
        category_id,
        AVG(tax_rate) AS avg_tax_prev_year
    FROM `meli.TaxCalculation` 
    WHERE EXTRACT(YEAR FROM DATE(calculation_date)) = EXTRACT(YEAR FROM CURRENT_DATE()) - 1
    GROUP BY category_id
) AS py
    ON tm.category_id = py.category_id
LEFT JOIN `meli.Categoria` c
    ON tm.category_id = c.category_id
-- ============================================
-- ORDENANDO E SELECIONANDO TOP 3 
-- ============================================
ORDER BY abs_desvio DESC
LIMIT 3;

-- =====================================================================
-- 2.3 ESTADO DE ITENS REPROCESSÁVEL (DuckDB script)
-- Cria a sequência de audit (se não existir)
-- Cria tabela audit (se não existir), remove snapshot do dia e insere novo
-- (DELETE + INSERT = idempotente). Usa CURRENT_DATE como data_snapshot.
-- Escolha: Ao remover o dia e inserir novamente garante que não terá duplicados ou inconsistências. Entretanto, perdemos as variações ao longo do dia.
-- Dada a abertura do enunciado, foi escolhido manter registros diários para evitar crescimento exponencial da tabela mesmo que
-- tenha perdas de variações dentro do mesmo dia.
-- Limitações: Para tabelas muito grandes, o processo de deletar e inserir pode ser demorado e custoso. Há outras limitações, por exemplo,
-- reprocessamento em horários distintos. Também temos uma limitação de pedidos que venham a ser inseridos pós final do dia corrente.
-- Para rodar faça: CALL `meli.processa_item_audit`();
-- =====================================================================
CREATE OR REPLACE PROCEDURE `meli.processa_item_audit`()
BEGIN
-- ================================
-- 1) Criar tabela se não existir
-- ================================
CREATE TABLE IF NOT EXISTS `meli.item_audit` ( 
  audit_id STRING,
  item_id INT64,
  unit_price FLOAT64,
  status STRING,
  data_snapshot DATE,
  created_at TIMESTAMP 
);

-- ================================
-- 2) Apagar snapshot de hoje
-- ================================
DELETE FROM `meli.item_audit`
WHERE data_snapshot = CURRENT_DATE();

-- ================================
-- 3) Inserir itens ativos + unknown
-- ================================
INSERT INTO `meli.item_audit` (audit_id, item_id, unit_price, status, data_snapshot, created_at)
SELECT
    GENERATE_UUID(),
    i.item_id,
    i.price AS unit_price,
    'ativo' AS status,
    CURRENT_DATE() AS data_snapshot,
    CURRENT_TIMESTAMP() as created_at
FROM `meli.Item` i

UNION ALL

SELECT
    GENERATE_UUID(),
    pi.item_id,
    NULL AS unit_price,
    'unknown' AS status, 
    CURRENT_DATE() AS data_snapshot,
    CURRENT_TIMESTAMP() as created_at
FROM (
    SELECT DISTINCT item_id
    FROM `meli.PedidoItem`
    EXCEPT DISTINCT
    SELECT item_id FROM `meli.Item`
) pi;

-- ================================
-- 4) Retornar os 10 primeiros registros - Não necessário pós primeira rodada, apenas para verificar o que foi adicionado.
-- ================================
-- SELECT *
-- FROM `meli.item_audit`
-- WHERE data_snapshot = CURRENT_DATE()
-- ORDER BY created_at
-- LIMIT 10;

END;