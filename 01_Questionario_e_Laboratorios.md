# PostgreSQL — Questionário e laboratórios

Material autoral em português baseado nos capítulos 3, 4, 5, 6 e 11 de *PostgreSQL: Introduction and Concepts*, Bruce Momjian, edição Addison–Wesley de 2000/2001, arquivo `PG_BruceMomjian.pdf`. Os exercícios usam um cenário próprio de treinamento; não são transcrições dos exercícios do livro.

## Roteiro de estudo

| Capítulo | Tema | Páginas impressas | Páginas do PDF¹ | Tempo sugerido |
|---|---|---|---|---|
| 3 | Comandos SQL básicos | 11–22 | 39–50 | 60–90 min |
| 4 | Personalização de consultas | 23–47 | 51–75 | 90–120 min |
| 5 | Agregações SQL | 49–55 | 77–83 | 60–90 min |
| 6 | Junções entre tabelas | 57–77 | 85–105 | 90–120 min |
| 11 | Desempenho | 131–136 | 159–164 | 90–120 min |

¹ Contagem a partir da primeira página do arquivo, inclusive páginas sem numeração.

Leia o capítulo, responda às dez questões sem consultar o gabarito e execute o laboratório correspondente. Para cada tarefa prática, entregue SQL, resultado e uma breve explicação. Em desempenho, entregue também os planos de execução e as condições de medição.

## Preparação

Use um banco descartável de treinamento e uma conta que possa criar schemas, tabelas e índices e manter os objetos que criar. Não use dados de clientes. A preparação cria o schema `bdadosql` e falha se ele já existir, para evitar sobrescrever um estudo anterior.

Execute `00_preparacao.sql` uma vez. Alternativa opcional ao DBeaver: no terminal da própria VM, com o arquivo disponível nela, use o psql:

```text
psql -h localhost -U SEU_USUARIO -d SEU_BANCO -v ON_ERROR_STOP=1 -f 00_preparacao.sql
```

No pgAdmin ou DBeaver, abra o arquivo e execute o SQL. Ao abrir outra sessão, execute `SET search_path TO bdadosql, public;`. As tabelas possuem nomes em português e identificadores explícitos; não é necessário estudar sequências para fazer estes laboratórios.

Os laboratórios 4, 5 e 6 usam a mesma carga inicial e não devem alterá-la. O laboratório 3 cria sua própria tabela. O laboratório 11 cria tabelas próprias. Isso permite executar os cinco laboratórios na sequência sem recarregar dados. As soluções estão em `03_Solucoes_Laboratorios.sql`; consulte-as depois de tentar.

## Capítulo 3 — Comandos SQL básicos

Referência: seções 3.1–3.10. Objetivo: criar uma tabela, inserir, consultar, filtrar, ordenar, atualizar e excluir dados.

### Questionário

1. **C3-Q01.** Diferencie servidor de banco, banco de dados, tabela, linha e coluna. Dê um exemplo de cada no cenário de uma loja.
2. **C3-Q02.** O que `CREATE TABLE` define? Uma tabela recém-criada já contém linhas?
3. **C3-Q03.** Por que é útil explicitar a lista de colunas em `INSERT`? O que pode acontecer se os valores forem informados na ordem errada?
4. **C3-Q04.** Qual a diferença entre `SELECT *` e `SELECT nome, cidade`? A seleção de colunas limita a quantidade de linhas?
5. **C3-Q05.** Escreva um filtro para pessoas com idade maior ou igual a 18 e menor que 30. Quais limites entram no resultado?
6. **C3-Q06.** Que linhas são afetadas por um `UPDATE` sem `WHERE`? E por um `DELETE` sem `WHERE`?
7. **C3-Q07.** Diferencie `DELETE FROM contatos` de `DROP TABLE contatos`.
8. **C3-Q08.** Uma consulta sem `ORDER BY` garante a ordem de inserção? Como ordenar por cidade crescente e idade decrescente?
9. **C3-Q09.** Em `WHERE nome = 'Ana'`, por que Ana usa aspas simples? Para que servem aspas duplas em SQL?
10. **C3-Q10.** Como conferir o conjunto de linhas antes de executar `UPDATE` ou `DELETE`? Por que essa conferência é útil?

### Laboratório 3 — Cadastro de contatos

