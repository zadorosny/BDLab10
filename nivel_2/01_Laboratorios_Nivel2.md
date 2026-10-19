# PostgreSQL — Laboratórios de nível 2

Os laboratórios existentes no BDLab10 passam a ser a trilha de **nível 1**. Esta trilha acrescenta **cinco laboratórios e 30 desafios**, com problemas de integridade, regras de negócio, relatórios e investigação de desempenho. Mantém a progressão dos temas dos capítulos 3, 4, 5, 6 e 11, mas introduz recursos além desse recorte do livro: transações, CTEs, funções de janela, subconsultas, outer joins e estatísticas estendidas. Não são exercícios transcritos do livro.

## Como começar no Windows e no DBeaver

1. Ligue a VM Ubuntu no Hyper-V e conecte o DBeaver ao PostgreSQL de treinamento. Use preferencialmente PostgreSQL 18. O [guia principal](../LEIA-ME.md) explica conexão, banco e modo de execução.
2. Confirme o destino com `SELECT current_database(), current_user, version();`. Não é necessário recriar o banco do nível 1: o nível 2 usa seu próprio schema **bdadosql_n2**. Também funciona em um banco de treinamento novo, sem os scripts do nível 1.
3. Abra **00_Preparacao_Nivel2.sql** e execute como script completo, uma única vez. Deixe Auto-commit ativo: o arquivo contém seu próprio BEGIN/COMMIT. Se houver erro, interrompa, execute ROLLBACK e investigue. Não continue após falha na criação do schema.
4. Confira as contagens: clientes 8; produtos 6; pedidos 12; itens 15; pagamentos 12; estoques 2; importações 7; contatos tratados 0; acessos 4.
5. Em cada editor ou reconexão, execute `SET search_path TO bdadosql_n2, public;`. Salve suas tentativas em arquivos pessoais separados, como `n2_lab03_tentativas.sql`.
6. Execute somente a tarefa atual. Nos testes com BEGIN, SAVEPOINT e ROLLBACK, use o mesmo editor e a mesma sessão. Se o cliente abrir outra conexão, a transação não acompanha. Selecione e execute os comandos em etapas; para um erro intencional, execute a instrução de erro sozinha e depois a recuperação indicada.
7. As soluções ficam em **03_Solucoes_Nivel2.sql**, separadas por identificador. Consulte depois de tentar. Não execute o arquivo inteiro: contém transações, alterações e experimentos com ordem obrigatória.
8. Somente ao chegar ao N2-5, execute **02_Preparacao_Desempenho.sql**. A tabela de 300 mil eventos é independente das pequenas tabelas comerciais. Não crie índices antes da linha de base.

Para repetir tudo, use outro banco de treinamento e rode os dois preparadores no momento adequado. Os preparadores falham se os objetos já existirem: não são scripts de reinício. Os exercícios comerciais não devem alterar permanentemente pedidos, itens, produtos, clientes ou pagamentos. As únicas mudanças persistentes previstas no N2-1 são os contatos tratados; os estoques devem terminar como começaram.

Tempo sugerido: N2-1 e N2-2, 60–90 min cada; N2-3 e N2-4, 90–120 min cada; N2-5, 120–180 min. Ajuste ao seu ritmo. Entregue SQL, saída e explicação por tarefa; em desempenho, guarde os planos completos.

## Regras do cenário comercial

- valor_total é o valor bruto do pedido. A soma quantidade × preco_unitario dos itens deve reconciliar com ele. O preço do item é o preço histórico da venda.
- Para os relatórios financeiros desta trilha, **líquido contratado = valor_total − COALESCE(desconto, 0)**. NULL continua significando desconto desconhecido no cadastro; a conversão para zero é uma regra explícita deste relatório.
- Exclua pedidos cancelados dos relatórios financeiros e rankings, salvo instrução contrária. O status não substitui o cálculo do saldo.
- Em pagamentos, valor é sempre positivo. Recebimento soma; estorno subtrai. **Saldo = líquido contratado − recebido líquido**. Saldo positivo é a receber; negativo é crédito do cliente. Não esconda crédito transformando todos os saldos negativos em zero no total global.
- O pedido 112 recebeu 120 para um líquido de 100: tem crédito de 20. O pedido 104 recebeu 500 e teve estorno de 20: recebeu líquido 480.
- Ordene resultados com desempate estável. Ausência de ORDER BY não garante ordem. Valores esperados pressupõem a carga inicial e a execução dos testes de escrita com ROLLBACK.

