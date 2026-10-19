-- Executar uma vez depois de 00_preparacao.sql; sem DROP de objetos existentes.
BEGIN;
SET search_path TO bdadosql, public;
CREATE TABLE eventos_lab11 (
    id INTEGER NOT NULL,
    cliente_id INTEGER NOT NULL,
    data_evento DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    valor NUMERIC(10,2) NOT NULL,
    descricao TEXT
);
-- Sem PK: a comparação inicial precisa acontecer sem índice de id.
-- Dados determinísticos; cliente e data variam em ciclos diferentes.
INSERT INTO eventos_lab11
SELECT g,
       (g % 1000) + 1,
       DATE '2026-01-01' + (g % 365),
       CASE WHEN g % 10 = 0 THEN 'pendente' ELSE 'pago' END,
       ((g % 10000)::NUMERIC / 10)::NUMERIC(10,2),
       repeat('evento de treinamento ',5)
FROM generate_series(1,200000) AS serie(g);
CREATE TABLE codigos_lab11 (codigo INTEGER);
COMMIT;
ANALYZE bdadosql.eventos_lab11;
SELECT COUNT(*) AS linhas FROM bdadosql.eventos_lab11;
-- Esperado: 200000. Prosseguir para L11.1 antes de criar índices.
