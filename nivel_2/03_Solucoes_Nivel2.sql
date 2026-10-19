-- SOLUÇÕES NÍVEL 2: consulte somente DEPOIS da tentativa.
-- Execute um bloco identificado por vez. NÃO execute este arquivo inteiro.
-- Use a mesma sessão nos blocos transacionais e Auto-commit para manutenção.
-- Tentativas que geram erro estão COMENTADAS: execute-as separadamente.
SET search_path TO bdadosql_n2, public;

-- N2-1.1: inspecione primeiro; cada tentativa deve ser isolada.
SELECT conrelid::regclass AS tabela, conname, pg_get_constraintdef(oid)
FROM pg_constraint WHERE connamespace='bdadosql_n2'::regnamespace
ORDER BY tabela,conname;
-- BEGIN;
-- UPDATE estoques SET saldo=-1 WHERE produto_id=1 AND deposito='A'; -- 23514
-- ROLLBACK;
-- BEGIN;
-- INSERT INTO estoques VALUES (1,'A',1); -- 23505
-- ROLLBACK;
-- BEGIN;
-- INSERT INTO pagamentos VALUES (99,999,DATE '2026-01-01','recebimento',1); -- 23503
-- ROLLBACK;
SELECT * FROM estoques ORDER BY produto_id,deposito;

-- N2-1.2: só execute o crédito após conferir uma linha no RETURNING.
BEGIN;
UPDATE estoques SET saldo=saldo-3
WHERE produto_id=1 AND deposito='A' AND saldo>=3 RETURNING *;
-- Conferir a saída acima antes de executar o crédito na mesma sessão.
UPDATE estoques SET saldo=saldo+3
WHERE produto_id=1 AND deposito='B' RETURNING *;
SELECT deposito,saldo,SUM(saldo) OVER () AS total FROM estoques ORDER BY deposito;
ROLLBACK;
SELECT * FROM estoques ORDER BY deposito; -- A10 B5

-- N2-1.3: passos manuais; a falha não deve interromper um script completo.
BEGIN;
UPDATE estoques SET saldo=saldo-2 WHERE produto_id=1 AND deposito='A';
SAVEPOINT antes_da_falha;
-- Execute a próxima linha sem o comentário, sozinha: erro 23514 esperado.
-- UPDATE estoques SET saldo=-1 WHERE produto_id=1 AND deposito='B';
-- Após o erro, execute somente a recuperação antes das demais instruções:
ROLLBACK TO SAVEPOINT antes_da_falha;
SELECT * FROM estoques ORDER BY deposito; -- A8 B5
UPDATE estoques SET saldo=saldo+2 WHERE produto_id=1 AND deposito='B';
SELECT * FROM estoques ORDER BY deposito; -- A8 B7
ROLLBACK;

-- N2-1.4: diagnóstico de todas as linhas, sem alterar a origem.
WITH normalizados AS (
 SELECT lote_id,cliente_id,btrim(nome) AS nome,
 NULLIF(lower(btrim(email)),'') AS email,upper(btrim(uf)) AS uf
 FROM importacao_contatos
), classificados AS (
 SELECT *,CASE
 WHEN nome IS NULL OR nome='' THEN 'nome ausente'
 WHEN uf IS NULL OR uf NOT IN ('PR','SP','PE','RS','RJ','SC') THEN 'UF invalida'
 WHEN email IS NOT NULL AND email !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$'
 THEN 'email invalido' ELSE 'valido' END AS motivo
 FROM normalizados
)
SELECT *,COUNT(*) FILTER (WHERE motivo='valido') OVER (PARTITION BY cliente_id)
 AS registros_validos_do_cliente
FROM classificados ORDER BY lote_id;

-- N2-1.5: execute este comando duas vezes e confira o conteúdo.
WITH normalizados AS (
 SELECT lote_id,cliente_id,btrim(nome) AS nome,
 NULLIF(lower(btrim(email)),'') AS email,upper(btrim(uf)) AS uf
 FROM importacao_contatos
), validos AS (
 SELECT * FROM normalizados
 WHERE nome IS NOT NULL AND nome<>''
 AND uf IN ('PR','SP','PE','RS','RJ','SC')
 AND (email IS NULL OR email ~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$')
), ordenados AS (
 SELECT *,ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY lote_id DESC) AS rn
 FROM validos
)
INSERT INTO contatos_tratados (cliente_id,nome,email,uf)
SELECT cliente_id,nome,email,uf FROM ordenados WHERE rn=1
ON CONFLICT (cliente_id) DO UPDATE
SET nome=EXCLUDED.nome,email=EXCLUDED.email,uf=EXCLUDED.uf;
SELECT * FROM contatos_tratados ORDER BY cliente_id;
-- 1 Ana Silva ana@example.test PR; 2 Bruno Costa NULL PR;
-- 3 Carla Nova carla@example.test SP; 9 Ivan ivan@example.test RJ.

