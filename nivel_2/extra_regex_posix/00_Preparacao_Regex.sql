-- BDLab10: laboratório extra de expressões regulares POSIX.
-- Execute este arquivo UMA VEZ no banco de treinamento, pelo DBeaver.
-- A preparação usa seu próprio BEGIN/COMMIT. Não depende dos outros níveis.
-- Não apaga nem reinicia objetos existentes. Se falhar, pare e use ROLLBACK.
BEGIN;
CREATE SCHEMA bdadosql_regex;

CREATE TABLE bdadosql_regex.importacao_contatos (
    id integer PRIMARY KEY,
    nome text,
    email text,
    telefone text,
    uf text,
    codigo text,
    observacao text
);

-- Dados fictícios. Preserve a carga: os exercícios usam somente SELECT.
-- E'\t' e E'\n' inserem tabulação e quebra de linha reais.
INSERT INTO bdadosql_regex.importacao_contatos
    (id, nome, email, telefone, uf, codigo, observacao)
VALUES
 (1, '  Ana   Silva  ', ' ANA@EXAMPLE.TEST ', '(41) 99999-0001',
     'pr', 'CLI-001', 'Pedidos PED-101 e PED-102'),
 (2, 'ANA LIMA', '   ', '41 3333-0002',
     'SP', 'cli-002', 'Sem pedido informado'),
 (3, 'Mariana Costa', 'mariana@example.test', '21988880003',
     'rj', 'CLI-003', 'Revisar PED-103'),
 (4, 'Anabela Rocha', 'anabela@@example.test', '(48)98888-0004',
     'SC', ' CLI-004 ', 'Conferir email'),
 (5, 'Bruno', 'bruno@example', '12345',
     'XX', 'CLI-05', 'Cadastro incompleto'),
 (6, E'Carla\tSouza', 'carla.souza@example.com.br', '+55 (51) 99999-0006',
     ' rs ', 'CLI-006', 'Telefone com codigo do pais'),
 (7, 'Diego  Alves', 'diego @example.test', '81 9A999-0007',
     'PE', 'XCLI-007', 'Letra no telefone'),
 (8, 'Eva', NULL, NULL,
     'PR', 'CLI-008-extra', 'Sem pedido informado'),
 (9, 'Fabio', 'fabio@example..test', '(11) 99999-0009',
     'SP', 'CLI-009', 'Dois pontos seguidos no dominio'),
 (10, 'Gabi', '@example.test', '   ',
     '', 'CLI-010', 'Contato sem usuario no email'),
 (11, 'Hugo', 'hugo@example.', '41 3333 0011',
     'PR', 'CLI-011', 'Email sem sufixo'),
 (12, E'Iara\nMelo', 'iara+news@example.test', '(21) 98888-0012',
     'RJ', 'CLI-012', 'Nome com quebra de linha');
COMMIT;

SELECT count(*) AS linhas_esperadas_12
FROM bdadosql_regex.importacao_contatos;
