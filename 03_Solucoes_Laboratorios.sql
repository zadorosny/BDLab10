-- SOLUÇÕES: consulte após tentar. Executar por laboratório, na ordem das tarefas.
-- Não executar o arquivo inteiro como uma transação: VACUUM exige autocommit.
-- L11.4 contém uma tentativa duplicada comentada para execução manual isolada.
SET search_path TO bdadosql, public;

-- L3.1
CREATE TABLE contatos_lab3 (
 id INTEGER, nome VARCHAR(50), cidade VARCHAR(50), uf CHAR(2), idade INTEGER
);
INSERT INTO contatos_lab3 (id,nome,cidade,uf,idade) VALUES
(1,'Ana','Curitiba','PR',22),(2,'Bruno','Londrina','PR',31),
(3,'Carla','São Paulo','SP',27),(4,'Diego','Curitiba','PR',19),
(5,'Elisa','Santos','SP',35),(6,'Fabio','Recife','PE',27);
-- L3.2: seis linhas.
SELECT nome,cidade FROM contatos_lab3 ORDER BY id;
-- L3.3: Ana (1) e Bruno (2).
SELECT * FROM contatos_lab3 WHERE uf='PR' AND idade>=20 AND idade<=31 ORDER BY id;
-- L3.4: Elisa, Bruno, Carla, Fabio, Ana, Diego.
SELECT * FROM contatos_lab3 ORDER BY idade DESC,nome;
-- L3.5: uma linha atualizada.
SELECT * FROM contatos_lab3 WHERE id=2;
UPDATE contatos_lab3 SET cidade='Maringá' WHERE id=2;
SELECT * FROM contatos_lab3 WHERE id=2;
-- L3.6: uma linha excluída (Diego).
SELECT * FROM contatos_lab3 WHERE idade<20;
DELETE FROM contatos_lab3 WHERE idade<20;
SELECT * FROM contatos_lab3 ORDER BY id;
-- L3.7: DELETE deixa a tabela vazia; DROP remove a tabela.
CREATE TABLE rascunho_lab3 (id INTEGER);
INSERT INTO rascunho_lab3 VALUES (1);
DELETE FROM rascunho_lab3;
SELECT * FROM rascunho_lab3;
DROP TABLE rascunho_lab3;
-- L3.8: ids 1,2,3,5,6; Bruno em Maringá.
SELECT * FROM contatos_lab3 ORDER BY id;

-- L4.1: ids 2,4,6 na primeira; zero linhas na segunda.
SELECT id,nome,email FROM clientes WHERE email IS NULL ORDER BY id;
SELECT id,nome,email FROM clientes WHERE email=NULL ORDER BY id;
-- L4.2: pendente, pendente, NULL.
CREATE TABLE config_lab4 (
 id INTEGER, descricao VARCHAR(50), status VARCHAR(20) DEFAULT 'pendente'
);
INSERT INTO config_lab4 (id,descricao) VALUES (1,'D''Avila');
INSERT INTO config_lab4 (id,descricao,status) VALUES (2,'teste default',DEFAULT);
INSERT INTO config_lab4 (id,descricao,status) VALUES (3,'teste nulo',NULL);
SELECT * FROM config_lab4 ORDER BY id;
-- L4.3: correta ids 1,3,4; sem parênteses inclui também 2 (inativo do PR).
SELECT * FROM clientes WHERE (uf='PR' OR uf='SP') AND ativo=true ORDER BY id;
SELECT * FROM clientes WHERE uf='PR' OR uf='SP' AND ativo=true ORDER BY id;
-- L4.4: produtos 2,4,5; clientes 1,2,4,6.
SELECT * FROM produtos WHERE preco BETWEEN 100 AND 500 ORDER BY id;
SELECT * FROM clientes WHERE uf IN ('PR','PE') ORDER BY id;
-- L4.5: LIKE ids 1,5; regex ids 1,2,5.
SELECT id,nome FROM clientes WHERE nome LIKE 'Ana%' ORDER BY id;
SELECT id,nome FROM clientes WHERE nome ~ '^[AB]' ORDER BY id;
-- L4.6: cinco pares cidade/UF; Curitiba aparece uma vez.
SELECT DISTINCT cidade,uf FROM clientes ORDER BY uf,cidade;
/* upper modifica a apresentação, sem atualizar o cadastro. */
SELECT id,upper(nome) AS nome_maiusculo FROM clientes ORDER BY id;
-- L4.7: baixo, medio, alto, medio, medio.
SELECT id,nome,preco,
 CASE WHEN preco<100 THEN 'baixo' WHEN preco<=500 THEN 'medio' ELSE 'alto' END AS faixa
FROM produtos ORDER BY id;
-- L4.8: guarde o valor inicial antes de alterar.
SHOW DateStyle;
SET DateStyle TO 'SQL, DMY';
SELECT DATE '2026-10-16'; -- 16/10/2026 no estilo escolhido.
RESET DateStyle;
SHOW DateStyle;
SELECT DATE '2026-10-16';