-- N2-1.6: primeira retirada 1 linha, segunda 0; nada persiste.
BEGIN;
UPDATE estoques SET saldo=saldo-8
WHERE produto_id=1 AND deposito='A' AND saldo>=8 RETURNING *;
UPDATE estoques SET saldo=saldo-8
WHERE produto_id=1 AND deposito='A' AND saldo>=8 RETURNING *;
ROLLBACK;

-- N2-2.1: NULLIF também reconhece o email composto só por espaços.
SELECT id,nome,uf,email FROM clientes
WHERE ativo AND (uf='PR' OR uf='SP')
AND NULLIF(btrim(email),'') IS NULL ORDER BY id; -- 4

-- N2-2.2: somas iguais não tornam NULL semanticamente igual a zero.
SELECT COUNT(*) FILTER (WHERE desconto IS NULL) AS desconhecidos,
 COUNT(*) FILTER (WHERE desconto=0) AS zeros,
 COUNT(*) FILTER (WHERE desconto>0) AS positivos,
 SUM(desconto) AS soma_original,SUM(COALESCE(desconto,0)) AS soma_com_zero
FROM pedidos; -- 3,6,3,40,40

-- N2-2.3: SET LOCAL restaura automaticamente a configuração no ROLLBACK.
BEGIN;
SET LOCAL TIME ZONE 'UTC';
SELECT id,ocorrido_em,ocorrido_em AT TIME ZONE 'America/Sao_Paulo' AS horario_local
FROM acessos
WHERE ocorrido_em >= (TIMESTAMP '2026-03-01 00:00:00' AT TIME ZONE 'America/Sao_Paulo')
AND ocorrido_em < (TIMESTAMP '2026-04-01 00:00:00' AT TIME ZONE 'America/Sao_Paulo')
ORDER BY id;
SET LOCAL TIME ZONE 'America/Sao_Paulo';
SELECT id,ocorrido_em,ocorrido_em AT TIME ZONE 'America/Sao_Paulo' AS horario_local
FROM acessos
WHERE ocorrido_em >= (TIMESTAMP '2026-03-01 00:00:00' AT TIME ZONE 'America/Sao_Paulo')
AND ocorrido_em < (TIMESTAMP '2026-04-01 00:00:00' AT TIME ZONE 'America/Sao_Paulo')
ORDER BY id;
ROLLBACK; -- ids 2,3 em ambas; apresentação muda, instantes não.

-- N2-2.4: a ordem dos WHEN resolve os limites sem sobreposição.
SELECT id,nome,preco,CASE WHEN preco<100 THEN 'baixo'
 WHEN preco<=500 THEN 'medio' ELSE 'alto' END AS faixa
FROM produtos ORDER BY id;
WITH faixas AS (
 SELECT CASE WHEN preco<100 THEN 'baixo' WHEN preco<=500 THEN 'medio'
 ELSE 'alto' END AS faixa FROM produtos
)
SELECT faixa,COUNT(*) FROM faixas GROUP BY faixa ORDER BY faixa;
SELECT preco,CASE WHEN preco<100 THEN 'baixo' WHEN preco<=500 THEN 'medio'
 ELSE 'alto' END AS faixa FROM (VALUES (100),(500)) AS limites(preco);

-- N2-2.5: as três consultas respondem perguntas diferentes.
SELECT id FROM pedidos WHERE desconto<>0 ORDER BY id;
SELECT id FROM pedidos WHERE desconto IS DISTINCT FROM 0 ORDER BY id;
SELECT id FROM pedidos WHERE desconto IS DISTINCT FROM 0
EXCEPT SELECT id FROM pedidos WHERE desconto<>0 ORDER BY id; -- 102,105,108

