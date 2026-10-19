-- Conferências de leitura: execute após a preparação comercial, ou após N2-1 a N2-4.
-- O conteúdo comercial deve continuar inalterado; estoques e preço restaurados.
-- Não exige preparar nem executar o laboratório de desempenho.
SET search_path TO bdadosql_n2, public;
WITH recebido AS (
 SELECT pedido_id,SUM(CASE WHEN tipo='recebimento' THEN valor ELSE -valor END) AS valor
 FROM pagamentos GROUP BY pedido_id
), posicao AS (
 SELECT p.id,p.valor_total-COALESCE(p.desconto,0) AS contratado,
 COALESCE(r.valor,0) AS recebido,
 p.valor_total-COALESCE(p.desconto,0)-COALESCE(r.valor,0) AS saldo
 FROM pedidos p LEFT JOIN recebido r ON r.pedido_id=p.id WHERE p.status<>'cancelado'
), checks AS (
 SELECT 'clientes' AS verificacao,COUNT(*)::numeric AS obtido,8::numeric AS esperado FROM clientes
 UNION ALL SELECT 'pedidos',COUNT(*),12 FROM pedidos
 UNION ALL SELECT 'itens',COUNT(*),15 FROM itens
 UNION ALL SELECT 'pagamentos',COUNT(*),12 FROM pagamentos
 UNION ALL SELECT 'contratado',SUM(contratado),3060 FROM posicao
 UNION ALL SELECT 'recebido',SUM(recebido),2730 FROM posicao
 UNION ALL SELECT 'saldo assinado',SUM(saldo),330 FROM posicao
 UNION ALL SELECT 'a receber',SUM(GREATEST(saldo,0)),350 FROM posicao
 UNION ALL SELECT 'credito',SUM(GREATEST(-saldo,0)),20 FROM posicao
 UNION ALL SELECT 'estoque A',saldo,10 FROM estoques WHERE produto_id=1 AND deposito='A'
 UNION ALL SELECT 'estoque B',saldo,5 FROM estoques WHERE produto_id=1 AND deposito='B'
 UNION ALL SELECT 'preco Mouse',preco,50 FROM produtos WHERE id=1
)
SELECT *,obtido IS NOT DISTINCT FROM esperado AS confere FROM checks ORDER BY verificacao;
-- Todos os resultados devem apresentar confere=true.

-- Somente APÓS N2-1.5: comparar conteúdo exato nas duas direções.
-- Zero linhas significa igualdade de conjuntos.
WITH esperado(cliente_id,nome,email,uf) AS (
 VALUES (1,'Ana Silva','ana@example.test','PR'),(2,'Bruno Costa',NULL,'PR'),
 (3,'Carla Nova','carla@example.test','SP'),(9,'Ivan','ivan@example.test','RJ')
), diferencas AS (
 (SELECT cliente_id,nome,email,uf::text FROM contatos_tratados EXCEPT SELECT * FROM esperado)
 UNION ALL
 (SELECT * FROM esperado EXCEPT SELECT cliente_id,nome,email,uf::text FROM contatos_tratados)
)
SELECT * FROM diferencas;