-- L5.1: 8; 2600.00; 325.00; 50.00; 900.00.
SELECT COUNT(*) AS quantidade,SUM(valor_total) AS total,
 round(AVG(valor_total),2) AS media,MIN(valor_total) AS minimo,MAX(valor_total) AS maximo
FROM pedidos;
-- L5.2: 8; 5; 8.00. Nulos não entram na média; zeros entram.
SELECT COUNT(*),COUNT(desconto),AVG(desconto) FROM pedidos;
-- L5.3: cancelado 1/50; pago 4/1850; pendente 3/700.
SELECT status,COUNT(*) AS quantidade,SUM(valor_total) AS total
FROM pedidos GROUP BY status ORDER BY status;
-- L5.4: cliente 1:3/1200; 3:2/550; 4:1/500; 5:1/200; 2:1/150.
SELECT cliente_id,COUNT(*) AS quantidade,SUM(valor_total) AS total
FROM pedidos GROUP BY cliente_id ORDER BY total DESC,cliente_id;
-- L5.5: clientes 1 (3 pedidos) e 3 (2 pedidos).
SELECT cliente_id,COUNT(*) AS quantidade FROM pedidos
GROUP BY cliente_id HAVING COUNT(*)>1 ORDER BY cliente_id;
-- L5.6: cliente 1:1150; cliente 3:500.
SELECT cliente_id,SUM(valor_total) AS total_pago FROM pedidos
WHERE status='pago' GROUP BY cliente_id HAVING SUM(valor_total)>400 ORDER BY cliente_id;
-- L5.7: PE/Recife 1; PR/Curitiba 2; PR/Londrina 1; SP/Santos 1; SP/São Paulo 1.
SELECT uf,cidade,COUNT(*) FROM clientes GROUP BY uf,cidade ORDER BY uf,cidade;
-- L5.8: sem GROUP BY: uma linha (0,NULL,NULL); com GROUP BY: zero linhas.
SELECT COUNT(*),SUM(valor_total),AVG(valor_total) FROM pedidos WHERE status='inexistente';
SELECT status,COUNT(*),SUM(valor_total),AVG(valor_total)
FROM pedidos WHERE status='inexistente' GROUP BY status;

-- L6.1: oito linhas, pedidos 101 a 108.
SELECT p.id AS pedido,c.nome AS cliente,p.valor_total
FROM pedidos p JOIN clientes c ON c.id=p.cliente_id ORDER BY p.id;
-- L6.2: oito linhas.
SELECT p.id AS pedido,c.nome AS cliente,v.nome AS vendedor
FROM pedidos p JOIN clientes c ON c.id=p.cliente_id
JOIN vendedores v ON v.id=p.vendedor_id ORDER BY p.id;
-- L6.3: dez linhas. Pedido 101: Mouse 2/100; Teclado 1/150.
SELECT p.id AS pedido,c.nome AS cliente,pr.nome AS produto,i.quantidade,
 i.quantidade*i.preco_unitario AS subtotal
FROM pedidos p JOIN clientes c ON c.id=p.cliente_id
JOIN itens i ON i.pedido_id=p.id JOIN produtos pr ON pr.id=i.produto_id
ORDER BY p.id,pr.id;
-- L6.4: oito linhas; todas as colunas confere = true; totais somam 2600.
SELECT p.id,p.valor_total,SUM(i.quantidade*i.preco_unitario) AS soma_itens,
 p.valor_total=SUM(i.quantidade*i.preco_unitario) AS confere
FROM pedidos p JOIN itens i ON i.pedido_id=p.id
GROUP BY p.id,p.valor_total ORDER BY p.id;
-- Somar p.valor_total após o JOIN com itens contaria pedidos 101 e 107 duas vezes.
-- L6.5: cartesiano 48; join correto 8. Fabio (id 6) não tem pedidos.
SELECT COUNT(*) FROM clientes CROSS JOIN pedidos;
SELECT COUNT(*) FROM clientes c JOIN pedidos p ON p.cliente_id=c.id;
SELECT DISTINCT c.id,c.nome FROM clientes c JOIN pedidos p ON p.cliente_id=c.id ORDER BY c.id;
-- L6.6: só o par (1,4), Ana Silva e Diego Lima, de Curitiba/PR.
SELECT a.id AS id_a,a.nome AS cliente_a,b.id AS id_b,b.nome AS cliente_b,a.cidade,a.uf
FROM clientes a JOIN clientes b ON a.cidade=b.cidade AND a.uf=b.uf AND a.id<b.id
ORDER BY a.id,b.id;
-- L6.7: Mouse (id 1), 50.00.
SELECT p.id,p.nome,p.preco FROM produtos p
JOIN produtos ref ON p.preco<ref.preco WHERE ref.id=2 ORDER BY p.preco,p.id;
-- L6.8: quatro linhas para cliente 1; duas para pedido 101.
SELECT p.id AS pedido,c.nome AS cliente,v.nome AS vendedor,
 pr.id AS produto_id,pr.nome AS produto,i.quantidade,i.preco_unitario