Tempo: 45–60 min. Crie a tabela `contatos_lab3`; não altere `clientes`.

| id | nome | cidade | uf | idade |
|---|---|---|---|---|
| 1 | Ana | Curitiba | PR | 22 |
| 2 | Bruno | Londrina | PR | 31 |
| 3 | Carla | São Paulo | SP | 27 |
| 4 | Diego | Curitiba | PR | 19 |
| 5 | Elisa | Santos | SP | 35 |
| 6 | Fabio | Recife | PE | 27 |

1. **L3.1.** Crie a tabela com `id INTEGER`, `nome VARCHAR(50)`, `cidade VARCHAR(50)`, `uf CHAR(2)` e `idade INTEGER`. Insira os seis registros com lista explícita de colunas.
2. **L3.2.** Mostre somente nome e cidade de todos os contatos, ordenados por id.
3. **L3.3.** Consulte os contatos do PR com idade entre 20 e 31, inclusive. Ordene por id.
4. **L3.4.** Liste todos por idade decrescente; em caso de empate, nome crescente.
5. **L3.5.** Confira com `SELECT` o contato de id 2 e altere somente sua cidade para Maringá. Consulte novamente.
6. **L3.6.** Confira e remova somente contatos com idade menor que 20. Liste os restantes.
7. **L3.7.** Crie `rascunho_lab3`, insira uma linha, execute `DELETE` sem filtro e consulte a tabela vazia. Depois execute `DROP TABLE` e explique o que mudou.
8. **L3.8.** Entregue uma consulta final de `contatos_lab3` por id. Confira: cinco linhas; Bruno em Maringá; Diego ausente; os demais dados preservados.

Critério de conclusão: filtros corretos, ordenação reproduzível e alterações restritas às linhas previstas.

## Capítulo 4 — Personalização de consultas

Referência: seções 4.1–4.15. Objetivo: trabalhar com tipos, aspas, valores ausentes, padrões e expressões.

### Questionário

1. **C4-Q01.** Diferencie `CHAR(2)`, `VARCHAR(50)`, `INTEGER`, `NUMERIC(10,2)`, `DATE`, `TIME` e `TIMESTAMP`. Qual escolher para preço e por quê?
2. **C4-Q02.** Como representar o texto `D'Avila` em um literal SQL sem depender de configurações de escape?
3. **C4-Q03.** `NULL`, zero e texto vazio representam a mesma coisa? Por que `email = NULL` não encontra emails ausentes?
4. **C4-Q04.** Compare omitir uma coluna com `DEFAULT`, usar a palavra `DEFAULT` e informar `NULL` explicitamente.
5. **C4-Q05.** O que um alias com `AS` altera no resultado? Ele renomeia a coluna armazenada? Mostre um comentário de linha e um de bloco.
6. **C4-Q06.** Qual operador tem precedência: `AND` ou `OR`? Compare `uf = 'PR' OR uf = 'SP' AND ativo = true` com a versão que exige ativo para ambos os estados.
7. **C4-Q07.** `BETWEEN 100 AND 200` inclui os extremos? Quando `IN` facilita a escrita de filtros?
8. **C4-Q08.** Explique `%` e `_` no `LIKE`. Qual a diferença entre `LIKE 'Ana%'`, regex `~ '^Ana'` e regex `~ 'Ana'`?
9. **C4-Q09.** Para que servem `CASE`, `DISTINCT` e funções como `upper()`? Em `SELECT DISTINCT cidade, uf`, a distinção vale para qual conjunto de valores?
10. **C4-Q10.** Diferencie `SET`, `SHOW` e `RESET` em uma sessão. `RESET` significa necessariamente adotar o valor de fábrica?

### Laboratório 4 — Filtros e apresentação

Use as tabelas `clientes` e `produtos` da preparação. Faça experiências de escrita somente em uma tabela nova `config_lab4`.

