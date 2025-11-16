-- Em resumo, ID's como chaves primárias para evitar duplicidade e algumas chaves extras para garantir informações importantes.
-- Por exemplo, itens e clientes existentes para cada pedido - Tabela 5(ln48).
-- =========================
-- 1. CLIENTE
-- =========================
CREATE TABLE Cliente (
    customer_id     INTEGER PRIMARY KEY, -- garante não duplicidade
    name            TEXT NOT NULL,
    email           TEXT NOT NULL,
    tax_id_type     TEXT NOT NULL,
    document        TEXT NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- 2. CATEGORIA
-- =========================
CREATE TABLE Categoria (
    category_id    INTEGER PRIMARY KEY, -- garante não duplicidade
    name           TEXT NOT NULL,
    description    TEXT
);

-- =========================
-- 3. ITEM 
-- =========================
CREATE TABLE Item (
    item_id        INTEGER PRIMARY KEY, -- garante não duplicidade
    name           TEXT NOT NULL,
    category_id    INTEGER NOT NULL,
    price          REAL NOT NULL,
    FOREIGN KEY (category_id) REFERENCES Categoria(category_id) -- garante categoria do item
);

-- =========================
-- 4. PEDIDO 
-- =========================
CREATE TABLE Pedido (
    order_id       INTEGER PRIMARY KEY, -- garante não duplicidade
    customer_id    INTEGER NOT NULL,
    order_date     TIMESTAMP NOT NULL,
    total_paid     REAL NOT NULL,
    status         TEXT NOT NULL,   -- criado, pago, cancelado
    FOREIGN KEY (customer_id) REFERENCES Cliente(customer_id) -- garante cliente do pedido
);

-- =========================
-- 5. PEDIDO_ITEM (ITENS DOS PEDIDOS)
-- =========================
CREATE TABLE PedidoItem (
    order_item_id  INTEGER PRIMARY KEY, -- garante não duplicidade
    order_id       INTEGER NOT NULL,
    item_id        INTEGER NOT NULL,
    quantity       INTEGER NOT NULL,
    unit_price     REAL NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Pedido(order_id),
    FOREIGN KEY (item_id) REFERENCES Item(item_id)
);

-- =========================
-- 6. FATURA (INVOICE)
-- =========================
CREATE TABLE Invoice (
    invoice_id             INTEGER PRIMARY KEY, -- garante não duplicidade
    order_id               INTEGER NOT NULL,
    issued_date            TIMESTAMP NOT NULL,
    issued_amount          REAL NOT NULL,
    status                 TEXT NOT NULL, -- emitida, pendente, anulada
    invoice_number         TEXT NOT NULL, 
    seller_tax_id_type     TEXT NOT NULL,
    buyer_tax_id_type      TEXT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Pedido(order_id)
);

-- =========================
-- 7. CÁLCULO DE IMPOSTOS
-- =========================
CREATE TABLE TaxCalculation (
    tax_id                    INTEGER PRIMARY KEY, -- garante não duplicidade
    invoice_id                INTEGER NOT NULL,
    category_id               INTEGER NOT NULL,
    tax_amount                REAL NOT NULL,
    tax_rate                  REAL NOT NULL,
    calculation_date          TIMESTAMP NOT NULL,
    FOREIGN KEY (invoice_id)  REFERENCES Invoice(invoice_id),
    FOREIGN KEY (category_id) REFERENCES Categoria(category_id)
);