## N2-1 — Integridade, transações e importação

Pré-requisitos novos: PRIMARY KEY, CHECK, BEGIN/COMMIT/ROLLBACK, SAVEPOINT, CTE, ROW_NUMBER e INSERT ON CONFLICT. Um SAVEPOINT marca um ponto dentro da transação; ROLLBACK TO recupera somente até esse ponto. Uma CTE (`WITH nome AS (...)`) organiza etapas de uma consulta. ROW_NUMBER numera linhas por grupo e ordem escolhidos.

### N2-1.1 — Provar as restrições

Examine as restrições de estoques e pagamentos pelo DBeaver ou pg_constraint. Demonstre separadamente as rejeições a estoque negativo, chave composta repetida e pagamento de pedido inexistente. Faça cada tentativa dentro de BEGIN/ROLLBACK, registrando erro e SQLSTATE. Depois de um erro, execute ROLLBACK antes da próxima tentativa. Não remova restrições para passar nos testes.

**Evidência:** erros esperados 23514 (CHECK), 23505 (unicidade) e 23503 (FK); estoques continuam A=10, B=5 e pagamentos continuam com 12 linhas.

### N2-1.2 — Transferência atômica de estoque

Em uma transação, transfira três unidades do produto 1 de A para B. Debite A com condição saldo >= 3 e RETURNING; somente prossiga ao crédito de B se exatamente uma linha foi debitada. Consulte os dois saldos e o total antes de decidir confirmar. Neste exercício, termine com **ROLLBACK**. Explique por que confirmar só o débito viola a regra da transferência e por que uma aplicação real precisa verificar a linha afetada.

**Evidência:** dentro da transação, A=7, B=8 e total=15; após ROLLBACK, A=10 e B=5.

### N2-1.3 — Recuperar uma falha sem perder tudo

Abra uma transação, debite duas unidades de A e crie um SAVEPOINT. Tente definir saldo negativo em B, isoladamente. Recupere com ROLLBACK TO SAVEPOINT; confira que o débito anterior ao savepoint permanece. Credite duas unidades em B, confira o total e termine com ROLLBACK completo.

**Evidência:** após recuperar a falha, A=8 e B=5; após crédito, A=8 e B=7; ao final A=10 e B=5. Explique a diferença entre ROLLBACK e ROLLBACK TO.

### N2-1.4 — Diagnosticar o lote bruto

Sem alterar importacao_contatos, normalize nome com btrim, email com lower/btrim/NULLIF e UF com upper/btrim. Considere válidos: nome não vazio; email ausente ou compatível com `^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$`; UF em PR, SP, PE, RS, RJ ou SC. Essa regex é um filtro didático, não validação completa de endereço de email. Liste o motivo de rejeição e identifique ids repetidos entre os válidos.

**Evidência:** sete linhas brutas, cinco válidas, duas inválidas (lotes 6 e 7); cliente 3 tem dois registros válidos. Não elimine duplicatas antes de contar e explicar a qualidade do lote.

### N2-1.5 — Importar com desempate e repetição segura

Entre os válidos, escolha o maior lote_id por cliente_id. Use ROW_NUMBER com PARTITION BY e importe em contatos_tratados com ON CONFLICT (cliente_id) DO UPDATE. Execute a mesma importação duas vezes; compare o conteúdo final. Explique por que deduplicar antes do UPSERT é necessário quando duas entradas atingem a mesma chave.