1. **L4.1.** Liste id, nome e email dos clientes cujo email é `NULL`, por id. Compare com o resultado de `WHERE email = NULL` e explique a diferença.
2. **L4.2.** Crie `config_lab4 (id INTEGER, descricao VARCHAR(50), status VARCHAR(20) DEFAULT 'pendente')`. Insira três linhas: uma omitindo status, uma usando `DEFAULT` e outra usando `NULL`; uma descrição deve ser `D'Avila`. Consulte por id.
3. **L4.3.** Liste clientes ativos de PR ou SP. Use parênteses e ordene por id. Depois execute a versão sem parênteses descrita em C4-Q06 e identifique a linha adicional.
4. **L4.4.** Liste produtos com preço entre 100 e 500, inclusive, por id. Em outra consulta, liste clientes de PR ou PE usando `IN`.
5. **L4.5.** Liste clientes com nome começando por `Ana` usando `LIKE`; depois nomes que começam com A ou B maiúsculos usando regex `~ '^[AB]'`. Ordene por id.
6. **L4.6.** Liste cidades e UFs sem repetição, ordenadas por UF e cidade. Depois mostre os nomes em maiúsculas com alias `nome_maiusculo`. Inclua comentários nos comandos.
7. **L4.7.** Classifique cada produto como `baixo` (preço < 100), `medio` (100 a 500, inclusive) ou `alto` (> 500), usando `CASE`. Mostre id, nome, preço e faixa, por id.
8. **L4.8.** Execute `SHOW DateStyle`; guarde o valor. Use `SET DateStyle TO 'SQL, DMY'`, consulte `DATE '2026-10-16'`, execute `RESET DateStyle` e consulte novamente. Explique se o valor final coincide com o inicial e por que isso pode depender da configuração da sessão.

Critério de conclusão: diferenciar `NULL` de default, controlar precedência e justificar cada padrão de busca. `SET` aqui afeta a sessão, não modifica o servidor inteiro.

## Capítulo 5 — Agregações SQL

Referência: seções 5.1–5.5. Objetivo: resumir dados, agrupar e filtrar grupos.

### Questionário

1. **C5-Q01.** Qual a finalidade de `COUNT`, `SUM`, `AVG`, `MIN` e `MAX`?
2. **C5-Q02.** Em uma coluna contendo `10`, `20` e `NULL`, quais são `COUNT(*)`, `COUNT(coluna)`, `SUM(coluna)` e `AVG(coluna)`?
3. **C5-Q03.** Qual o resultado de `COUNT(*)` e `SUM(valor)` quando o filtro não encontra nenhuma linha e não há `GROUP BY`?
4. **C5-Q04.** O que `GROUP BY uf` faz? O que muda com `GROUP BY uf, cidade`?
5. **C5-Q05.** Por que `SELECT uf, nome, COUNT(*) FROM clientes GROUP BY uf` é inválida neste modelo?
6. **C5-Q06.** Diferencie `WHERE` de `HAVING` e diga qual deles exclui linhas antes do agrupamento.
7. **C5-Q07.** Corrija `SELECT uf, COUNT(*) FROM clientes WHERE COUNT(*) > 1 GROUP BY uf`.
8. **C5-Q08.** Como os valores `NULL` da chave de agrupamento são agrupados?
9. **C5-Q09.** Como ordenar estados pela quantidade de clientes, do maior para o menor, e desempatar pela UF?
10. **C5-Q10.** Antes de excluir pedidos por status, como usar `SELECT` e `COUNT(*)` com o mesmo filtro para conferir o impacto?

### Laboratório 5 — Resumo de pedidos

Use a carga inicial; não execute exclusões nem atualizações neste laboratório. `valor_total` contém o total do pedido e `desconto` pode ser desconhecido (`NULL`).

1. **L5.1.** Calcule quantidade de pedidos, soma, média arredondada para duas casas, mínimo e máximo de `valor_total`.
2. **L5.2.** Compare `COUNT(*)`, `COUNT(desconto)` e `AVG(desconto)`. Explique por que desconto desconhecido não entra como zero na média.
3. **L5.3.** Agrupe por status e mostre quantidade e soma dos valores, ordenando por status.
4. **L5.4.** Mostre quantidade e total por cliente, ordenados pelo total decrescente e por id do cliente.
5. **L5.5.** Mostre somente clientes com mais de um pedido, usando `HAVING`.
6. **L5.6.** Considere apenas pedidos pagos e mostre clientes cuja soma paga seja maior que 400. Use `WHERE` e `HAVING` na mesma consulta.
7. **L5.7.** Agrupe clientes por UF e cidade, com quantidade; ordene por UF e cidade.
8. **L5.8.** Consulte `COUNT(*)`, `SUM(valor_total)` e `AVG(valor_total)` para `status = 'inexistente'`. Repita agrupando por status e explique por que a quantidade de linhas do resultado muda.

