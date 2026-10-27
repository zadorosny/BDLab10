-- Conferências de leitura do nível 1: comparam os dados com os resultados
-- esperados citados no roteiro e em 03_Solucoes_Laboratorios.sql.
-- Execute depois de 00_preparacao.sql. Os laboratórios 3 a 6 não alteram a carga.
SET search_path TO bdadosql, public;
WITH itens_por_pedido AS (
 SELECT p.id,p.valor_total,SUM(i.quantidade*i.preco_unitario) AS soma_itens
 FROM pedidos p JOIN itens i ON i.pedido_id=p.id GROUP BY p.id,p.valor_total
), checks AS (
 SELECT 'clientes' AS verificacao,COUNT(*)::numeric AS obtido,6::numeric AS esperado FROM clientes
 UNION ALL SELECT 'vendedores',COUNT(*),2 FROM vendedores
 UNION ALL SELECT 'produtos',COUNT(*),5 FROM produtos
 UNION ALL SELECT 'pedidos',COUNT(*),8 FROM pedidos
 UNION ALL SELECT 'itens',COUNT(*),10 FROM itens
 UNION ALL SELECT 'soma dos preços',SUM(preco),1850 FROM produtos
 UNION ALL SELECT 'L4.1 email nulo',COUNT(*),3 FROM clientes WHERE email IS NULL
 UNION ALL SELECT 'L4.3 com parênteses',COUNT(*),3 FROM clientes WHERE (uf='PR' OR uf='SP') AND ativo=true
 UNION ALL SELECT 'L4.3 sem parênteses',COUNT(*),4 FROM clientes WHERE uf='PR' OR uf='SP' AND ativo=true
 UNION ALL SELECT 'L4.4 preço 100 a 500',COUNT(*),3 FROM produtos WHERE preco BETWEEN 100 AND 500
 UNION ALL SELECT 'L4.4 PR ou PE',COUNT(*),4 FROM clientes WHERE uf IN ('PR','PE')
 UNION ALL SELECT 'L4.5 LIKE Ana%',COUNT(*),2 FROM clientes WHERE nome LIKE 'Ana%'
 UNION ALL SELECT 'L4.5 regex ^[AB]',COUNT(*),3 FROM clientes WHERE nome ~ '^[AB]'
 UNION ALL SELECT 'L4.6 pares cidade/UF',COUNT(*),5 FROM (SELECT DISTINCT cidade,uf FROM clientes) d
 UNION ALL SELECT 'L5.1 soma',SUM(valor_total),2600 FROM pedidos
 UNION ALL SELECT 'L5.1 média',round(AVG(valor_total),2),325 FROM pedidos
 UNION ALL SELECT 'L5.2 COUNT(desconto)',COUNT(desconto),5 FROM pedidos
 UNION ALL SELECT 'L5.2 AVG(desconto)',AVG(desconto),8 FROM pedidos
 UNION ALL SELECT 'L5.3 pago',SUM(valor_total),1850 FROM pedidos WHERE status='pago'
 UNION ALL SELECT 'L5.3 pendente',SUM(valor_total),700 FROM pedidos WHERE status='pendente'
 UNION ALL SELECT 'L5.6 cliente 1 pago',SUM(valor_total),1150 FROM pedidos WHERE status='pago' AND cliente_id=1
 UNION ALL SELECT 'L6.4 pedidos que conferem',COUNT(*) FILTER (WHERE valor_total=soma_itens),8 FROM itens_por_pedido
 UNION ALL SELECT 'L6.5 produto cartesiano',COUNT(*),48 FROM clientes CROSS JOIN pedidos
 UNION ALL SELECT 'L6.5 junção correta',COUNT(*),8 FROM clientes c JOIN pedidos p ON p.cliente_id=c.id
 UNION ALL SELECT 'L6.6 pares mesma cidade',COUNT(*),1 FROM clientes a JOIN clientes b
  ON a.cidade=b.cidade AND a.uf=b.uf AND a.id<b.id
 UNION ALL SELECT 'L6.7 mais baratos que id 2',COUNT(*),1 FROM produtos p
  JOIN produtos ref ON p.preco<ref.preco WHERE ref.id=2
)
SELECT *,obtido IS NOT DISTINCT FROM esperado AS confere FROM checks ORDER BY verificacao;
-- Todos os resultados devem apresentar confere=true.

-- Somente depois de 02_Lab11_Preparacao.sql e ANTES de L11.6, que altera os eventos.
WITH checks AS (
 SELECT 'eventos' AS verificacao,COUNT(*)::numeric AS obtido,200000::numeric AS esperado FROM eventos_lab11
 UNION ALL SELECT 'L11.3 cliente 42',COUNT(*),200 FROM eventos_lab11 WHERE cliente_id=42
 UNION ALL SELECT 'L11.3 cliente 42 de 1 a 10/04',COUNT(*),6 FROM eventos_lab11
  WHERE cliente_id=42 AND data_evento BETWEEN DATE '2026-04-01' AND DATE '2026-04-10'
 UNION ALL SELECT 'L11.3 somente o intervalo',COUNT(*),5480 FROM eventos_lab11
  WHERE data_evento BETWEEN DATE '2026-04-01' AND DATE '2026-04-10'
)
SELECT *,obtido IS NOT DISTINCT FROM esperado AS confere FROM checks ORDER BY verificacao;