FROM pedidos p JOIN clientes c ON c.id=p.cliente_id
JOIN vendedores v ON v.id=p.vendedor_id JOIN itens i ON i.pedido_id=p.id
JOIN produtos pr ON pr.id=i.produto_id WHERE c.id=1 ORDER BY p.id,pr.id;
SELECT pr.id,pr.nome,i.quantidade FROM itens i
JOIN produtos pr ON pr.id=i.produto_id WHERE i.pedido_id=101 ORDER BY pr.id;
-- FKs garantem referências válidas ao cabeçalho e ao produto;
-- a condição ON continua necessária em cada ligação escrita na consulta.

-- LAB 11: executar 02_Lab11_Preparacao.sql antes deste trecho.
-- L11.1: cada EXPLAIN abaixo deve ser executado 3 vezes e registrado.
SELECT version();
ANALYZE eventos_lab11;
SELECT pg_size_pretty(pg_table_size('bdadosql.eventos_lab11')) AS tabela,
 pg_size_pretty(pg_indexes_size('bdadosql.eventos_lab11')) AS indices;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_lab11 WHERE id=150000;
-- L11.2: busca retorna uma linha. Plano e tempo dependem do ambiente.
CREATE INDEX eventos_lab11_id_idx ON eventos_lab11 (id);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_lab11 WHERE id=150000;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_lab11;
-- L11.3: antes das alterações L11.6, cliente 42 tem 200 eventos;
-- cliente 42 no intervalo: 6 eventos; só o intervalo: 5480 eventos.
CREATE INDEX eventos_lab11_cliente_data_idx ON eventos_lab11 (cliente_id,data_evento);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_lab11 WHERE cliente_id=42;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_lab11
WHERE cliente_id=42 AND data_evento BETWEEN DATE '2026-04-01' AND DATE '2026-04-10';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_lab11
WHERE data_evento BETWEEN DATE '2026-04-01' AND DATE '2026-04-10';
-- L11.4: executar manualmente a linha comentada e guardar o erro 23505.
CREATE UNIQUE INDEX codigos_lab11_codigo_idx ON codigos_lab11 (codigo);
INSERT INTO codigos_lab11 VALUES (10);
-- INSERT INTO codigos_lab11 VALUES (10); -- erro esperado: duplicação de chave.
INSERT INTO codigos_lab11 VALUES (NULL),(NULL);
SELECT codigo FROM codigos_lab11 ORDER BY codigo NULLS LAST; -- 10,NULL,NULL.
-- L11.5: não há ganho obrigatório; repetir medições antes/depois.
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_lab11
WHERE cliente_id=42 AND data_evento BETWEEN DATE '2026-04-01' AND DATE '2026-04-10';
CLUSTER bdadosql.eventos_lab11 USING eventos_lab11_cliente_data_idx;
ANALYZE bdadosql.eventos_lab11;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_lab11
WHERE cliente_id=42 AND data_evento BETWEEN DATE '2026-04-01' AND DATE '2026-04-10';
SELECT indexrelid::regclass AS indice,indisclustered FROM pg_index
WHERE indrelid='bdadosql.eventos_lab11'::regclass;
-- L11.6: 40000 atualizações; 20000 exclusões; restam 180000 linhas.
UPDATE eventos_lab11 SET status='revisado' WHERE id<=40000;
DELETE FROM eventos_lab11 WHERE id>180000;
SELECT COUNT(*) FROM eventos_lab11;
SELECT pg_table_size('bdadosql.eventos_lab11') AS bytes_tabela,
 pg_indexes_size('bdadosql.eventos_lab11') AS bytes_indices;
-- EXECUTAR ESTE VACUUM ISOLADAMENTE, EM AUTOCOMMIT:
VACUUM (VERBOSE, ANALYZE) bdadosql.eventos_lab11;
SELECT COUNT(*) FROM eventos_lab11;
SELECT pg_table_size('bdadosql.eventos_lab11') AS bytes_tabela,
 pg_indexes_size('bdadosql.eventos_lab11') AS bytes_indices;
-- Tamanho final e quantidade de versões limpas dependem do ambiente/autovacuum.
-- L11.7: exemplo de filtro; compare estimates e actual rows no plano real.
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_lab11 WHERE cliente_id=42;
SELECT attname,n_distinct,most_common_vals,most_common_freqs FROM pg_stats
WHERE schemaname='bdadosql' AND tablename='eventos_lab11' AND attname='cliente_id';
-- L11.8: meça antes de remover; remova só o índice indicado.
SELECT indexrelid::regclass AS indice,pg_size_pretty(pg_relation_size(indexrelid)) AS tamanho
FROM pg_index WHERE indrelid='bdadosql.eventos_lab11'::regclass;
DROP INDEX bdadosql.eventos_lab11_id_idx;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_lab11 WHERE id=150000;
-- Relatório: hipótese, plano anterior/posterior, três medições, buffers,
-- tamanho dos índices, conclusão e limitações (cache, carga e estatísticas).