**Evidência:** quatro contatos, ids 1, 2, 3 e 9; cliente 3 se chama Carla Nova; cliente 2 tem email NULL; nomes e emails tratados. A segunda execução mantém o mesmo conteúdo, mesmo que o comando reporte atualizações.

### N2-1.6 — Reserva condicional sem saldo negativo

Em BEGIN, tente retirar oito unidades de A com UPDATE condicionado a saldo >= 8, usando RETURNING. Repita a tentativa ainda na mesma transação. Termine com ROLLBACK. Discuta a vantagem sobre consultar o saldo e executar depois um UPDATE incondicional. Esta é uma demonstração em uma sessão; não conclua que ela testa toda a concorrência de uma aplicação.

**Evidência:** primeira tentativa retorna saldo 2; a segunda afeta zero linhas; depois do ROLLBACK, saldo 10.

## N2-2 — Filtros, NULL, texto e limites de datas

Pré-requisitos novos: NULLIF, btrim, IS DISTINCT FROM, timestamptz, AT TIME ZONE e intervalos com limite superior exclusivo. Todas as tarefas são de leitura. Não transforme valores ausentes no cadastro para facilitar a consulta.

### N2-2.1 — Ausência de email com regra composta

Encontre clientes ativos de PR ou SP cujo email normalizado esteja ausente, incluindo espaços vazios. Mostre id, nome, UF e email original. Entregue uma versão com parênteses claros e explique por que email IS NULL sozinho não atende à regra.

**Evidência:** apenas Diego, id 4. Ana não entra: seu email tem espaços, mas não é vazio.

### N2-2.2 — Desconhecido, zero e positivo

Em uma única consulta agregada de pedidos, conte descontos desconhecidos, zero e positivos sem confundir NULL com zero. Mostre também as somas de desconto original e com COALESCE, explicando por que podem coincidir mesmo com semânticas diferentes.

**Evidência:** desconhecidos=3, zero=6, positivos=3; soma de descontos=40. Os três grupos cobrem os 12 pedidos.

### N2-2.3 — Março no horário de São Paulo

Em acessos, encontre os eventos de março de 2026 considerando America/Sao_Paulo. Construa o filtro direto em ocorrido_em com limites timestamptz equivalentes a 01/03 00:00 local e 01/04 00:00 local, usando >= e <. Mostre também a apresentação local com AT TIME ZONE. Execute a consulta com a sessão em UTC e depois em America/Sao_Paulo; mantenha os limites explícitos e restaure a configuração ao terminar.

**Evidência:** ids 2 e 3 nas duas execuções. O id 1 ainda é fevereiro local; o 4 já é abril local. Explique o risco de usar BETWEEN com o primeiro instante do mês seguinte e de converter a coluna para date para filtrar sem considerar o fuso.

### N2-2.4 — Faixas de preço sem buracos

Classifique produtos como baixo (<100), medio (100 até 500, inclusive) e alto (>500). Entregue a listagem e a quantidade por faixa. Demonstre o comportamento nos limites 100 e 500 com VALUES, sem inserir produtos extras.

**Evidência:** baixo=2, medio=3, alto=1; 100 e 500 são medio.

### N2-2.5 — NULL na comparação

Compare os ids retornados por desconto <> 0 e desconto IS DISTINCT FROM 0. Entregue também a consulta que identifica exatamente os ids presentes em uma versão e ausentes na outra usando EXCEPT. Explique qual expressão escolher para buscar desconto positivo e qual serve para detectar qualquer diferença em relação a zero, incluindo ausência.

**Evidência:** <> retorna 101,104,107; IS DISTINCT FROM acrescenta 102,105,108. Não trate a segunda lista como prova de que o desconto é positivo.

### N2-2.6 — Caracteres literais em padrões

Encontre o produto cujo nome contém o caractere % literal e depois aquele que contém _ literal. Use LIKE com um caractere de escape explícito, como !. Compare com LIKE '%_%' e explique a diferença entre wildcard e texto literal. Ordene por id.

