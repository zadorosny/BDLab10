# Gabarito comentado — Questionário

Use depois de responder ao arquivo `01_Questionario_e_Laboratorios.md`. Respostas equivalentes são válidas quando preservam o significado.

## Capítulo 3

1. **C3-Q01.** O servidor executa o SGBD e atende conexões; um banco contém objetos de uma aplicação; uma tabela organiza registros; uma linha representa um registro; uma coluna representa um atributo. Exemplo: servidor PostgreSQL → banco loja → tabela clientes → cliente Ana → coluna nome.
2. **C3-Q02.** Define nome e estrutura da tabela, incluindo colunas, tipos e eventuais restrições. `CREATE TABLE` comum cria uma tabela vazia.
3. **C3-Q03.** A lista explicita o mapeamento valor–coluna e reduz dependência da ordem física declarada. Valores trocados podem causar erro de tipo ou, quando compatíveis, armazenar dados incorretos silenciosamente.
4. **C3-Q04.** `*` retorna todas as colunas; a lista retorna somente as indicadas. Isso não filtra linhas; use `WHERE` para selecioná-las.
5. **C3-Q05.** `WHERE idade >= 18 AND idade < 30`. Inclui 18, exclui 30; com idade inteira, vai de 18 a 29.
6. **C3-Q06.** Sem filtro, o comando tenta atualizar ou excluir todas as linhas da tabela. Restrições, permissões ou outros mecanismos podem impedir a operação; a ausência de filtro não a limita a uma linha.
7. **C3-Q07.** `DELETE` remove linhas e mantém a estrutura. `DROP TABLE` remove o próprio objeto, sujeito a dependências.
8. **C3-Q08.** Não há ordem garantida sem `ORDER BY`. Use `ORDER BY cidade ASC, idade DESC`; acrescente uma chave única se precisar desempatar totalmente.
9. **C3-Q09.** Aspas simples delimitam um literal de texto. Aspas duplas delimitam identificadores, por exemplo `"Nome Completo"`; `"Ana"` seria um identificador, não o texto Ana.
10. **C3-Q10.** Execute `SELECT *` e/ou `SELECT COUNT(*)` com o mesmo `WHERE` e confira os registros. Isso detecta filtros amplos ou incorretos; em ambiente concorrente, a conferência prévia por si só não congela o conjunto de linhas.

## Capítulo 4

1. **C4-Q01.** `CHAR(2)` tem comprimento fixo com preenchimento; `VARCHAR(50)` é texto variável limitado; `INTEGER` armazena inteiros; `NUMERIC(10,2)` representa decimais exatos com duas casas; `DATE` é data; `TIME` é hora; `TIMESTAMP` combina data e hora. Use `NUMERIC` para os preços deste modelo, evitando aproximações de ponto flutuante.
2. **C4-Q02.** `'D''Avila'`: duplique a aspa simples interna.
3. **C4-Q03.** Não: zero é número, `''` é texto conhecido de comprimento zero e `NULL` indica ausência/valor desconhecido. A comparação com `NULL` resulta em desconhecido, que não passa no `WHERE`; use `IS NULL` ou `IS NOT NULL`.
4. **C4-Q04.** Omissão e palavra `DEFAULT` usam a expressão padrão da coluna. `NULL` explícito armazena nulo se permitido; não aciona o default. Sem default declarado, a omissão normalmente resulta em `NULL`, sujeito às restrições.
5. **C4-Q05.** O alias dá nome à expressão no resultado e não altera a definição persistente. Comentários: `-- comentário até o fim da linha` e `/* comentário de bloco */`.
6. **C4-Q06.** `AND` precede `OR`. Sem parênteses, todos do PR passam, mais os ativos de SP. Para exigir ativo nos dois estados: `WHERE (uf = 'PR' OR uf = 'SP') AND ativo = true`.
7. **C4-Q07.** `BETWEEN` inclui 100 e 200. `IN ('PR','PE')` simplifica várias igualdades alternativas sobre a mesma expressão.
8. **C4-Q08.** `%` combina zero ou mais caracteres e `_` combina um caractere. `LIKE 'Ana%'` exige prefixo Ana; `~ '^Ana'` também ancora no início; `~ 'Ana'` pode encontrar Ana em qualquer posição. Esses operadores são sensíveis a maiúsculas neste uso; `~*` oferece regex sem essa distinção.
9. **C4-Q09.** `CASE` constrói um valor condicional; `DISTINCT` elimina duplicatas do conjunto de expressões selecionadas; `upper()` transforma o texto no resultado. `DISTINCT cidade, uf` distingue pares, não apenas cidades.
10. **C4-Q10.** `SET` altera um parâmetro da sessão; `SHOW` exibe o valor; `RESET` restaura o padrão aplicável à sessão. Esse padrão pode vir de configuração de banco, usuário ou conexão, não necessariamente do valor de fábrica. Um `SET` manual anterior também pode explicar diferença entre o valor inicialmente observado e o valor após `RESET`.

