-- Executar uma vez em um banco de treinamento. Se o schema existir, parar.
BEGIN;
CREATE SCHEMA bdadosql;
SET search_path TO bdadosql, public;

CREATE TABLE clientes (
    id INTEGER PRIMARY KEY,
    nome VARCHAR(60) NOT NULL,
    cidade VARCHAR(50) NOT NULL,
    uf CHAR(2) NOT NULL,
    email VARCHAR(100),
    ativo BOOLEAN DEFAULT true
);
INSERT INTO clientes (id,nome,cidade,uf,email,ativo) VALUES
(1,'Ana Silva','Curitiba','PR','ana@example.test',true),
(2,'Bruno Costa','Londrina','PR',NULL,false),
(3,'Carla Souza','São Paulo','SP','carla@example.test',true),
(4,'Diego Lima','Curitiba','PR',NULL,true),
(5,'Ana Paula','Santos','SP','anapaula@example.test',false),
(6,'Fabio D''Avila','Recife','PE',NULL,true);

CREATE TABLE vendedores (id INTEGER PRIMARY KEY, nome VARCHAR(60) NOT NULL);
INSERT INTO vendedores VALUES (1,'Marcos'),(2,'Julia');

CREATE TABLE produtos (
    id INTEGER PRIMARY KEY,
    nome VARCHAR(60) NOT NULL,
    categoria VARCHAR(30),
    preco NUMERIC(10,2) NOT NULL
);
INSERT INTO produtos VALUES
(1,'Mouse','Perifericos',50.00),
(2,'Teclado','Perifericos',150.00),
(3,'Monitor','Telas',900.00),
(4,'Headset','Audio',250.00),
(5,'Webcam','Video',500.00);

CREATE TABLE pedidos (
    id INTEGER PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    vendedor_id INTEGER NOT NULL REFERENCES vendedores(id),
    data_pedido DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    valor_total NUMERIC(12,2) NOT NULL,
    desconto NUMERIC(10,2)
);
-- valor_total = soma dos itens; desconto é informativo e não está deduzido.
INSERT INTO pedidos VALUES
(101,1,1,'2026-04-01','pago',250.00,10.00),
(102,1,2,'2026-04-02','pago',900.00,NULL),
(103,2,1,'2026-04-03','pendente',150.00,0.00),
(104,3,2,'2026-04-04','pago',500.00,20.00),
(105,3,2,'2026-04-05','cancelado',50.00,NULL),
(106,4,1,'2026-04-06','pendente',500.00,0.00),
(107,5,1,'2026-04-07','pago',200.00,10.00),
(108,1,2,'2026-04-08','pendente',50.00,NULL);

CREATE TABLE itens (
    pedido_id INTEGER REFERENCES pedidos(id),
    produto_id INTEGER REFERENCES produtos(id),
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (pedido_id,produto_id)
);
INSERT INTO itens VALUES
(101,1,2,50.00),(101,2,1,150.00),
(102,3,1,900.00),(103,2,1,150.00),
(104,5,1,500.00),(105,1,1,50.00),
(106,4,2,250.00),
(107,1,1,50.00),(107,2,1,150.00),
(108,1,1,50.00);
COMMIT;

SELECT 'clientes' AS tabela, COUNT(*) AS linhas FROM bdadosql.clientes
UNION ALL SELECT 'vendedores',COUNT(*) FROM bdadosql.vendedores
UNION ALL SELECT 'produtos',COUNT(*) FROM bdadosql.produtos
UNION ALL SELECT 'pedidos',COUNT(*) FROM bdadosql.pedidos
UNION ALL SELECT 'itens',COUNT(*) FROM bdadosql.itens;
-- Esperado: clientes 6; vendedores 2; produtos 5; pedidos 8; itens 10.