**Evidência:** as buscas literais retornam somente Cabo_100%, id 6; o padrão sem escape retorna os seis produtos.

## N2-3 — Relatórios financeiros e funções de janela

Pré-requisitos novos: FILTER, CTE, generate_series, date_trunc, ROW_NUMBER, LAG e SUM OVER. Uma janela mantém as linhas do resultado e calcula sobre seu grupo; GROUP BY resume linhas. Use ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW para explicitar o acumulado. Todas as tarefas usam a carga original, sem escrita.

### N2-3.1 — Receita contratada com meses vazios

Gere um calendário de janeiro a junho de 2026. Calcule o líquido contratado por mês, excluindo cancelados e preservando os meses sem pedidos. Entregue exatamente uma linha por mês, com zero nos vazios. Trate como competência a data do pedido, não a do pagamento.

**Evidência:** janeiro=1290; fevereiro=980; março=540; abril=250; maio=0; junho=0. Total=3060.

### N2-3.2 — Posição financeira por pedido

Agregue pagamentos por pedido ANTES de ligá-los ao cabeçalho. Mostre contratado, recebido líquido, saldo e situação (a_receber, quitado ou credito) de cada pedido não cancelado. Inclua pedidos sem pagamento e confira os totais. Não substitua o saldo pelo status cadastrado.

**Evidência:** dez pedidos; contratado=3060, recebido=2730, saldo assinado=330. A receber positivo=350 e crédito=20. Pedido 112 tem saldo -20; 104 tem recebido 480 e saldo zero.

### N2-3.3 — Dois maiores clientes de cada mês

Some o líquido contratado por cliente e mês; use ROW_NUMBER para selecionar no máximo os dois maiores de cada mês. Desempate por cliente_id crescente e não por nome. Explique como o resultado mudaria se a regra pedisse todos os empatados na segunda posição e fosse usado DENSE_RANK somente pelo total.

**Evidência:** janeiro: (1,1140),(2,150); fevereiro: (4,500),(3,480); março: (6,300),(5,190); abril: (5,150),(3,100). O cliente 1 fica fora do top 2 de março.

### N2-3.4 — Acumulado e variação mensal

Sobre os seis meses de N2-3.1, calcule total acumulado, receita do mês anterior com LAG e variação percentual. O primeiro mês não tem anterior. Se o anterior for zero, a variação percentual deve ser NULL, evitando divisão por zero. Não remova os meses vazios antes da janela.

**Evidência:** acumulados=1290,2270,2810,3060,3060,3060; maio varia -100%; junho tem variação NULL. Use round(...,2) apenas na apresentação.

### N2-3.5 — Recebimentos e estornos separados

Por mês de pagamento, mostre recebimentos brutos, estornos, recebido líquido e percentual estornado sobre o bruto. Preserve janeiro a junho e proteja a divisão por zero. Compare com a competência de N2-3.1 e explique por que as duas visões podem divergir em um cenário real.

**Evidência:** líquidos por mês=1190,780,490,270,0,0; fevereiro tem bruto 800, estorno 20 e percentual 2,50%; total líquido=2730. Nesta carga, datas de recebimento permanecem no mês do pedido, mas há pagamentos parciais e créditos.

### N2-3.6 — Cobrança sem compensação indevida

Produza relatório por cliente com valor a receber e crédito separados. Considere somente pedidos não cancelados. Classifique cada saldo POR PEDIDO antes de agregar, de modo que eventual crédito de um pedido não esconda dívida de outro. Mostre somente clientes com a receber > 0.

**Evidência:** clientes 1=50, 2=100 e 4=200 a receber. Em uma consulta complementar sem HAVING, cliente 3 tem crédito=20. Explique por que SUM(saldo) e SUM(GREATEST(saldo,0)) respondem perguntas diferentes.

## N2-4 — Cardinalidade, ausência e reconciliação

