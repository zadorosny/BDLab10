-- Execute uma vez, somente ao chegar ao laboratório N2-5.
-- Requer 00_Preparacao_Nivel2.sql. Não toca em bdadosql (nível 1).
BEGIN;
SET search_path TO bdadosql_n2, public;
-- Sem PK ou índices: necessária para a primeira medição.
CREATE TABLE eventos (
 id integer NOT NULL, cliente_id integer NOT NULL,
 data_evento date NOT NULL, status text NOT NULL,
 valor numeric(12,2) NOT NULL, email text NOT NULL,
 uf text NOT NULL, cidade text NOT NULL, descricao text NOT NULL
);
INSERT INTO eventos
SELECT g, ((g-1)%1000)+1,
 DATE '2026-01-01' + (((g-1)/1000)%180),
 CASE WHEN ((g-1)/1000)%20=0 THEN 'pendente' ELSE 'pago' END,
 ((g%10000)::numeric/10)::numeric(12,2),
 'CLIENTE'||(((g-1)%1000)+1)||'@EXAMPLE.TEST',
 CASE WHEN (g-1)%10<6 THEN 'PR' ELSE 'SP' END,
 CASE WHEN (g-1)%10<6 THEN 'Curitiba' ELSE 'Santos' END,
 repeat('evento nivel 2 ',5)
FROM generate_series(1,300000) AS serie(g);
COMMIT;
ANALYZE bdadosql_n2.eventos;
-- 300000 eventos; 1000 clientes, 300 linhas cada; 15000 pendentes;
-- PR/Curitiba: 180000; SP/Santos: 120000. Dependência UF/cidade intencional.
SELECT count(*) AS total,
 count(DISTINCT cliente_id) AS clientes,
 count(*) FILTER (WHERE status='pendente') AS pendentes,
 count(*) FILTER (WHERE cliente_id=42 AND data_evento
 BETWEEN DATE '2026-03-01' AND DATE '2026-04-10') AS filtro_cliente_42
FROM bdadosql_n2.eventos;
-- Esperado: 300000 | 1000 | 15000 | 82.
