-- NÍVEL 2: executar UMA VEZ, como script, no DBeaver.
-- Banco de treinamento já conectado; Auto-commit ativo.
-- Não depende do nível 1. Se bdadosql_n2 já existir, pare e confira o estado.
-- Em erro dentro desta transação: interrompa o script e execute ROLLBACK.
BEGIN;
CREATE SCHEMA bdadosql_n2;
SET search_path TO bdadosql_n2, public;

CREATE TABLE clientes (
 id integer PRIMARY KEY,
 nome text NOT NULL,
 uf char(2) NOT NULL,
 email text,
 ativo boolean NOT NULL DEFAULT true
);
INSERT INTO clientes VALUES
 (1,'Ana Silva','PR',' ANA@EXAMPLE.TEST ',true),
 (2,'Bruno Costa','PR',NULL,false),
 (3,'Carla Souza','SP','carla@example.test',true),
 (4,'Diego Lima','PR','   ',true),
 (5,'Elisa Santos','SP','elisa@example.test',true),
 (6,'Fabio D''Avila','PE',NULL,true),
 (7,'Gabriela Alves','PE','gabi@example.test',false),
 (8,'Hugo Reis','RS','hugo@example.test',true);

CREATE TABLE produtos (
 id integer PRIMARY KEY, nome text NOT NULL,
 preco numeric(12,2) NOT NULL CHECK (preco >= 0)
);
INSERT INTO produtos VALUES
 (1,'Mouse',50),(2,'Teclado',150),(3,'Monitor',900),
 (4,'Headset',250),(5,'Webcam',500),(6,'Cabo_100%',30);

CREATE TABLE pedidos (
 id integer PRIMARY KEY,
 cliente_id integer NOT NULL REFERENCES clientes(id),
 data_pedido date NOT NULL,
 status text NOT NULL CHECK (status IN ('pago','pendente','cancelado')),
 valor_total numeric(12,2) NOT NULL CHECK (valor_total >= 0),
 desconto numeric(12,2) CHECK (desconto >= 0 AND desconto <= valor_total)
);
-- Regra dos relatórios: NULL em desconto é desconhecido no cadastro,
-- mas será tratado como zero SOMENTE no cálculo financeiro solicitado.
-- valor_total é bruto, antes do desconto; preço do item é histórico.
INSERT INTO pedidos VALUES
 (101,1,'2026-01-05','pago',250,10),
 (102,1,'2026-01-15','pago',900,NULL),
 (103,2,'2026-01-20','pendente',150,0),
 (104,3,'2026-02-02','pago',500,20),
 (105,3,'2026-02-04','cancelado',50,NULL),
 (106,4,'2026-02-10','pendente',500,0),
 (107,5,'2026-03-01','pago',200,10),
 (108,1,'2026-03-10','pendente',50,NULL),
 (109,6,'2026-03-15','pago',300,0),
 (110,5,'2026-04-01','pago',150,0),
 (111,4,'2026-04-10','cancelado',900,0),
 (112,3,'2026-04-15','pendente',100,0);

CREATE TABLE itens (
 pedido_id integer REFERENCES pedidos(id),
 produto_id integer REFERENCES produtos(id),
 quantidade integer NOT NULL CHECK (quantidade > 0),
 preco_unitario numeric(12,2) NOT NULL CHECK (preco_unitario >= 0),
 PRIMARY KEY (pedido_id,produto_id)
);
INSERT INTO itens VALUES
 (101,1,2,50),(101,2,1,150),(102,3,1,900),(103,2,1,150),
 (104,5,1,500),(105,1,1,50),(106,4,2,250),
 (107,1,1,50),(107,2,1,150),(108,1,1,50),
 (109,4,1,250),(109,1,1,50),(110,2,1,150),
 (111,3,1,900),(112,1,2,50);

CREATE TABLE pagamentos (
 id integer PRIMARY KEY, pedido_id integer NOT NULL REFERENCES pedidos(id),
 data_pagamento date NOT NULL,
 tipo text NOT NULL CHECK (tipo IN ('recebimento','estorno')),
 valor numeric(12,2) NOT NULL CHECK (valor > 0)
);
-- Estorno é armazenado positivo; o relatório deve subtraí-lo.
INSERT INTO pagamentos VALUES
 (1,101,'2026-01-05','recebimento',100),
 (2,101,'2026-01-06','recebimento',140),
 (3,102,'2026-01-15','recebimento',900),
 (4,103,'2026-01-20','recebimento',50),
 (5,104,'2026-02-02','recebimento',500),
 (6,104,'2026-02-03','estorno',20),
 (7,106,'2026-02-10','recebimento',200),
 (8,106,'2026-02-11','recebimento',100),
 (9,107,'2026-03-01','recebimento',190),
 (10,109,'2026-03-15','recebimento',300),
 (11,110,'2026-04-01','recebimento',150),
 (12,112,'2026-04-15','recebimento',120);

CREATE TABLE estoques (
 produto_id integer REFERENCES produtos(id),
 deposito text CHECK (deposito IN ('A','B')),
 saldo integer NOT NULL CHECK (saldo >= 0),
 PRIMARY KEY (produto_id,deposito)
);
INSERT INTO estoques VALUES (1,'A',10),(1,'B',5);

CREATE TABLE importacao_contatos (
 lote_id integer PRIMARY KEY, cliente_id integer NOT NULL,
 nome text, email text, uf text
);
INSERT INTO importacao_contatos VALUES
 (1,1,' Ana Silva ',' ANA@EXAMPLE.TEST ','pr'),
 (2,2,'Bruno Costa',' ','pr'),
 (3,3,'Carla Souza','carla@example.test','SP'),
 (4,3,'Carla Nova',' CARLA@EXAMPLE.TEST ','sp'),
 (5,9,'Ivan','ivan@example.test','rj'),
 (6,10,'Ines','invalido','sc'),
 (7,11,'Julia','julia@example.test','XX');
CREATE TABLE contatos_tratados (
 cliente_id integer PRIMARY KEY, nome text NOT NULL,
 email text, uf char(2) NOT NULL CHECK (uf IN ('PR','SP','PE','RS','RJ','SC'))
);

CREATE TABLE acessos (id integer PRIMARY KEY, ocorrido_em timestamptz NOT NULL);
INSERT INTO acessos VALUES
 (1,'2026-03-01 02:59:59+00'),(2,'2026-03-01 03:00:00+00'),
 (3,'2026-04-01 02:59:59+00'),(4,'2026-04-01 03:00:00+00');
COMMIT;

-- 8 clientes; 6 produtos; 12 pedidos; 15 itens; 12 pagamentos;
-- 2 estoques; 7 importações; 0 contatos tratados; 4 acessos.
SELECT 'clientes' AS tabela, count(*) AS linhas FROM bdadosql_n2.clientes
UNION ALL SELECT 'produtos',count(*) FROM bdadosql_n2.produtos
UNION ALL SELECT 'pedidos',count(*) FROM bdadosql_n2.pedidos
UNION ALL SELECT 'itens',count(*) FROM bdadosql_n2.itens
UNION ALL SELECT 'pagamentos',count(*) FROM bdadosql_n2.pagamentos
UNION ALL SELECT 'estoques',count(*) FROM bdadosql_n2.estoques
UNION ALL SELECT 'importacao_contatos',count(*) FROM bdadosql_n2.importacao_contatos
UNION ALL SELECT 'contatos_tratados',count(*) FROM bdadosql_n2.contatos_tratados
UNION ALL SELECT 'acessos',count(*) FROM bdadosql_n2.acessos;