Pré-requisitos novos: LEFT JOIN, FULL JOIN, NOT EXISTS e LEFT JOIN LATERAL. Uma junção lateral pode consultar dados da linha à esquerda; LIMIT 1 exige ORDER BY determinístico. Todas as tarefas de escrita terminam com ROLLBACK.

### N2-4.1 — Clientes sem movimento no relatório

Liste todos os oito clientes, quantidade de pedidos não cancelados e total líquido contratado. Clientes sem pedidos elegíveis devem aparecer com zero. Faça uma versão com o filtro de status no ON ou em uma CTE e explique o efeito de colocá-lo no WHERE depois do LEFT JOIN. Não use COUNT(*) para contar filhos ausentes.

**Evidência:** Gabriela e Hugo aparecem com zero; total global contratado=3060 e quantidade=10.

### N2-4.2 — Anti-join resistente a NULL

Encontre clientes sem nenhum pedido não cancelado usando NOT EXISTS. Depois compare NOT IN e NOT EXISTS para excluir os ids da lista VALUES (2),(NULL::integer). Explique por que a presença de NULL muda o primeiro filtro.

**Evidência:** sem pedidos elegíveis: 7 e 8; exclusão da lista com NOT IN retorna zero clientes; com NOT EXISTS retorna sete, todos exceto 2.

### N2-4.3 — Investigar uma soma inflada

Para o pedido 101, junte diretamente pedidos, itens e pagamentos e some os subtotais dos itens e o recebido. Conte as linhas intermediárias e identifique a multiplicação. Corrija usando duas agregações independentes por pedido antes da junção. Explique por que SUM(DISTINCT valor) não é uma solução geral.

**Evidência:** junção ingênua produz quatro linhas, subtotal inflado=500 e recebido inflado=480. A versão correta retorna bruto dos itens=250, recebido=240 e líquido contratado=240. Valores diferentes aqui podem representar desconto, não erro de cadastro.

### N2-4.4 — Último pedido sem perder clientes

Use LEFT JOIN LATERAL para mostrar o pedido mais recente de cada cliente, incluindo cancelados, preservando clientes sem pedidos. Desempate por data_pedido DESC, id DESC. Como alternativa, entregue versão com ROW_NUMBER e compare o resultado usando EXCEPT nas duas direções.

**Evidência:** ids dos últimos pedidos dos clientes 1 a 6: 108,103,112,111,110,109; clientes 7 e 8 ficam com NULL. As versões devem retornar o mesmo conjunto.

### N2-4.5 — Auditoria com registros ausentes dos dois lados

Simule duas fontes em CTEs: em cabecalhos, exclua o pedido 111 e acrescente 1 ao valor_total do 101; em totais_itens, exclua o pedido 112 e agregue os itens restantes. Não altere as tabelas reais. Use FULL JOIN para listar somente divergências, identificando ausência em cada fonte ou diferença de valor. Use IS DISTINCT FROM para comparar valores com NULL.

**Evidência:** três ocorrências: 101 com diferença de 1; 111 somente nos itens; 112 somente no cabeçalho. Uma junção interna esconderia os dois registros ausentes.

### N2-4.6 — Preço histórico versus preço atual

Em BEGIN, calcule os itens do pedido 101 pelo preço histórico e pelo cadastro atual. Altere somente o preço atual do Mouse para 60, repita a comparação e execute ROLLBACK. Entregue uma conclusão sobre qual preço usar em receita histórica e em uma simulação de reposição a preços atuais.

**Evidência:** antes, ambos=250; depois, histórico=250 e cadastro atual=270; após ROLLBACK, preço do Mouse=50. Não reescreva o preço dos itens.

## N2-5 — Desempenho orientado por hipóteses

Execute **02_Preparacao_Desempenho.sql** uma vez. Esperado: 300000 linhas, 1000 clientes, 15000 pendentes e 82 linhas no filtro de referência. A distribuição UF/cidade tem dependência intencional para estudar estatísticas conjuntas; não é necessário produzir estatísticas desatualizadas. Não altere parâmetros globais nem desative scans para forçar um plano.