Critério de conclusão: totais corretos, tratamento de `NULL` e uso de `WHERE`/`HAVING` no estágio adequado.

## Capítulo 6 — Junções entre tabelas

Referência: seções 6.1–6.14. Objetivo: relacionar tabelas, entender cardinalidade e modelar pedidos com vários itens.

### Questionário

1. **C6-Q01.** Por que separar clientes, pedidos e produtos em tabelas distintas? Cite uma duplicação evitada.
2. **C6-Q02.** Por que qualificar colunas com o nome ou alias da tabela? Dê um exemplo de ambiguidade envolvendo `id`.
3. **C6-Q03.** O que acontece se duas tabelas aparecem no `FROM` sem condição de ligação? Quantas linhas resultam do produto cartesiano de tabelas com 6 e 8 linhas?
4. **C6-Q04.** Em um relacionamento cliente–pedidos, por que um cliente pode aparecer várias vezes em um `INNER JOIN`?
5. **C6-Q05.** Um cliente sem pedidos aparece em um `INNER JOIN`? Justifique. Como extensão, cite uma junção que permita incluí-lo.
6. **C6-Q06.** Compare usar o nome do cliente e um identificador estável como chave de ligação. Um código curto e único também pode ser adequado?
7. **C6-Q07.** O que é self-join? Por que usar dois aliases da mesma tabela?
8. **C6-Q08.** O que diferencia equijoin de non-equijoin? Dê um exemplo usando preços.
9. **C6-Q09.** Por que guardar apenas um `produto_id` em `pedidos` não representa bem pedidos com vários produtos? Como uma tabela de itens resolve isso?
10. **C6-Q10.** Diferencie chave primária de estrangeira. A existência de uma FK elimina a necessidade de escrever a condição de junção? O preço histórico do item deveria depender sempre do preço atual do produto?

### Laboratório 6 — Pedidos com vários produtos

Relações: `pedidos.cliente_id → clientes.id`; `pedidos.vendedor_id → vendedores.id`; `itens.pedido_id → pedidos.id`; `itens.produto_id → produtos.id`. A chave de `itens` é `(pedido_id, produto_id)`. O preço unitário do item registra o preço da venda; o livro usa preço do cadastro em seu exemplo, mas discuta o efeito de uma alteração futura.

1. **L6.1.** Faça um `INNER JOIN` entre pedidos e clientes. Mostre pedido, cliente e valor, ordenando por pedido.
2. **L6.2.** Junte pedidos, clientes e vendedores. Mostre pedido, cliente e vendedor, com aliases claros e ordem por pedido.
3. **L6.3.** Junte pedidos, clientes, itens e produtos. Mostre pedido, cliente, produto, quantidade e subtotal (`quantidade * preco_unitario`), ordenando por pedido e produto.
4. **L6.4.** Agregue os itens por pedido e confira se sua soma coincide com `pedidos.valor_total`. Não some `valor_total` repetido a cada item. Explique essa armadilha de cardinalidade.
5. **L6.5.** Compare `SELECT COUNT(*) FROM clientes CROSS JOIN pedidos` com a contagem de uma junção correta. Identifique qual cliente não aparece no `INNER JOIN` usando os dados iniciais, sem exigir subconsulta.
6. **L6.6.** Faça self-join de clientes para encontrar pares da mesma cidade e UF. Exiba cada par uma vez, exclua a combinação da pessoa consigo mesma e ordene pelos ids do par.
7. **L6.7.** Usando self-join de produtos e uma comparação `<` de preços, encontre os produtos mais baratos que o produto id 2. Ordene por preço e id.
8. **L6.8.** Junte pedidos, clientes, vendedores, itens e produtos para listar os itens dos pedidos da cliente id 1. Depois consulte o pedido 101 e demonstre seus dois produtos. Explique a função das duas FKs da tabela de itens.

Critério de conclusão: condições completas, oito pedidos na consulta simples e dez linhas na consulta de itens. `LEFT JOIN` é uma extensão opcional: o livro desenvolve outer joins no capítulo 8, fora do recorte solicitado.