-- N2-2.6: ! escapa o próximo caractere do padrão.
SELECT id,nome FROM produtos WHERE nome LIKE '%!%%' ESCAPE '!' ORDER BY id;
SELECT id,nome FROM produtos WHERE nome LIKE '%!_%' ESCAPE '!' ORDER BY id;
SELECT id,nome FROM produtos WHERE nome LIKE '%_%' ORDER BY id;

-- N2-3.1: filtro na CTE preserva os meses vazios do calendário.
WITH meses AS (
 SELECT generate_series(DATE '2026-01-01',DATE '2026-06-01',INTERVAL '1 month')::date AS mes
), receita AS (
 SELECT date_trunc('month',data_pedido)::date AS mes,
 SUM(valor_total-COALESCE(desconto,0)) AS liquido
 FROM pedidos WHERE status<>'cancelado' GROUP BY 1
)
SELECT m.mes,COALESCE(r.liquido,0) AS liquido FROM meses m
LEFT JOIN receita r USING (mes) ORDER BY m.mes;

-- N2-3.2: uma linha por pedido antes de somar os totais.
WITH recebidos AS (
 SELECT pedido_id,SUM(CASE WHEN tipo='recebimento' THEN valor ELSE -valor END) AS recebido
 FROM pagamentos GROUP BY pedido_id
), posicao AS (
 SELECT p.id,p.valor_total-COALESCE(p.desconto,0) AS contratado,
 COALESCE(r.recebido,0) AS recebido,
 p.valor_total-COALESCE(p.desconto,0)-COALESCE(r.recebido,0) AS saldo
 FROM pedidos p LEFT JOIN recebidos r ON r.pedido_id=p.id WHERE p.status<>'cancelado'
)
SELECT *,CASE WHEN saldo>0 THEN 'a_receber' WHEN saldo<0 THEN 'credito' ELSE 'quitado' END AS situacao,
 SUM(contratado) OVER () AS total_contratado,SUM(recebido) OVER () AS total_recebido,
 SUM(saldo) OVER () AS saldo_global,
 SUM(GREATEST(saldo,0)) OVER () AS total_a_receber,
 SUM(GREATEST(-saldo,0)) OVER () AS total_credito
FROM posicao ORDER BY id; -- 3060,2730,330,350,20

-- N2-3.3: não acrescente cliente_id ao DENSE_RANK se a regra incluir empates de valor.
WITH totais AS (
 SELECT date_trunc('month',data_pedido)::date AS mes,cliente_id,
 SUM(valor_total-COALESCE(desconto,0)) AS liquido
 FROM pedidos WHERE status<>'cancelado' GROUP BY 1,2
), ranking AS (
 SELECT *,ROW_NUMBER() OVER (PARTITION BY mes ORDER BY liquido DESC,cliente_id) AS posicao
 FROM totais
)
SELECT * FROM ranking WHERE posicao<=2 ORDER BY mes,posicao;