Antes de cada etapa, consulte pg_indexes para saber quais índices já existem. Se perdeu a linha de base, recomece em outro banco de treinamento; não compare um estado já reorganizado como se fosse o original. Auto-commit ativo para os experimentos de manutenção, sem transação pendente. Meça três vezes cada consulta em cada condição, mantendo filtro e projeção iguais. Registre versão, CPU/RAM da VM, cache observado e índices existentes. Não há meta fixa de milissegundos nem obrigação de escolher um tipo específico de scan.

### N2-5.1 — Linha de base e seletividade

Sem índices em eventos, execute ANALYZE, registre tamanhos e meça estas três consultas com EXPLAIN (ANALYZE, BUFFERS): cliente 42 entre 01/03 e 10/04 inclusive; somente esse intervalo de datas; todos os eventos. Mantenha SELECT * nas três. Relacione cardinalidade e seletividade com o plano. Não some buffers de pai e filho, pois isso pode contar o mesmo trabalho duas vezes. Em nós repetidos, actual rows é uma média por execução; interprete loops e workers.

**Evidência:** filtro combinado=82 linhas; intervalo sem cliente=82000; tabela inteira=300000. Guarde os nove planos antes da criação dos índices.

### N2-5.2 — Índice composto e seu custo

Crie B-tree (cliente_id, data_evento). Repita as três consultas de N2-5.1 e compare o trabalho e o tamanho do índice. Explique por que o índice pode ajudar o filtro seletivo e não ser escolhido para a tabela inteira. Para a busca só por data, descreva o plano real sem afirmar que a ausência de filtro na primeira coluna impede todo uso do índice.

**Evidência:** resultados idênticos aos da linha de base; conclusão baseada em buffers, estimativas, linhas e custo de armazenamento, além do tempo. Não confunda cost com milissegundos.

### N2-5.3 — Índice parcial para a fila pendente

Meça SELECT * de eventos pendentes em março (>=01/03 e <01/04), ordenados por data_evento,id, LIMIT 50. Projete um índice parcial (data_evento,id) WHERE status='pendente', crie e repita. Compare também a consulta equivalente para status='pago': explique por que o índice parcial não cobre essa população. Registre tamanhos do índice parcial e do composto.

**Evidência:** há 4000 pendentes em março antes do LIMIT; a busca limitada retorna 50 linhas. Não exija uso do índice se o plano real justificar outra estratégia. Sua conclusão deve distinguir predicado do índice, ordenação e limite.

### N2-5.4 — Índice de expressão

Meça SELECT * WHERE lower(email)='cliente42@example.test', três vezes. Crie um índice em lower(email), execute ANALYZE e repita as medições. Explique a diferença entre um índice na coluna original e um na expressão e acrescente uma consulta de conferência dos ids antes/depois.

**Evidência:** 300 linhas nas duas condições; expressão no filtro compatível com a expressão indexada. Observe eventuais Bitmap Scans sem tratá-los como falha.

### N2-5.5 — Estatísticas individuais e dependência entre colunas

Meça SELECT * WHERE uf='PR' AND cidade='Curitiba' antes de criar estatísticas estendidas. Examine pg_stats para cliente_id, uf e cidade. Verifique por agrupamento se UF determina cidade nesta carga. Crie CREATE STATISTICS com dependencies sobre uf,cidade, execute ANALYZE e meça novamente a MESMA consulta. Consulte pg_stats_ext. Compare linhas estimadas/reais; registre um nó comparável, considerando loops e paralelismo.

**Evidência:** 180000 linhas reais, PR aparece apenas com Curitiba e SP apenas com Santos. As condições são dependentes: não reduzem a população independentemente. Não confunda correlation de pg_stats (ordem física de uma coluna) com dependencies (relação entre colunas). Criar estatísticas não cria índice nem reorganiza a tabela. Se a estimativa já era boa, documente isso.

### N2-5.6 — Organização física, versões mortas e relatório final