## Capítulo 11 — Desempenho

Referência: seções 11.1–11.7. Objetivo: investigar índices e planos, distinguir estatísticas de limpeza e observar organização física.

### Questionário

1. **C11-Q01.** Como um índice pode reduzir o trabalho de uma busca seletiva? Por que criar índices tem custos de disco e escrita?
2. **C11-Q02.** Ter um índice garante que toda consulta o utilize? Por que uma varredura sequencial pode ser a melhor opção?
3. **C11-Q03.** Para um índice B-tree `(cliente_id, data_evento)`, que filtro tende a aproveitar suas primeiras colunas? É correto afirmar que filtros só por data nunca podem usá-lo?
4. **C11-Q04.** O que `CREATE UNIQUE INDEX` impede? Como ele trata vários `NULL` por padrão? Para duas colunas, a unicidade vale individualmente ou para a combinação?
5. **C11-Q05.** `CLUSTER` organiza o quê? Mantém essa organização automaticamente após novas escritas? Substitui `ORDER BY`?
6. **C11-Q06.** Por que `UPDATE` e `DELETE` podem deixar versões mortas? Qual a função do `VACUUM` comum e como ele difere de `VACUUM FULL`?
7. **C11-Q07.** Diferencie `ANALYZE` de `VACUUM`. O que `VACUUM (ANALYZE)` combina?
8. **C11-Q08.** Diferencie `EXPLAIN` de `EXPLAIN ANALYZE`. Os números de `cost` são milissegundos? O que comparam `rows` estimado e `actual rows`?
9. **C11-Q09.** Por que comparar apenas o tempo de uma execução antes e outra depois do índice pode levar a uma conclusão incorreta?
10. **C11-Q10.** Um índice composto substitui qualquer índice simples? Toda FK cria automaticamente um índice na coluna que referencia a tabela pai? Como decidir com evidências?

### Laboratório 11 — Diagnóstico de desempenho

Tempo: 75–100 min. Use `02_Lab11_Preparacao.sql`, que gera 200 mil eventos e não cria índices na tabela `eventos_lab11`. Ele deve ser executado uma vez após a preparação principal. Não há dependência de dados externos. `generate_series`, funções de tamanho e catálogos são recursos auxiliares apresentados prontos para permitir o experimento.

Mantenha autocommit ativo. Execute cada `VACUUM` como comando separado, fora de `BEGIN` e sem execução do arquivo inteiro em uma transação. Na interface gráfica, selecione o comando `VACUUM` isoladamente. Comandos de medição abaixo são exemplos fornecidos; as demais consultas devem ser escritas por você.

```sql
SELECT version();
SELECT pg_size_pretty(pg_table_size('bdadosql.eventos_lab11')) AS tabela,
       pg_size_pretty(pg_indexes_size('bdadosql.eventos_lab11')) AS indices;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM bdadosql.eventos_lab11 WHERE id = 150000;
```

1. **L11.1.** Registre versão, tamanho da tabela e dos índices. Execute `ANALYZE` e meça a busca por id acima três vezes. Registre tipo de scan, linhas estimadas/reais, buffers, tempo de planejamento e execução. Esta é a linha de base sem índice.
2. **L11.2.** Crie um índice B-tree em `id`, repita exatamente a consulta três vezes e compare os planos. Compare também uma consulta que retorna todas as linhas. Explique a decisão do planejador sem exigir um tipo de scan fixo.
3. **L11.3.** Crie um índice composto em `(cliente_id, data_evento)`. Compare planos para: cliente 42; cliente 42 de 1 a 10 de abril de 2026, inclusive; e somente esse intervalo de datas. Use datas ISO e mantenha as mesmas colunas selecionadas. Discuta a ordem das colunas sem afirmar que o índice é inutilizável quando falta filtro na primeira.
4. **L11.4.** Em `codigos_lab11 (codigo INTEGER)`, crie um índice único. Insira 10, tente inserir 10 de novo e registre o erro esperado. Insira dois `NULL` e confira o resultado. Execute a tentativa duplicada isoladamente, em autocommit, para continuar os demais passos.
5. **L11.5.** Meça um intervalo de datas de eventos do cliente 42 antes e depois de `CLUSTER eventos_lab11 USING eventos_lab11_cliente_data_idx`, seguido de `ANALYZE`. Compare buffers e tempos; não presuma ganho. Consulte `pg_index.indisclustered` para identificar o índice escolhido. Explique o bloqueio e a necessidade de espaço para reescrita.
6. **L11.6.** Atualize `status = 'revisado'` onde `id <= 40000`; exclua onde `id > 180000`. Confira as quantidades afetadas. Meça tamanho e contagem; execute `VACUUM (VERBOSE, ANALYZE) bdadosql.eventos_lab11` isoladamente e repita as medições. Explique por que espaço reutilizável não implica redução proporcional do arquivo. O autovacuum e outras transações podem influenciar observações.
7. **L11.7.** Escolha um filtro, compare linhas estimadas/reais e escreva um diagnóstico com evidências. Como extensão, examine `pg_stats` para `cliente_id`. Não é necessário provocar artificialmente estatísticas ruins.
8. **L11.8.** Registre o tamanho dos índices, remova apenas o índice simples de `id` com `DROP INDEX` e repita a busca de L11.2. Produza um relatório de até uma página explicando benefícios, custos e limitações das medições. Preserve o índice composto para consulta posterior.

