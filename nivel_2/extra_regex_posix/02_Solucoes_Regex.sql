-- Consulte por exercício, depois de tentar.
-- Todos os blocos são somente leitura e usam nomes de tabela qualificados.
-- Podem ser repetidos sem modificar a carga de 12 contatos.

-- RX-01: procurar texto e comparar maiúsculas e minúsculas
SELECT id, nome,
       nome ~ 'ana' AS encontra_exato,
       nome ~* 'ana' AS encontra_sem_distinguir_caixa,
       nome !~ 'ana' AS nao_encontra_exato,
       nome !~* 'ana' AS nao_encontra_sem_distinguir_caixa
FROM bdadosql_regex.importacao_contatos
ORDER BY id;
-- ~: id 3. ~*: ids 1, 2, 3, 4. Mariana também contém "ana".
-- !~ e !~* negam o teste; não alteram o texto.

-- RX-02: encontrar Ana como primeiro nome, e não dentro de outra palavra
SELECT id, btrim(nome) AS nome,
       btrim(nome) ~* 'ana' AS em_qualquer_posicao,
       btrim(nome) ~* '^ana' AS no_inicio,
       btrim(nome) ~* '^ana([[:space:]]|$)' AS primeiro_nome_ana
FROM bdadosql_regex.importacao_contatos
ORDER BY id;
-- Qualquer posição: 1,2,3,4. Início: 1,2,4. Primeiro nome: 1,2.
-- Depois de "ana", o grupo exige um branco OU o fim do texto.
SELECT 'Ana' ~* '^ana$' AS nome_inteiro_ana,
       'Ana Silva' ~* '^ana$' AS nome_composto_nao_e_igual;

-- RX-03: investigar espaços em branco e repetições
SELECT id, nome,
       nome ~ '[[:space:]]' AS tem_branco,
       nome ~ '[[:space:]]{2,}' AS tem_brancos_consecutivos
FROM bdadosql_regex.importacao_contatos
ORDER BY id;
-- Brancos: 1,2,3,4,6,7,12. Dois ou mais consecutivos: 1,7.
SELECT '' ~ '^[[:space:]]*$' AS asterisco_aceita_vazio,
       '' ~ '^[[:space:]]+$' AS mais_exige_um,
       E'\t' ~ '^[[:space:]]+$' AS tabulacao_e_branco,
       E'\n' ~ '^[[:space:]]+$' AS quebra_e_branco;

-- RX-04: diagnosticar o formato básico dos emails
SELECT id, email AS email_original,
       NULLIF(lower(btrim(email)), '') AS email_normalizado,
       email ~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$'
           AS original_passa,
       CASE
           WHEN NULLIF(btrim(email), '') IS NULL THEN 'ausente'
           WHEN lower(btrim(email))
                ~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$'
               THEN 'passa no formato'
           ELSE 'fora do formato'
       END AS diagnostico
FROM bdadosql_regex.importacao_contatos
ORDER BY id;
-- Normalizados: 5 passam (1,3,6,9,12), 2 ausentes (2,8), 5 fora.
-- O id 9 passa apesar dos dois pontos seguidos. O regex é simplificado.
SELECT NULL::text ~ 'abc' AS teste_com_null,
       NULL::text !~ 'abc' AS negacao_com_null;
-- Ambos NULL: negação não transforma valor desconhecido em verdadeiro.

-- RX-05: aceitar somente as UFs atendidas pela loja
SELECT id, uf AS uf_original, upper(btrim(uf)) AS uf_normalizada,
       upper(btrim(uf)) ~ '^(PR|SP|PE|RS|RJ|SC)$' AS uf_atendida
FROM bdadosql_regex.importacao_contatos
ORDER BY id;
-- 10 passam. IDs 5 e 10 não passam.
SELECT texto,
       texto ~ '^PR|SC$' AS agrupamento_incorreto,
       texto ~ '^(PR|SC)$' AS agrupamento_correto
FROM (VALUES ('PR'), ('PRX'), ('XSC'), ('SP')) AS exemplos(texto)
ORDER BY texto;
-- ^PR|SC$ significa "começa com PR OU termina com SC".

-- RX-06: conferir prefixo e quantidade exata de dígitos
SELECT id, codigo AS codigo_original,
       upper(btrim(codigo)) AS codigo_normalizado,
       upper(btrim(codigo)) COLLATE "C"
           ~ '^CLI-[[:digit:]]{3}$' AS codigo_no_formato
FROM bdadosql_regex.importacao_contatos
ORDER BY id;
-- 9 passam. IDs 5, 7 e 8 não passam.
-- COLLATE "C" explicita a convenção ASCII para os dígitos deste código.
SELECT texto,
       texto ~ '^[[:digit:]]{2}-?[[:digit:]]{4}$' AS separador_opcional
FROM (VALUES ('123456'), ('12-3456'), ('12--3456')) AS exemplos(texto)
ORDER BY texto;

-- RX-07: apresentar nomes sem brancos extras
SELECT id, nome AS nome_original,
       regexp_replace(nome, '[[:space:]]+', ' ') AS primeira_substituicao,
       btrim(regexp_replace(nome, '[[:space:]]+', ' ', 'g'))
           AS nome_normalizado
FROM bdadosql_regex.importacao_contatos
ORDER BY id;
-- No id 1, a primeira substituição só atinge os espaços iniciais.
-- g trata todos os grupos; btrim retira os espaços que sobram nas bordas.
-- O SELECT mostra uma versão tratada; o dado original continua igual.