Crie eventos_fisicos como cópia de eventos, sem tocar nos experimentos anteriores; crie nela um índice (cliente_id,data_evento). Meça o filtro de referência três vezes, consulte correlation e tamanhos. Execute CLUSTER pela cópia e ANALYZE, repita a medição e a consulta de estatísticas. Depois atualize status para revisado onde id<=60000 e exclua id>270000. Registre contagens e tamanhos antes/depois de VACUUM (VERBOSE, ANALYZE), executado isoladamente.

**Evidência:** após as escritas, 270000 linhas vivas, 60000 revisadas e nenhuma com id>270000. Até 90000 versões mortas podem ter sido geradas pelas duas escritas; autovacuum, poda e outras condições afetam o que o VACUUM reporta. Espaço reutilizável não obriga redução do arquivo. CLUSTER exige bloqueio exclusivo e não mantém a organização nas novas escritas.

**Extensão opcional:** registre os tamanhos, execute VACUUM FULL somente na cópia, isoladamente, depois ANALYZE, e compare. Ele reescreve a tabela e exige espaço e bloqueio exclusivo; não é manutenção necessária para concluir a tarefa. Não misture medições dessa etapa com a linha de base original.

Entregue relatório de uma página: hipótese, método, evidências, conclusão, limitação e recomendação de quais índices manter para as consultas testadas. Uma conclusão de ausência de ganho é válida se sustentada pelos dados. Distingua limpeza (VACUUM), atualização de estatísticas (ANALYZE) e organização física (CLUSTER/FULL).

## Modelo de evidências e avaliação

Por tarefa, salve: identificador, SQL, estado inicial necessário, resultado esperado/obtido, explicação e correção depois da primeira tentativa. Os erros intencionais são evidência de integridade, não falhas a esconder.

| Etapa/consulta | Execução | Índices existentes | Nó/loops | Estimadas/reais | Buffers hit/read | Planejamento ms | Execução ms | Observação |
|---|---|---|---|---|---|---|---|---|
| N2-5.1 / cliente e data | 1 | nenhum | | | | | | |

Cada laboratório vale 20 pontos: seis tarefas de 3 pontos (SQL/método=1; resultado/evidência=1; explicação=1) e 2 pontos por organização e revisão. Total=100. Em desempenho, não se atribui nota por tempo mínimo: avalie consistência do método e qualidade das evidências. Não há questionário adicional de múltipla escolha nesta trilha; o foco é resolver e justificar problemas práticos.

## Referências oficiais e limites da validação

- [Transações](https://www.postgresql.org/docs/18/tutorial-transactions.html) e [SAVEPOINT](https://www.postgresql.org/docs/18/sql-savepoint.html).
- [INSERT / ON CONFLICT](https://www.postgresql.org/docs/18/sql-insert.html), [CTEs](https://www.postgresql.org/docs/18/queries-with.html) e [funções de janela](https://www.postgresql.org/docs/18/tutorial-window.html).
- [Junções e LATERAL](https://www.postgresql.org/docs/18/queries-table-expressions.html), [padrões de texto](https://www.postgresql.org/docs/18/functions-matching.html) e [tipos de data/hora](https://www.postgresql.org/docs/18/datatype-datetime.html).
- [EXPLAIN](https://www.postgresql.org/docs/18/using-explain.html), [índices parciais](https://www.postgresql.org/docs/18/indexes-partial.html) e [índices de expressão](https://www.postgresql.org/docs/18/indexes-expressional.html).
- [Estatísticas e dependências](https://www.postgresql.org/docs/18/planner-stats.html), [pg_stats](https://www.postgresql.org/docs/18/view-pg-stats.html), [CLUSTER](https://www.postgresql.org/docs/18/sql-cluster.html) e [VACUUM](https://www.postgresql.org/docs/18/sql-vacuum.html).

Veja **VALIDACAO.md** para os checks efetivamente realizados na edição distribuída. Planos, desempenho e integração com sua VM devem ser medidos no PostgreSQL do seu ambiente; o material não fornece tempos ou scans garantidos.