-- N2-3.4: janela sobre o resultado mensal, incluindo zeros.
WITH meses AS (
 SELECT generate_series(DATE '2026-01-01',DATE '2026-06-01',INTERVAL '1 month')::date AS mes
), receita AS (
 SELECT date_trunc('month',data_pedido)::date AS mes,
 SUM(valor_total-COALESCE(desconto,0)) AS liquido
 FROM pedidos WHERE status<>'cancelado' GROUP BY 1
), calendario AS (
 SELECT m.mes,COALESCE(r.liquido,0) AS liquido FROM meses m LEFT JOIN receita r USING (mes)
), janelas AS (
 SELECT *,SUM(liquido) OVER (ORDER BY mes ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS acumulado,
 LAG(liquido) OVER (ORDER BY mes) AS anterior FROM calendario
)
SELECT *,round(100.0*(liquido-anterior)/NULLIF(anterior,0),2) AS variacao_pct
FROM janelas ORDER BY mes;

-- N2-3.5: calendário de caixa, não de competência.
WITH meses AS (
 SELECT generate_series(DATE '2026-01-01',DATE '2026-06-01',INTERVAL '1 month')::date AS mes
), caixa AS (
 SELECT date_trunc('month',pg.data_pagamento)::date AS mes,
 COALESCE(SUM(pg.valor) FILTER (WHERE pg.tipo='recebimento'),0) AS bruto,
 COALESCE(SUM(pg.valor) FILTER (WHERE pg.tipo='estorno'),0) AS estorno
 FROM pagamentos pg JOIN pedidos p ON p.id=pg.pedido_id
 WHERE p.status<>'cancelado' GROUP BY 1
)
SELECT m.mes,COALESCE(c.bruto,0) AS bruto,COALESCE(c.estorno,0) AS estorno,
 COALESCE(c.bruto-c.estorno,0) AS recebido_liquido,
 round(100.0*c.estorno/NULLIF(c.bruto,0),2) AS pct_estornado
FROM meses m LEFT JOIN caixa c USING (mes) ORDER BY m.mes;

-- N2-3.6: separe dívidas e créditos antes de agregar por cliente.
WITH recebidos AS (
 SELECT pedido_id,SUM(CASE WHEN tipo='recebimento' THEN valor ELSE -valor END) AS recebido
 FROM pagamentos GROUP BY pedido_id
), saldos AS (
 SELECT p.cliente_id,p.valor_total-COALESCE(p.desconto,0)-COALESCE(r.recebido,0) AS saldo
 FROM pedidos p LEFT JOIN recebidos r ON r.pedido_id=p.id WHERE p.status<>'cancelado'
)
SELECT cliente_id,SUM(GREATEST(saldo,0)) AS a_receber,SUM(GREATEST(-saldo,0)) AS credito
FROM saldos GROUP BY cliente_id HAVING SUM(GREATEST(saldo,0))>0 ORDER BY cliente_id;
-- Remova somente HAVING para conferir o crédito do cliente 3.

-- N2-4.1: COUNT(p.id), não COUNT(*), para contar pedidos.
SELECT c.id,c.nome,COUNT(p.id) AS pedidos,
 COALESCE(SUM(p.valor_total-COALESCE(p.desconto,0)),0) AS contratado
FROM clientes c LEFT JOIN pedidos p ON p.cliente_id=c.id AND p.status<>'cancelado'
GROUP BY c.id,c.nome ORDER BY c.id;

-- N2-4.2: comparar igualdade com NULL não produz verdadeiro.
SELECT c.id,c.nome FROM clientes c WHERE NOT EXISTS (
 SELECT 1 FROM pedidos p WHERE p.cliente_id=c.id AND p.status<>'cancelado'
) ORDER BY c.id;
SELECT id FROM clientes WHERE id NOT IN (SELECT id FROM (VALUES (2),(NULL::integer)) AS lista(id));
SELECT c.id FROM clientes c WHERE NOT EXISTS (
 SELECT 1 FROM (VALUES (2),(NULL::integer)) AS lista(id) WHERE lista.id=c.id
) ORDER BY c.id;

-- N2-4.3: duas relações 1:N produzem multiplicação antes do GROUP BY.
SELECT COUNT(*) AS linhas,SUM(i.quantidade*i.preco_unitario) AS itens_inflados,
 SUM(CASE WHEN pg.tipo='recebimento' THEN pg.valor ELSE -pg.valor END) AS recebido_inflado
FROM pedidos p JOIN itens i ON i.pedido_id=p.id JOIN pagamentos pg ON pg.pedido_id=p.id
WHERE p.id=101; -- 4,500,480
WITH ti AS (
 SELECT pedido_id,SUM(quantidade*preco_unitario) AS bruto_itens FROM itens GROUP BY pedido_id
), rp AS (
 SELECT pedido_id,SUM(CASE WHEN tipo='recebimento' THEN valor ELSE -valor END) AS recebido
 FROM pagamentos GROUP BY pedido_id
)
SELECT p.id,ti.bruto_itens,COALESCE(rp.recebido,0) AS recebido,
 p.valor_total-COALESCE(p.desconto,0) AS contratado
FROM pedidos p LEFT JOIN ti ON ti.pedido_id=p.id LEFT JOIN rp ON rp.pedido_id=p.id WHERE p.id=101;
-- DISTINCT descartaria também valores iguais legítimos em outras cargas.

-- N2-4.4: LEFT JOIN LATERAL e alternativa equivalente por janela.
SELECT c.id AS cliente_id,ult.id AS pedido_id,ult.data_pedido
FROM clientes c LEFT JOIN LATERAL (
 SELECT p.id,p.data_pedido FROM pedidos p WHERE p.cliente_id=c.id
 ORDER BY p.data_pedido DESC,p.id DESC LIMIT 1
) ult ON true ORDER BY c.id;
WITH ordenados AS (
 SELECT *,ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY data_pedido DESC,id DESC) AS rn FROM pedidos
)
SELECT c.id AS cliente_id,p.id AS pedido_id,p.data_pedido
FROM clientes c LEFT JOIN ordenados p ON p.cliente_id=c.id AND p.rn=1 ORDER BY c.id;
-- Para provar equivalência em SQL, envolva as duas versões (sem ORDER BY) em CTEs
-- a e b e execute (SELECT * FROM a EXCEPT SELECT * FROM b)
-- UNION ALL (SELECT * FROM b EXCEPT SELECT * FROM a): zero linhas.