Use esta tabela no relatório (uma linha por execução):

| Etapa/consulta | Execução | Scan | Linhas estimadas/reais | Buffers hit/read | Planejamento (ms) | Execução (ms) | Observações |
|---|---|---|---|---|---|---|---|
| Sem índice / id | 1 | | | | | | |

Critério de conclusão: planos e medições reais registrados, distinção entre estimativa e tempo medido, e conclusão que considere cache, seletividade, estatísticas e custo de manutenção. Não há meta fixa de milissegundos ou exigência de ganho percentual.

## Atualizações em relação à edição histórica

- O `VACUUM` comum disponibiliza espaço para reutilização interna e em geral não compacta todo o arquivo nem devolve todo o espaço ao sistema operacional. `VACUUM FULL` reescreve a tabela e exige bloqueio exclusivo. A descrição histórica do livro não deve ser aplicada literalmente. Consulte a [documentação de VACUUM](https://www.postgresql.org/docs/18/sql-vacuum.html).
- `ANALYZE` atualiza estatísticas; `VACUUM (ANALYZE)` também faz a limpeza. Há manutenção automática por autovacuum; veja [manutenção rotineira](https://www.postgresql.org/docs/18/routine-vacuuming.html).
- Restrições `PRIMARY KEY` e `UNIQUE` criam índices automaticamente; uma FK não cria automaticamente índice no lado que referencia. Veja [restrições](https://www.postgresql.org/docs/18/ddl-constraints.html).
- A eficiência de índices B-tree compostos depende das condições, ordem de colunas e distribuição. Há possibilidades de uso sem filtro na primeira coluna, inclusive skip scan no PostgreSQL 18. Veja [índices multicoluna](https://www.postgresql.org/docs/18/indexes-multicolumn.html).
- `CLUSTER` exige `ACCESS EXCLUSIVE`, espaço de trabalho e não mantém a organização em novas escritas. A ordem de apresentação exige `ORDER BY`. Veja [CLUSTER](https://www.postgresql.org/docs/18/sql-cluster.html).
- `EXPLAIN (ANALYZE, BUFFERS)` executa a consulta e mostra medições; neste material é usado com `SELECT`. Veja [leitura de planos](https://www.postgresql.org/docs/18/using-explain.html).

## Avaliação sugerida

São **50 questões e 40 tarefas práticas**. Cada capítulo vale 20 pontos: 10 pelo questionário (1 por questão) e 10 pelo laboratório (1,25 por tarefa). Uma resposta conceitual recebe o ponto se explicar corretamente o comportamento; nas tarefas, considere 0,75 pelo SQL/execução e 0,50 pela conferência e explicação. Em desempenho, a conclusão baseada em evidências vale mesmo quando o índice ou o CLUSTER não melhoram o tempo.

Antes de consultar as soluções, confira se consegue explicar: efeito de um filtro ausente, lógica de `NULL`, diferença entre `WHERE` e `HAVING`, multiplicação de linhas em joins e motivos pelos quais o planejador pode ignorar um índice.