## Capítulo 5

1. **C5-Q01.** Respectivamente: contar, somar, calcular média, obter menor e maior valor de um conjunto.
2. **C5-Q02.** `COUNT(*) = 3`, `COUNT(coluna) = 2`, `SUM = 30`, `AVG = 15`. A média não inclui o nulo no denominador.
3. **C5-Q03.** Uma linha de resultado: contagem zero e soma `NULL`. Sem entradas não há valores a somar; isso difere de somar valores zero.
4. **C5-Q04.** Forma um grupo para cada UF; com cidade, forma um grupo para cada par UF/cidade.
5. **C5-Q05.** Nome não está agregado nem determinado pela chave de agrupamento deste modelo: uma UF pode ter vários nomes. Não há um nome único para exibir por grupo. Incluí-lo no `GROUP BY` muda a granularidade.
6. **C5-Q06.** `WHERE` filtra linhas antes da agregação; `HAVING` filtra grupos após a agregação.
7. **C5-Q07.** `SELECT uf, COUNT(*) FROM clientes GROUP BY uf HAVING COUNT(*) > 1;` Uma agregação desse nível não pode ser usada no `WHERE` da mesma consulta.
8. **C5-Q08.** As linhas com a mesma chave nula formam um grupo. Isso não significa que `NULL = NULL` passe a ser verdadeiro em comparações comuns.
9. **C5-Q09.** `SELECT uf, COUNT(*) AS quantidade FROM clientes GROUP BY uf ORDER BY quantidade DESC, uf;`.
10. **C5-Q10.** Por exemplo, `SELECT * FROM pedidos WHERE status = 'cancelado';` e `SELECT COUNT(*) FROM pedidos WHERE status = 'cancelado';`. Compare conteúdo e quantidade antes de usar o mesmo filtro no `DELETE`.

## Capítulo 6

1. **C6-Q01.** Separa fatos sobre entidades distintas e evita repetir nome/endereço do cliente a cada pedido ou a descrição do produto a cada item. Isso reduz inconsistências de atualização.
2. **C6-Q02.** `p.id` e `c.id` distinguem ids de pedidos e clientes. Sem qualificação, `SELECT id` em uma junção que contém ambas as colunas é ambíguo.
3. **C6-Q03.** Cada linha de uma tabela combina com cada linha da outra: produto cartesiano. Com 6 e 8 linhas, são 48 combinações.
4. **C6-Q04.** Uma linha de cliente combina com cada um de seus pedidos. Repetir os dados do cliente no resultado é comportamento esperado de uma relação um-para-muitos.
5. **C6-Q05.** Não aparece porque não há linha correspondente em pedidos. `LEFT JOIN`, com clientes à esquerda, permite incluí-lo; é uma extensão ao capítulo 6.
6. **C6-Q06.** Nomes podem repetir ou mudar; ids estáveis e únicos identificam a entidade. Um código curto, único e suficientemente estável também pode funcionar. A escolha depende do domínio e das garantias de integridade.
7. **C6-Q07.** É a junção de uma tabela com ela mesma. Dois aliases representam papéis distintos, por exemplo clientes `a` e `b` da mesma cidade.
8. **C6-Q08.** Equijoin liga por igualdade; non-equijoin usa outra comparação. Exemplo: `produtos p JOIN produtos ref ON p.preco < ref.preco`, filtrando o id do produto de referência.
9. **C6-Q09.** Uma única coluna comporta apenas uma referência de produto por pedido. A tabela `itens` mantém uma linha por produto no pedido, com quantidade, e permite vários produtos sem repetir os dados do cabeçalho.
10. **C6-Q10.** A PK identifica uma linha de maneira única e não nula; a FK exige correspondência com uma chave referenciada, salvo valores nulos permitidos. A FK não escreve o `JOIN` automaticamente. Para preservar histórico comercial, registre o preço de venda no item; depender sempre do cadastro atual pode alterar retroativamente os totais calculados.