-- N2-4.5: fontes simuladas; nenhuma alteração real.
WITH cabecalhos AS (
 SELECT id,valor_total+CASE WHEN id=101 THEN 1 ELSE 0 END AS bruto
 FROM pedidos WHERE id<>111
), totais_itens AS (
 SELECT pedido_id,SUM(quantidade*preco_unitario) AS bruto
 FROM itens WHERE pedido_id<>112 GROUP BY pedido_id
)
SELECT COALESCE(c.id,i.pedido_id) AS pedido_id,c.bruto AS cabecalho,i.bruto AS itens,
 c.bruto-i.bruto AS diferenca,
 CASE WHEN c.id IS NULL THEN 'somente_itens'
 WHEN i.pedido_id IS NULL THEN 'somente_cabecalho' ELSE 'valor_divergente' END AS motivo
FROM cabecalhos c FULL JOIN totais_itens i ON i.pedido_id=c.id
WHERE c.bruto IS DISTINCT FROM i.bruto ORDER BY pedido_id;

-- N2-4.6: escrita somente no cadastro; sempre desfazer ao final.
BEGIN;
SELECT SUM(i.quantidade*i.preco_unitario) AS historico,SUM(i.quantidade*p.preco) AS atual
FROM itens i JOIN produtos p ON p.id=i.produto_id WHERE i.pedido_id=101;
UPDATE produtos SET preco=60 WHERE id=1;
SELECT SUM(i.quantidade*i.preco_unitario) AS historico,SUM(i.quantidade*p.preco) AS atual
FROM itens i JOIN produtos p ON p.id=i.produto_id WHERE i.pedido_id=101;
ROLLBACK;

-- N2-5.1: primeiro execute 02_Preparacao_Desempenho.sql.
-- REPITA CADA EXPLAIN 3 VEZES e salve os nove planos ANTES de N2-5.2.
SELECT version();
SELECT indexname,indexdef FROM pg_indexes WHERE schemaname='bdadosql_n2' AND tablename='eventos';
SELECT pg_table_size('bdadosql_n2.eventos') AS tabela_bytes,
 pg_indexes_size('bdadosql_n2.eventos') AS indices_bytes;
ANALYZE eventos;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos
WHERE cliente_id=42 AND data_evento BETWEEN DATE '2026-03-01' AND DATE '2026-04-10';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos
WHERE data_evento BETWEEN DATE '2026-03-01' AND DATE '2026-04-10';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos;

-- N2-5.2: após criação, repetir CADA EXPLAIN de N2-5.1 três vezes.
CREATE INDEX n2_eventos_cliente_data_idx ON eventos (cliente_id,data_evento);
-- Execute novamente as três consultas EXPLAIN de N2-5.1, sem recriar a base.
SELECT pg_size_pretty(pg_relation_size('bdadosql_n2.n2_eventos_cliente_data_idx')) AS tamanho_indice;

-- N2-5.3: executar EXPLAIN três vezes antes, criar índice, repetir três vezes.
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos
WHERE status='pendente' AND data_evento>=DATE '2026-03-01' AND data_evento<DATE '2026-04-01'
ORDER BY data_evento,id LIMIT 50;
CREATE INDEX n2_eventos_pendentes_idx ON eventos (data_evento,id) WHERE status='pendente';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos
WHERE status='pendente' AND data_evento>=DATE '2026-03-01' AND data_evento<DATE '2026-04-01'
ORDER BY data_evento,id LIMIT 50;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos
WHERE status='pago' AND data_evento>=DATE '2026-03-01' AND data_evento<DATE '2026-04-01'
ORDER BY data_evento,id LIMIT 50;
SELECT COUNT(*) FROM eventos WHERE status='pendente'
AND data_evento>=DATE '2026-03-01' AND data_evento<DATE '2026-04-01'; -- 4000
SELECT indexrelname,pg_size_pretty(pg_relation_size(indexrelid)) AS tamanho
FROM pg_stat_user_indexes WHERE schemaname='bdadosql_n2' AND relname='eventos';