-- RX-08: limpar telefone sem esconder uma letra indevida
WITH telefones AS (
    SELECT id, telefone,
           regexp_replace(telefone, '[^[:digit:]]', '', 'g') AS digitos
    FROM bdadosql_regex.importacao_contatos
)
SELECT id, telefone AS telefone_original, digitos,
       CASE
           WHEN telefone IS NULL OR telefone ~ '^[[:space:]]*$'
               THEN 'ausente'
           WHEN telefone COLLATE "C" ~ '^[[:digit:][:space:]()+-]+$'
            AND digitos COLLATE "C" ~ '^[[:digit:]]{10,11}$'
               THEN 'passa na regra local'
           ELSE 'revisar'
       END AS diagnostico
FROM telefones
ORDER BY id;
-- Regra didática: DDD + número, com 10 ou 11 dígitos, sem código do país.
-- Permitimos espaços, (), + e - na apresentação; letras são rejeitadas.
-- 7 passam (1,2,3,4,9,11,12), 2 ausentes (8,10), 3 revisar (5,6,7).
-- No id 7, retirar "A" gera 10 dígitos, mas o original exige revisão.
-- No id 6, +55 está fora do modelo LOCAL; isso não prova telefone inválido.

-- RX-09: extrair somente o domínio do email
SELECT id, email,
       substring(lower(btrim(email))
                 FROM '^[^[:space:]@]+@([^[:space:]@]+[.][^[:space:]@]+)$')
           AS dominio
FROM bdadosql_regex.importacao_contatos
ORDER BY id;
-- substring devolve o primeiro grupo entre parênteses.
-- Há domínio nos ids 1,3,6,9,12; os outros retornam NULL.
-- O id 9 devolve example..test: extrair não resolve a limitação do filtro.
SELECT regexp_match('CLI-017', '^(CLI)-([[:digit:]]{3})$') AS grupos;
-- Um array com dois grupos: {CLI,017}.

-- RX-10: reutilizar grupos para formatar um telefone
SELECT id, telefone AS telefone_original,
       regexp_replace(
           regexp_replace(telefone, '[^[:digit:]]', '', 'g'),
           '^([[:digit:]]{2})([[:digit:]]{5})([[:digit:]]{4})$',
           E'(\\1) \\2-\\3'
       ) AS telefone_formatado
FROM bdadosql_regex.importacao_contatos
WHERE id IN (1,3,4,9,12)
ORDER BY id;
-- Seleção restrita a cinco telefones já conferidos no RX-08.
-- Grupo 1: DDD; grupo 2: cinco dígitos; grupo 3: quatro dígitos.
-- No literal E'...', \\ representa uma barra entregue ao regexp_replace.
-- \1, \2 e \3, na substituição, reaproveitam os grupos capturados.
-- Exemplo do id 3: (21) 98888-0003.

-- RX-11: encontrar uma ocorrência ou todas as ocorrências
SELECT id, regexp_match(observacao, 'PED-([[:digit:]]{3})') AS primeiro
FROM bdadosql_regex.importacao_contatos
WHERE id IN (1,3,8)
ORDER BY id;
-- 3 linhas: 1 -> {101}; 3 -> {103}; 8 -> NULL.
SELECT id,
       regexp_matches(observacao, 'PED-([[:digit:]]{3})', 'g') AS ocorrencia
FROM bdadosql_regex.importacao_contatos
WHERE id IN (1,3,8)
ORDER BY id, ocorrencia;
-- 3 linhas novamente, mas de OUTRA população:
-- 1 -> {101}; 1 -> {102}; 3 -> {103}. O id 8 não produz linha.
-- Estes são códigos mencionados no texto, não prova de pedidos existentes.

-- RX-12: entregar um diagnóstico com evidências e limites
WITH normalizados AS (
    SELECT id, nome, email, uf, codigo,
           btrim(regexp_replace(nome, '[[:space:]]+', ' ', 'g')) AS nome_limpo,
           NULLIF(lower(btrim(email)), '') AS email_limpo,
           upper(btrim(uf)) AS uf_limpa,
           upper(btrim(codigo)) AS codigo_limpo
    FROM bdadosql_regex.importacao_contatos
), diagnostico AS (
    SELECT *,
           CASE
               WHEN email_limpo IS NULL THEN 'ausente'
               WHEN email_limpo
                    ~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$'
                   THEN 'passa no formato'
               ELSE 'fora do formato'
           END AS situacao_email,
           COALESCE(uf_limpa ~ '^(PR|SP|PE|RS|RJ|SC)$', false) AS uf_ok,
           COALESCE(codigo_limpo COLLATE "C" ~ '^CLI-[[:digit:]]{3}$', false)
               AS codigo_ok
    FROM normalizados
)
SELECT id, nome AS nome_original, nome_limpo,
       email AS email_original, email_limpo,
       uf AS uf_original, uf_limpa,
       codigo AS codigo_original, codigo_limpo,
       situacao_email, uf_ok, codigo_ok,
       CASE
           WHEN situacao_email IN ('ausente','passa no formato')
                AND uf_ok AND codigo_ok THEN 'passa nas regras'
           ELSE 'revisar'
       END AS decisao_das_regras
FROM diagnostico
ORDER BY id;
-- Escopo desta decisão: email, UF e código. Email ausente é permitido.
-- Nome é apresentado normalizado; telefone não participa dessa decisão.
-- 6 passam nas regras: 1,2,3,6,9,12. 6 ficam para revisão.
-- O id 9 continua sendo evidência de uma lacuna da regra de email.
-- Diagnóstico possível:
-- "O lote tem 12 contatos. Após normalização, 5 emails passam no formato,
-- 2 estão ausentes e 5 estão fora. Há 2 UFs e 3 códigos fora da regra.
-- Seis contatos passam nas três regras; isso não certifica sua qualidade
-- completa: o id 9 passa mesmo com example..test. Não importei a carga.
-- Encaminharia esse caso para definir uma regra adicional com a equipe."