## Capítulo 11

1. **C11-Q01.** Uma estrutura de acesso permite localizar poucas linhas sem percorrer toda a tabela. Índices ocupam disco e precisam de manutenção nas escritas que afetam suas entradas; muitos índices podem aumentar esse custo.
2. **C11-Q02.** Não. Quando grande parte da tabela será lida, percorrê-la sequencialmente pode custar menos que consultar o índice e buscar muitas páginas da tabela. Tamanho, cache, estatísticas e custos estimados influenciam a decisão.
3. **C11-Q03.** Igualdade em cliente, seguida de intervalo em data, costuma aproveitar bem essa ordem no B-tree. Filtros apenas por data também podem usar o índice, dependendo da distribuição e da versão; no PostgreSQL 18, skip scan é uma possibilidade. Verifique o plano em vez de aplicar a proibição absoluta do exemplo histórico.
4. **C11-Q04.** Impede duplicatas das chaves não nulas. Por padrão, aceita vários `NULL`; nas versões que suportam `NULLS NOT DISTINCT`, é possível mudar esse tratamento. Em índice composto, a combinação das colunas é única: repetir uma delas isoladamente pode ser permitido.
5. **C11-Q05.** Reorganiza fisicamente a tabela segundo um índice existente. É uma operação pontual, não mantém novas linhas automaticamente nessa ordem e não garante a ordem do resultado de consultas. Use `ORDER BY` para apresentação.
6. **C11-Q06.** O controle de concorrência mantém versões que podem ser necessárias a outras transações. Quando elegíveis para limpeza, o `VACUUM` comum disponibiliza seu espaço para reutilização, geralmente sem reduzir proporcionalmente o arquivo; permite leituras e escritas usuais. `VACUUM FULL` reescreve a tabela, pode devolver espaço ao SO e exige `ACCESS EXCLUSIVE`. O VACUUM comum também pode precisar de bloqueios breves em certas etapas, como truncamento final.
7. **C11-Q07.** `ANALYZE` coleta estatísticas para o planejador. `VACUUM` faz manutenção de versões e espaço, entre outras funções de manutenção. `VACUUM (ANALYZE)` combina ambos. O autovacuum pode executar essas tarefas automaticamente.
8. **C11-Q08.** `EXPLAIN` mostra o plano estimado sem executar a consulta; `EXPLAIN ANALYZE` executa e registra medidas. `cost` usa unidades convencionais do planejador, não milissegundos. Compare estimativas de linhas com linhas reais no mesmo nó, considerando que `actual rows` é uma média por execução quando `loops > 1`.
9. **C11-Q09.** Cache, carga concorrente, planejamento, armazenamento e variação da execução podem explicar diferenças. Repita a mesma consulta, registre buffers e planos e descreva o ambiente. Três repetições são um exercício de observação, não uma prova estatística de desempenho.
10. **C11-Q10.** Não: ordem das colunas, filtros e custo diferem. A FK não cria automaticamente um índice no lado que referencia; PK e UNIQUE normalmente criam índices no lado referenciado. Avalie consultas, joins, escritas e planos para decidir quais índices manter.

As atualizações de comportamento em relação ao livro estão documentadas e referenciadas ao final do roteiro principal. Os resultados numéricos dos laboratórios constam em comentários no arquivo `03_Solucoes_Laboratorios.sql`.