-- N2-5.4: três execuções antes/depois; preserve o mesmo SELECT *.
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos WHERE lower(email)='cliente42@example.test';
CREATE INDEX n2_eventos_email_lower_idx ON eventos (lower(email));
ANALYZE eventos;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos WHERE lower(email)='cliente42@example.test';
SELECT id FROM eventos WHERE lower(email)='cliente42@example.test' ORDER BY id; -- 300 ids

-- N2-5.5: compare a estimativa ANTES de criar o objeto de estatísticas.
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos WHERE uf='PR' AND cidade='Curitiba';
SELECT attname,null_frac,n_distinct,most_common_vals,most_common_freqs,histogram_bounds,correlation
FROM pg_stats WHERE schemaname='bdadosql_n2' AND tablename='eventos'
AND attname IN ('cliente_id','uf','cidade') ORDER BY attname;
SELECT uf,cidade,COUNT(*) FROM eventos GROUP BY uf,cidade ORDER BY uf,cidade;
CREATE STATISTICS bdadosql_n2.n2_eventos_uf_cidade_stats (dependencies) ON uf,cidade FROM eventos;
ANALYZE eventos;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos WHERE uf='PR' AND cidade='Curitiba';
SELECT statistics_name,attnames,kinds,dependencies FROM pg_stats_ext
WHERE schemaname='bdadosql_n2' AND tablename='eventos';

-- N2-5.6: cópia independente; só criar uma vez.
CREATE TABLE eventos_fisicos AS SELECT * FROM eventos;
CREATE INDEX n2_fisicos_cliente_data_idx ON eventos_fisicos (cliente_id,data_evento);
ANALYZE eventos_fisicos;
SELECT correlation FROM pg_stats WHERE schemaname='bdadosql_n2'
AND tablename='eventos_fisicos' AND attname='cliente_id';
-- Medir três vezes ANTES do CLUSTER:
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_fisicos
WHERE cliente_id=42 AND data_evento BETWEEN DATE '2026-03-01' AND DATE '2026-04-10';
CLUSTER bdadosql_n2.eventos_fisicos USING n2_fisicos_cliente_data_idx;
ANALYZE eventos_fisicos;
-- Medir três vezes DEPOIS do CLUSTER:
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM eventos_fisicos
WHERE cliente_id=42 AND data_evento BETWEEN DATE '2026-03-01' AND DATE '2026-04-10';
SELECT correlation FROM pg_stats WHERE schemaname='bdadosql_n2'
AND tablename='eventos_fisicos' AND attname='cliente_id';
UPDATE eventos_fisicos SET status='revisado' WHERE id<=60000; -- 60000
DELETE FROM eventos_fisicos WHERE id>270000; -- 30000
SELECT COUNT(*) AS total,COUNT(*) FILTER (WHERE status='revisado') AS revisados,
 COUNT(*) FILTER (WHERE id>270000) AS acima_limite FROM eventos_fisicos; -- 270000,60000,0
SELECT pg_table_size('bdadosql_n2.eventos_fisicos') AS tabela_bytes,
 pg_indexes_size('bdadosql_n2.eventos_fisicos') AS indices_bytes,
 pg_total_relation_size('bdadosql_n2.eventos_fisicos') AS total_bytes;
-- Execute SOMENTE este comando, em Auto-commit, sem transação pendente:
VACUUM (VERBOSE, ANALYZE) bdadosql_n2.eventos_fisicos;
-- Repita a consulta de tamanhos acima e salve as mensagens do VACUUM.
-- Extensão OPCIONAL, executar isoladamente e somente na cópia:
-- VACUUM FULL bdadosql_n2.eventos_fisicos;
-- ANALYZE bdadosql_n2.eventos_fisicos;
-- Repita a consulta de tamanhos; não confunda este estado com a linha de base.
