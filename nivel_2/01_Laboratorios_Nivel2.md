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

Você entrou na equipe de dados da **Loja Horizonte**, uma loja fictícia de equipamentos. A empresa vende produtos, recebe pagamentos parcelados e mantém o mesmo produto em dois depósitos. Cadastro, financeiro e operação pedem sua ajuda para corrigir relatórios e investigar comportamentos do sistema. Cada laboratório representa uma dessas frentes de trabalho.

Você trabalha sobre uma cópia de treinamento. Quando um exercício pede uma alteração seguida de ROLLBACK, a ideia é observar o efeito e desfazê-lo para manter os próximos exercícios reproduzíveis. Não é preciso memorizar os comandos novos: use as explicações e as dicas de cada tarefa antes de consultar a solução completa.

| Tabela | O que uma linha representa | Onde será usada |
|---|---|---|
| clientes | Uma pessoa cadastrada, com UF, email e indicação de atividade | Cadastro e relatórios por cliente |
| produtos | Um produto e seu preço atual de catálogo | Faixas de preço e comparação com vendas antigas |
| pedidos | O cabeçalho de uma venda: cliente, data, status, valor bruto e desconto | Receita contratada e dívida |
| itens | Um produto dentro de um pedido, com quantidade e preço da época | Conferência do valor vendido |
| pagamentos | Um recebimento ou estorno de um pedido; pode haver vários | Caixa e saldo a receber |
| estoques | O saldo de um produto em um depósito; produto 1 começa com A=10 e B=5 | Transações e proteção de saldo |
| importacao_contatos | Uma linha recebida de um arquivo externo, ainda sem tratamento | Limpeza e deduplicação |
| contatos_tratados | O cadastro resultante da importação; começa vazio | UPSERT |
| acessos | Um instante de acesso registrado com fuso horário | Fronteiras de mês |
| eventos | Um evento sintético para medições; criada somente antes de N2-5 | Índices, estatísticas e planos |

As ligações principais são: pedidos.cliente_id → clientes.id; itens.pedido_id → pedidos.id; itens.produto_id → produtos.id; pagamentos.pedido_id → pedidos.id. Assim, um pedido pode aparecer em várias linhas de itens e também em várias linhas de pagamentos. Essa diferença de quantidade é importante para os relatórios.

Antes de começar, faça uma visita aos dados no DBeaver. Execute cada SELECT e observe os nomes das colunas e os exemplos. Esses comandos são somente leitura:

```sql
SET search_path TO bdadosql_n2, public;
SELECT * FROM clientes ORDER BY id;
SELECT * FROM pedidos WHERE id IN (101,104,112) ORDER BY id;
SELECT * FROM itens WHERE pedido_id = 101 ORDER BY produto_id;
SELECT * FROM pagamentos WHERE pedido_id IN (101,104,112) ORDER BY id;
SELECT * FROM estoques ORDER BY produto_id,deposito;
SELECT * FROM importacao_contatos ORDER BY lote_id;
```

O pedido 101 é um bom exemplo para acompanhar: seus itens somam 250, o desconto é 10 e os dois recebimentos somam 240. Portanto, a venda vale 250 brutos, o cliente contratou 240 líquidos e não deve nada. Use esse exemplo para separar os conceitos nas regras abaixo.

- valor_total é o valor bruto do pedido. A soma quantidade × preco_unitario dos itens deve reconciliar com ele. O preço do item é o preço histórico da venda.
- Para os relatórios financeiros desta trilha, **líquido contratado = valor_total − COALESCE(desconto, 0)**. NULL continua significando desconto desconhecido no cadastro; a conversão para zero é uma regra explícita deste relatório.
- Exclua pedidos cancelados dos relatórios financeiros e rankings, salvo instrução contrária. O status não substitui o cálculo do saldo.
- Em pagamentos, valor é sempre positivo. Recebimento soma; estorno subtrai. **Saldo = líquido contratado − recebido líquido**. Saldo positivo é a receber; negativo é crédito do cliente. Não esconda crédito transformando todos os saldos negativos em zero no total global.
- O pedido 112 recebeu 120 para um líquido de 100: tem crédito de 20. O pedido 104 recebeu 500 e teve estorno de 20: recebeu líquido 480.
- Ordene resultados com desempate estável. Ausência de ORDER BY não garante ordem. Valores esperados pressupõem a carga inicial e a execução dos testes de escrita com ROLLBACK.

## Como trabalhar cada exercício

Leia primeiro a **situação** para entender quem precisa da informação e por quê. Em seguida, veja o **objetivo**, confira os **dados de partida** e faça o **passo a passo**. A **dica** apresenta o recurso novo sem entregar a consulta inteira. Use a **conferência** apenas depois de tentar e registre onde seu resultado divergiu.

No HTML, o passo a passo, a dica e a conferência do resultado começam recolhidos em cada exercício. Clique em **Ver passo a passo**, **Ver dica para começar** ou **Ver como conferir seu resultado** para abrir somente a ajuda desejada; clique novamente para recolher. Você pode tentar resolver pelo contexto e pelo objetivo antes de consultar essas seções.

Nos passos numerados, execute cada etapa antes de seguir para a seguinte. No DBeaver, selecione somente o comando da etapa atual. Quando houver BEGIN, continue no mesmo editor; quando o enunciado mandar provocar um erro, execute essa instrução sozinha e depois a recuperação. Assim você consegue observar os estados intermediários.

Sua entrega pode ser curta: SQL utilizado, resultado ou captura e duas ou três frases explicando o que aconteceu. Em desempenho, acrescente os planos e as medições. As soluções no fim do HTML são para correção; não é necessário lê-las antes de começar.

No HTML, você também pode abrir **Ver uma solução possível** diretamente no exercício. A seção começa recolhida e apresenta o SQL comentado daquela tarefa. Ela exemplifica uma resposta válida; outras soluções são possíveis se respeitarem as regras e produzirem o resultado esperado. O conjunto das soluções permanece disponível no fim da página.

## Guia rápido das ferramentas novas

| Recurso | Para que serve aqui | Como pensar nele |
|---|---|---|
| BEGIN / COMMIT / ROLLBACK | Controlar alterações que precisam funcionar juntas | Iniciar, confirmar ou desfazer o conjunto |
| RETURNING | Ver as linhas que uma escrita realmente alterou | O resultado da alteração, antes de encerrar a transação |
| SAVEPOINT | Recuperar uma etapa sem desfazer a transação inteira | Um marco intermediário, sem confirmação permanente |
| WITH ... AS (...) | Separar uma consulta longa em etapas nomeadas, chamadas CTEs | Primeiro tratar os dados, depois usar esse resultado |
| ROW_NUMBER() OVER (...) | Numerar linhas de cada grupo em uma ordem escolhida | Escolher a versão mais recente ou a posição no ranking |
| ON CONFLICT ... DO UPDATE | Atualizar uma chave existente durante a importação | Inserir quem é novo, atualizar quem já está no destino |
| FILTER (WHERE ...) | Usar condições diferentes em contagens ou somas da mesma consulta | Uma medida para cada pergunta, na mesma linha de resumo |
| LEFT JOIN | Preservar a população da esquerda, mesmo sem correspondência | Todos os clientes, inclusive quem não comprou |
| FULL JOIN | Preservar registros de qualquer uma das fontes | Encontrar também o que está faltando de cada lado |
| NOT EXISTS | Testar ausência de uma linha correspondente | Não existe pedido elegível para esta pessoa? |
| SUM(...) OVER / LAG(...) OVER | Calcular acumulado e consultar a linha anterior | Acrescentar medidas sem colapsar o relatório em uma linha |

Por exemplo, antes de escrever uma consulta grande de importação, experimente uma CTE pequena. Você pode executar o trecho abaixo sem modificar tabelas:

```sql
WITH nomes_limpos AS (
    SELECT btrim(nome) AS nome
    FROM (VALUES ('  Joana  '), ('Rui ')) AS exemplo(nome)
)
SELECT nome, upper(nome) AS nome_maiusculo
FROM nomes_limpos
ORDER BY nome;
```

A parte dentro de WITH produz Joana e Rui sem os espaços. O SELECT seguinte usa esse resultado pelo nome nomes_limpos. Nos exercícios, você aplicará a mesma ideia com etapas como normalizados, validos e recebidos. Não precisa escrever todas as etapas de uma vez: execute a primeira, confira a saída e só então acrescente a próxima.

## N2-1 — Integridade, transações e importação

**Seu papel neste laboratório:** ajudar a operação e o cadastro a aceitar dados corretos sem deixar alterações pela metade. Primeiro você observa as proteções do banco, depois controla uma transferência e, por fim, trata um arquivo externo. As alterações de estoque são ensaios desfeitos com ROLLBACK; a importação em contatos_tratados é a entrega que permanece.

Pré-requisitos novos: PRIMARY KEY, CHECK, BEGIN/COMMIT/ROLLBACK, SAVEPOINT, CTE, ROW_NUMBER e INSERT ON CONFLICT. Um SAVEPOINT marca um ponto dentro da transação; ROLLBACK TO recupera somente até esse ponto. Uma CTE (`WITH nome AS (...)`) organiza etapas de uma consulta. ROW_NUMBER numera linhas por grupo e ordem escolhidos.

### N2-1.1 — Provar as restrições

**Situação:** o sistema da Loja Horizonte recebeu três tipos de informação errada: estoque negativo, um saldo duplicado para o mesmo depósito e um pagamento que aponta para uma venda inexistente. Antes de liberar uma importação, a equipe quer saber se o próprio banco impede esses erros.

**Seu objetivo:** demonstrar que cada regra está protegida por uma restrição e reconhecer a mensagem que ela produz.

**Dados de partida:** use estoques e pagamentos como vieram da preparação. O produto 1 já existe nos depósitos A e B; o pedido 999 não existe.

**Passo a passo:**

1. No navegador de objetos do DBeaver, abra as restrições dessas tabelas. Localize CHECK, chave primária e chave estrangeira. Alternativamente, consulte pg_constraint.
2. Abra BEGIN e tente definir o estoque de A como -1. Leia a mensagem e anote o SQLSTATE, que é o código do tipo de erro. Execute ROLLBACK.
3. Em outra transação, tente inserir novamente o par produto 1/depósito A. Anote o erro e execute ROLLBACK.
4. Faça o mesmo com um novo pagamento associado ao pedido 999, usando um id de pagamento ainda livre, como 99.
5. Consulte os saldos e conte pagamentos para provar que as tentativas não modificaram a carga.

**Dica para começar:** uma chave primária composta protege a combinação das colunas. Não é proibido ter o mesmo produto em depósitos diferentes. Depois de um erro, encerre a transação com ROLLBACK antes de testar a próxima situação.

**Como conferir seu resultado:** erros esperados 23514 (CHECK), 23505 (unicidade) e 23503 (FK); estoques continuam A=10, B=5 e pagamentos continuam com 12 linhas.

### N2-1.2 — Transferência atômica de estoque

**Situação:** a operação precisa levar três unidades do Mouse do depósito A para o B. Não houve compra nem venda: apenas mudança de lugar. Se o sistema baixar A e falhar antes de aumentar B, o estoque total ficará incorreto.

**Seu objetivo:** tratar a transferência como uma única operação e conferir sua consistência antes de confirmá-la.

**Dados de partida:** produto 1, A=10, B=5, total=15. O exercício anterior deve ter terminado com ROLLBACK.

**Passo a passo:**

1. Consulte os dois saldos e abra BEGIN na mesma sessão.
2. Subtraia três de A somente se saldo >= 3. Acrescente RETURNING para ver a linha alterada.
3. Confira que exatamente uma linha foi debitada. Só nesse caso, acrescente três a B. Se a primeira etapa afetar zero linhas, desfaça a transação e investigue.
4. Consulte A, B e a soma dos saldos. Pergunte: o total mudou ou apenas sua distribuição?
5. Neste treinamento, termine com ROLLBACK e consulte novamente. Explique em que ponto um sistema real poderia usar COMMIT.

**Dica para começar:** pense em BEGIN como o início de um conjunto de alterações que precisam dar certo juntas. RETURNING mostra o resultado do UPDATE; ele não confirma a transação. Uma aplicação real deve verificar o sucesso dos dois lados antes do COMMIT.

**Como conferir seu resultado:** dentro da transação, A=7, B=8 e total=15; após ROLLBACK, A=10 e B=5.

### N2-1.3 — Recuperar uma falha sem perder tudo

**Situação:** a transferência começou corretamente, mas um comando errado tentou deixar o depósito B com saldo negativo. A equipe quer recuperar essa etapa sem perder a baixa correta que já tinha feito em A.

**Seu objetivo:** observar a diferença entre desfazer toda a transação e voltar apenas a um ponto intermediário.

**Dados de partida:** estoque restaurado para A=10 e B=5. Faça tudo no mesmo editor do DBeaver, comando por comando.

**Passo a passo:**

1. Abra BEGIN e retire duas unidades de A. Agora A deve ter 8.
2. Crie um SAVEPOINT chamado antes_da_falha. Ele marca o estado que você pretende preservar.
3. Execute sozinha uma tentativa de definir B=-1. O erro é esperado; guarde a mensagem.
4. Execute ROLLBACK TO SAVEPOINT antes_da_falha. Consulte os saldos e veja se a retirada de A continua presente.
5. Corrija a operação: adicione duas unidades a B e confira que o total voltou a 15.
6. Termine com ROLLBACK completo para restaurar a carga inicial.

**Dica para começar:** SAVEPOINT não é um salvamento permanente. O ROLLBACK final ainda desfaz inclusive o que ocorreu antes dele. Após o erro, recupere a transação antes de tentar outras consultas.

**Como conferir seu resultado:** após recuperar a falha, A=8 e B=5; após crédito, A=8 e B=7; ao final A=10 e B=5. Explique a diferença entre ROLLBACK e ROLLBACK TO.

### N2-1.4 — Diagnosticar o lote bruto

**Situação:** o cadastro recebeu um arquivo de contatos de outra equipe. Há espaços extras, letras em formatos diferentes, emails inválidos e duas versões da mesma pessoa. Importar tudo diretamente esconderia problemas de qualidade.

**Seu objetivo:** produzir um diagnóstico do lote antes de decidir o que pode entrar no cadastro definitivo.

**Dados de partida:** importacao_contatos contém sete linhas. lote_id identifica a entrada do arquivo; cliente_id identifica a pessoa. Não altere essa tabela: ela é sua evidência do que foi recebido.

**Prática complementar:** o [laboratório extra de expressões regulares POSIX](extra_regex_posix/Laboratorio_Regex_POSIX.html) apresenta 12 exercícios graduais para entender e testar o filtro de email, limpar textos, extrair grupos e escrever um diagnóstico. Tem carga própria e ajudas recolhidas; no GitHub, consulte o [roteiro do extra](extra_regex_posix/01_Laboratorio_Regex.md).

**Passo a passo:**

1. Faça um SELECT do lote original. Em outro SELECT, mostre nome sem espaços nas pontas, email em minúsculas sem espaços e UF em maiúsculas.
2. Transforme email vazio após o tratamento em NULL. Considere válido um nome não vazio, UF em PR/SP/PE/RS/RJ/SC e email ausente ou compatível com `^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$`.
3. Acrescente uma coluna de diagnóstico com CASE: valido, nome ausente, UF invalida ou email invalido.
4. Conte válidos e rejeitados. Entre os válidos, agrupe por cliente_id para procurar mais de uma entrada da mesma pessoa.

**Dica para começar:** monte a consulta em etapas: normalização, classificação e contagem. btrim remove espaços das pontas; NULLIF(texto,'') converte texto vazio em NULL. A regex fornecida é somente um filtro didático; não valida todas as regras de um endereço de email.

**Como conferir seu resultado:** sete linhas brutas, cinco válidas, duas inválidas (lotes 6 e 7); cliente 3 tem dois registros válidos. Não elimine duplicatas antes de contar e explicar a qualidade do lote.

### N2-1.5 — Importar com desempate e repetição segura

**Situação:** depois do diagnóstico, o cadastro autorizou importar apenas as linhas válidas. Para quem aparece duas vezes, vale a entrada de maior lote_id, que representa a versão mais recente. O arquivo pode ser reenviado amanhã e não deve duplicar pessoas.

**Seu objetivo:** carregar contatos_tratados com uma linha por pessoa e obter o mesmo conteúdo quando repetir o processamento.

**Dados de partida:** reaproveite os critérios de N2-1.4. contatos_tratados começa vazia e sua chave é cliente_id. Não use a tabela clientes como destino desta importação.

**Passo a passo:**

1. Recupere somente as linhas normalizadas e válidas.
2. Dentro de cada cliente_id, numere as entradas por lote_id decrescente. Separe apenas a primeira de cada grupo.
3. Insira os vencedores em contatos_tratados. Se a pessoa já existir, atualize nome, email e UF com os dados recebidos.
4. Consulte o destino por cliente_id e salve o resultado.
5. Execute novamente a mesma importação. Compare o conteúdo, não apenas a quantidade de linhas que o DBeaver informa como afetadas.

**Dica para começar:** use ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY lote_id DESC) para escolher a versão. ON CONFLICT (cliente_id) DO UPDATE resolve a chave já existente; EXCLUDED representa a linha que você tentou inserir. Elimine as duplicatas da entrada antes do UPSERT.

**Como conferir seu resultado:** quatro contatos, ids 1, 2, 3 e 9; cliente 3 se chama Carla Nova; cliente 2 tem email NULL; nomes e emails tratados. A segunda execução mantém o mesmo conteúdo, mesmo que o comando reporte atualizações.

### N2-1.6 — Reserva condicional sem saldo negativo

**Situação:** chegaram duas solicitações de oito unidades para um depósito que tem apenas dez. A segunda solicitação não pode ser aceita depois que a primeira consumir o estoque disponível.

**Seu objetivo:** colocar a condição de disponibilidade dentro da própria alteração e interpretar uma tentativa que afeta zero linhas.

**Dados de partida:** produto 1 no depósito A com saldo 10. As duas tentativas serão sequenciais na mesma sessão, para facilitar a observação.

**Passo a passo:**

1. Abra BEGIN e execute um UPDATE que subtraia oito somente quando saldo >= 8. Use RETURNING para mostrar o saldo restante.
2. Ainda sem encerrar a transação, execute exatamente o mesmo comando novamente.
3. Compare as saídas: uma lista vazia significa que o filtro não encontrou saldo suficiente, não que ocorreu erro SQL.
4. Execute ROLLBACK e confirme que A voltou a 10.
5. Explique o risco de fazer primeiro SELECT do saldo e, depois, um UPDATE sem a condição de disponibilidade.

**Dica para começar:** a condição deve estar no WHERE do UPDATE. Este teste ensina a regra de alteração condicional; como há somente uma sessão, ele não demonstra todos os efeitos de concorrência de uma aplicação real.

**Como conferir seu resultado:** primeira tentativa retorna saldo 2; a segunda afeta zero linhas; depois do ROLLBACK, saldo 10.

## N2-2 — Filtros, NULL, texto e limites de datas

**Seu papel neste laboratório:** traduzir solicitações de negócio para filtros exatos. Uma regra mal interpretada pode selecionar a pessoa errada, misturar informação ausente com zero ou colocar um acesso no mês errado. Você vai trabalhar somente com consultas e justificar os casos de borda, além do resultado principal.

Pré-requisitos novos: NULLIF, btrim, IS DISTINCT FROM, timestamptz, AT TIME ZONE e intervalos com limite superior exclusivo. Todas as tarefas são de leitura. Não transforme valores ausentes no cadastro para facilitar a consulta.

### N2-2.1 — Ausência de email com regra composta

**Situação:** a equipe comercial vai enviar uma campanha apenas para clientes ativos do Paraná e de São Paulo. Antes, precisa identificar quem não tem email utilizável. Alguns cadastros têm NULL; outros têm somente espaços, que visualmente parecem um campo vazio.

**Seu objetivo:** montar a lista de pessoas que precisam atualizar o contato, obedecendo às três condições ao mesmo tempo.

**Dados de partida:** use clientes. Preserve o email original para mostrar o problema, sem corrigir o cadastro com UPDATE.

**Passo a passo:**

1. Consulte id, nome, ativo, UF e email de todos os clientes.
2. Escreva uma condição para ativo e outra para UF em PR ou SP. Use parênteses para deixar a combinação clara.
3. Trate o email apenas na expressão do filtro: remova espaços das pontas e converta texto vazio em NULL.
4. Mostre id, nome, UF e email original de quem atende às três condições.
5. Compare com a versão que testa somente email IS NULL e explique quem ficaria de fora incorretamente.

**Dica para começar:** NULLIF(btrim(email),'') permite reconhecer tanto ausência quanto texto preenchido só com espaços. Um email com espaços nas pontas e conteúdo no meio não está ausente.

**Como conferir seu resultado:** apenas Diego, id 4. Ana não entra: seu email tem espaços, mas não é vazio.

### N2-2.2 — Desconhecido, zero e positivo

**Situação:** o financeiro recebeu a pergunta: quantos pedidos tiveram desconto? O cadastro, porém, distingue desconto confirmado como zero, desconto positivo e desconto ainda desconhecido. Misturar desconhecido com zero esconderia pendências de preenchimento.

**Seu objetivo:** construir um resumo de qualidade do cadastro de descontos sem perder essa distinção.

**Dados de partida:** considere os 12 pedidos, inclusive cancelados. Aqui você analisa preenchimento, não receita.

**Passo a passo:**

1. Consulte id e desconto para reconhecer os três casos nos dados.
2. Em uma única consulta, conte separadamente desconto IS NULL, desconto = 0 e desconto > 0.
3. Confira se a soma das três contagens corresponde ao total de pedidos.
4. Acrescente SUM(desconto) e SUM(COALESCE(desconto,0)). Compare os números e explique por que uma soma igual não prova que NULL e zero significam a mesma coisa.

**Dica para começar:** COUNT(*) FILTER (WHERE condição) conta somente as linhas daquela condição sem exigir três consultas. SUM ignora NULL; COALESCE fornece um valor substituto para a expressão, sem alterar o cadastro.

**Como conferir seu resultado:** desconhecidos=3, zero=6, positivos=3; soma de descontos=40. Os três grupos cobrem os 12 pedidos.

### N2-2.3 — Março no horário de São Paulo

**Situação:** o sistema grava instantes de acesso, mas o relatório mensal da loja segue o horário de São Paulo. Um acesso registrado às 02:59:59 UTC de 1º de março ainda pertence a fevereiro em São Paulo. Cortar o mês pelo calendário UTC gera um relatório errado.

**Seu objetivo:** encontrar os acessos de março segundo o fuso do negócio e manter a resposta ao mudar o fuso de apresentação da sessão.

**Dados de partida:** use acessos.ocorrido_em, que é timestamptz. As quatro linhas foram colocadas perto das fronteiras de março justamente para revelar erros de limite.

**Passo a passo:**

1. Liste os instantes originais e uma coluna de apresentação com ocorrido_em AT TIME ZONE 'America/Sao_Paulo'.
2. Transforme 01/03/2026 00:00 e 01/04/2026 00:00 de São Paulo em limites timestamptz explícitos.
3. Filtre a coluna original com >= início e < início do mês seguinte. Não inclua o primeiro instante de abril.
4. Em uma transação, use SET LOCAL TIME ZONE 'UTC', execute a consulta, depois mude para America/Sao_Paulo e repita.
5. Termine com ROLLBACK para restaurar a configuração e explique por que os ids devem ser iguais nas duas execuções.

**Dica para começar:** TIMESTAMP '2026-03-01 00:00:00' AT TIME ZONE 'America/Sao_Paulo' interpreta aquele horário de parede no fuso indicado. Já aplicar AT TIME ZONE a ocorrido_em serve para apresentá-lo como horário local. BETWEEN inclui os dois extremos; aqui o extremo final deve ficar de fora.

**Como conferir seu resultado:** ids 2 e 3 nas duas execuções. O id 1 ainda é fevereiro local; o 4 já é abril local. Explique o risco de usar BETWEEN com o primeiro instante do mês seguinte e de converter a coluna para date para filtrar sem considerar o fuso.

### N2-2.4 — Faixas de preço sem buracos

**Situação:** o catálogo precisa exibir uma faixa de preço ao lado de cada produto. O comercial definiu baixo abaixo de 100, medio de 100 a 500 inclusive e alto acima de 500. Se os limites forem escritos de maneira inconsistente, um produto pode ficar sem faixa ou ser classificado na faixa errada.

**Seu objetivo:** escrever uma classificação única e provar seu comportamento nas fronteiras.

**Dados de partida:** use os seis produtos. O catálogo contém preço 500, mas não contém 100; por isso, você vai criar valores de teste somente na consulta.

**Passo a passo:**

1. Faça uma listagem com id, nome, preco e uma coluna faixa calculada com CASE.
2. Use essa classificação em uma CTE para contar produtos por faixa.
3. Crie duas linhas temporárias de consulta com VALUES (100),(500) e aplique o mesmo CASE.
4. Explique por que a ordem dos WHEN importa e como você garantiu que todo preço permitido receba uma classificação.

**Dica para começar:** CASE avalia os WHEN na ordem e para no primeiro verdadeiro. Depois de separar preco < 100, um segundo teste preco <= 500 já cobre a faixa intermediária. VALUES cria linhas na consulta; não insere produtos na tabela.

**Como conferir seu resultado:** baixo=2, medio=3, alto=1; 100 e 500 são medio.

### N2-2.5 — NULL na comparação

**Situação:** duas pessoas entregaram listas diferentes de pedidos com desconto diferente de zero. Uma usou <> 0; outra, IS DISTINCT FROM 0. O gestor quer entender se alguém errou ou se os filtros respondem perguntas diferentes.

**Seu objetivo:** mostrar a diferença com os ids dos pedidos e explicar o tratamento da ausência de informação.

**Dados de partida:** consulte pedidos, sem alterar os descontos. A carga aceita desconto NULL e não aceita desconto negativo.

**Passo a passo:**

1. Liste os ids e descontos encontrados por desconto <> 0.
2. Repita com desconto IS DISTINCT FROM 0.
3. Use EXCEPT para obter os ids da segunda consulta que não aparecem na primeira. Confira o desconto original desses pedidos.
4. Escreva duas frases: qual filtro responde desconto positivo nesta carga e qual responde qualquer diferença em relação a zero, incluindo ausência.

**Dica para começar:** uma comparação comum com NULL produz resultado desconhecido e não passa no WHERE. IS DISTINCT FROM permite comparar ausência como um caso distinto. EXCEPT devolve o que está no primeiro resultado e não no segundo.

**Como conferir seu resultado:** <> retorna 101,104,107; IS DISTINCT FROM acrescenta 102,105,108. Não trate a segunda lista como prova de que o desconto é positivo.

### N2-2.6 — Caracteres literais em padrões

**Situação:** um atendente procura um cabo cujo nome contém os símbolos _ e %. Ele digitou um padrão LIKE e recebeu todos os produtos, porque esses caracteres também têm significado especial na busca.

**Seu objetivo:** distinguir procurar um símbolo literal de usar um símbolo como regra de correspondência.

**Dados de partida:** o produto 6 se chama Cabo_100%. Você vai pesquisar nomes em produtos, sem alterar nenhum deles.

**Passo a passo:**

1. Liste os nomes e teste LIKE '%_%'. Observe a quantidade de resultados.
2. Escolha ! como caractere de escape com ESCAPE '!'. Escreva uma busca por % literal em qualquer posição.
3. Escreva outra busca por _ literal, também em qualquer posição.
4. Compare as três listas e explique por que a primeira é mais abrangente.

**Dica para começar:** no LIKE, % significa qualquer sequência de caracteres e _ significa um caractere. Com ESCAPE '!', um ! antes desses símbolos manda tratá-los literalmente. Você ainda pode usar os outros % do padrão como curingas nas pontas.

**Como conferir seu resultado:** as buscas literais retornam somente Cabo_100%, id 6; o padrão sem escape retorna os seis produtos.

## N2-3 — Relatórios financeiros e funções de janela

**Seu papel neste laboratório:** montar relatórios que o financeiro consiga explicar. Você começa pelo valor das vendas, compara com o dinheiro recebido e termina com a lista de cobrança. Cada exercício reaproveita uma ideia do anterior. Guarde a consulta mensal de N2-3.1 e a posição por pedido de N2-3.2: serão pontos de partida para as próximas tarefas.

Pré-requisitos novos: FILTER, CTE, generate_series, date_trunc, ROW_NUMBER, LAG e SUM OVER. Uma janela mantém as linhas do resultado e calcula sobre seu grupo; GROUP BY resume linhas. Use ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW para explicitar o acumulado. Todas as tarefas usam a carga original, sem escrita.

### N2-3.1 — Receita contratada com meses vazios

**Situação:** a direção quer um gráfico de receita contratada de janeiro a junho. Se maio e junho desaparecerem porque não tiveram pedidos, o gráfico parecerá incompleto. Além disso, venda cancelada não deve aumentar o resultado.

**Seu objetivo:** entregar seis linhas mensais, incluindo meses sem movimento, com a mesma regra financeira em todos os meses.

**Dados de partida:** use pedidos e a data do pedido. Receita contratada é valor_total menos desconto, tratando desconto desconhecido como zero para este relatório. Ainda não use pagamentos: dinheiro recebido será analisado depois.

**Passo a passo:**

1. Filtre os pedidos não cancelados e calcule o líquido de cada um.
2. Agrupe os valores pelo primeiro dia do mês de data_pedido.
3. Em outra CTE, gere todos os meses de janeiro a junho, mesmo os que não aparecem nas vendas.
4. Parta desse calendário e ligue os totais com LEFT JOIN. Mostre zero quando não existir total para o mês.
5. Ordene por mês e confira a soma do período.

**Dica para começar:** date_trunc('month', data_pedido) reúne datas do mesmo mês. generate_series com intervalo de um mês fornece o calendário. Chama-se competência, neste exercício, atribuir a venda ao mês do pedido, independentemente do recebimento.

**Como conferir seu resultado:** janeiro=1290; fevereiro=980; março=540; abril=250; maio=0; junho=0. Total=3060.

### N2-3.2 — Posição financeira por pedido

**Situação:** o financeiro precisa saber quais pedidos estão quitados e quais ainda têm saldo. O status cadastrado não basta: há recebimentos parciais, estorno e até cliente que pagou a mais.

**Seu objetivo:** calcular a posição financeira de cada venda sem contar um pedido várias vezes por ele ter vários pagamentos.

**Dados de partida:** use pedidos e pagamentos; deixe itens fora desta consulta. Observe primeiro os pedidos 101, 104 e 112 para ver, respectivamente, dois recebimentos, um estorno e um crédito.

**Passo a passo:**

1. Em pagamentos, transforme recebimento em valor positivo e estorno em valor negativo. Some por pedido_id, produzindo uma linha por pedido.
2. Ligue esse resumo aos pedidos não cancelados com LEFT JOIN. Sem pagamento, o recebido deve ser zero.
3. Calcule contratado líquido, recebido líquido e saldo = contratado - recebido.
4. Classifique saldo positivo como a_receber, zero como quitado e negativo como credito.
5. Confira os totais de contratado, recebido, saldo assinado, dívidas positivas e créditos separados.

**Dica para começar:** imagine a tabela intermediária com apenas pedido_id e recebido. Essa etapa evita que os vários pagamentos multipliquem o valor do cabeçalho. Um saldo de -20 representa crédito de 20, não uma dívida negativa a esconder.

**Como conferir seu resultado:** dez pedidos; contratado=3060, recebido=2730, saldo assinado=330. A receber positivo=350 e crédito=20. Pedido 112 tem saldo -20; 104 tem recebido 480 e saldo zero.

### N2-3.3 — Dois maiores clientes de cada mês

**Situação:** a área comercial quer destacar os dois clientes que mais contrataram em cada mês. Ordenar todas as vendas do semestre e aplicar LIMIT 2 escolheria somente dois clientes do período inteiro.

**Seu objetivo:** construir um ranking independente dentro de cada mês e aplicar um desempate reproduzível.

**Dados de partida:** use o líquido contratado dos pedidos não cancelados. Não some pagamentos: o ranking mede vendas, e não recebimentos.

**Passo a passo:**

1. Produza uma linha por mês e cliente com a soma do líquido contratado.
2. Sobre esse resumo, numere as linhas dentro de cada mês, do maior total para o menor. Em empate, use cliente_id crescente.
3. Em uma consulta externa, mantenha somente as posições 1 e 2.
4. Mostre mês, cliente_id, total e posição; confira especialmente março, quando há três clientes com vendas.
5. Explique como você mudaria a regra para incluir todos os clientes empatados entre os dois maiores valores, usando DENSE_RANK somente pelo total.

**Dica para começar:** PARTITION BY mes reinicia a numeração a cada mês. Faça a soma antes da janela: primeiro você constrói a pontuação de cada cliente, depois atribui sua posição.

**Como conferir seu resultado:** janeiro: (1,1140),(2,150); fevereiro: (4,500),(3,480); março: (6,300),(5,190); abril: (5,150),(3,100). O cliente 1 fica fora do top 2 de março.

### N2-3.4 — Acumulado e variação mensal

**Situação:** depois de receber os totais mensais, a direção perguntou quanto a loja acumulou até cada mês e quanto cresceu em relação ao mês anterior. Maio e junho sem vendas também precisam aparecer, pois fazem parte da análise.

**Seu objetivo:** acrescentar medidas de evolução ao relatório de N2-3.1 sem perder suas seis linhas.

**Dados de partida:** reaproveite a receita mensal de janeiro a junho já conferida. O primeiro mês não tem referência anterior; junho tem mês anterior com receita zero.

**Passo a passo:**

1. Deixe pronta uma CTE com mes e liquido, incluindo os zeros de maio e junho.
2. Acrescente o acumulado com SUM OVER em ordem de mês, usando a moldura ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW.
3. Use LAG para trazer o líquido da linha anterior.
4. Calcule 100 × (atual - anterior) / anterior. Se o anterior for zero ou não existir, retorne NULL.
5. Arredonde a porcentagem para duas casas apenas no resultado final. Explique o que NULL significa no primeiro mês e em junho.

**Dica para começar:** SUM OVER calcula sem agrupar novamente as linhas. LAG consulta a linha anterior na ordem definida. NULLIF(anterior,0) é uma forma de evitar divisão por zero; não invente uma taxa de crescimento para esse caso.

**Como conferir seu resultado:** acumulados=1290,2270,2810,3060,3060,3060; maio varia -100%; junho tem variação NULL. Use round(...,2) apenas na apresentação.

### N2-3.5 — Recebimentos e estornos separados

**Situação:** a direção comparou receita contratada com o extrato de recebimentos e encontrou números diferentes. O caixa registra quando o pagamento aconteceu e precisa separar dinheiro que entrou de valores devolvidos.

**Seu objetivo:** produzir uma visão mensal de caixa e explicar sua diferença para o relatório de vendas.

**Dados de partida:** use pagamentos ligados a pedidos não cancelados. Agora o mês é o de data_pagamento, não o de data_pedido. Estornos foram armazenados como valores positivos com tipo próprio.

**Passo a passo:**

1. Por mês de pagamento, some separadamente recebimentos e estornos, usando FILTER ou CASE.
2. Calcule recebido líquido = recebimentos - estornos.
3. Calcule percentual estornado = 100 × estornos / recebimentos, protegendo o denominador zero.
4. Ligue o resumo a um calendário de janeiro a junho para preservar os meses vazios.
5. Compare os totais com N2-3.1. Use fevereiro para explicar a devolução e cite pagamentos parciais e crédito como motivos de diferença nesta carga.

**Dica para começar:** o pagamento de 500 e o estorno de 20 do pedido 104 não são duas entradas de caixa. Um é entrada e o outro é devolução. Em meses sem recebimento, mostre líquido zero e percentual NULL.

**Como conferir seu resultado:** líquidos por mês=1190,780,490,270,0,0; fevereiro tem bruto 800, estorno 20 e percentual 2,50%; total líquido=2730. Nesta carga, datas de recebimento permanecem no mês do pedido, mas há pagamentos parciais e créditos.

### N2-3.6 — Cobrança sem compensação indevida

**Situação:** a equipe de cobrança quer saber quem precisa ser contatado. O crédito de uma venda não deve apagar automaticamente a dívida de outra no relatório operacional; uma compensação dependeria de uma regra específica da empresa.

**Seu objetivo:** separar o que cada cliente deve do que tem de crédito, classificando primeiro os saldos de cada pedido.

**Dados de partida:** reaproveite a posição por pedido de N2-3.2, mantendo cliente_id. Use apenas vendas não canceladas.

**Passo a passo:**

1. Para cada pedido, calcule a_receber como o saldo positivo, ou zero se ele não for positivo.
2. Calcule credito como o módulo do saldo negativo, ou zero nos demais casos.
3. Some as duas medidas por cliente_id, sem compensá-las antes.
4. Mostre somente clientes cuja soma a_receber seja maior que zero.
5. Remova temporariamente esse último filtro para encontrar o crédito do cliente 3. Explique por que um saldo global assinado responde outra pergunta.

**Dica para começar:** GREATEST(saldo,0) mantém a dívida positiva; GREATEST(-saldo,0) transforma somente crédito em valor positivo. HAVING filtra o total do cliente depois do agrupamento.

**Como conferir seu resultado:** clientes 1=50, 2=100 e 4=200 a receber. Em uma consulta complementar sem HAVING, cliente 3 tem crédito=20. Explique por que SUM(saldo) e SUM(GREATEST(saldo,0)) respondem perguntas diferentes.

## N2-4 — Cardinalidade, ausência e reconciliação

**Seu papel neste laboratório:** investigar relatórios que parecem plausíveis, mas omitem pessoas ou multiplicam valores. Antes de corrigir o SQL, observe quantas linhas cada ligação produz. Aqui, cardinalidade significa a quantidade de correspondências: um cliente tem vários pedidos e um pedido tem vários itens e pagamentos.

Pré-requisitos novos: LEFT JOIN, FULL JOIN, NOT EXISTS e LEFT JOIN LATERAL. Uma junção lateral pode consultar dados da linha à esquerda; LIMIT 1 exige ORDER BY determinístico. Todas as tarefas de escrita terminam com ROLLBACK.

### N2-4.1 — Clientes sem movimento no relatório

**Situação:** a equipe de relacionamento quer um relatório da carteira inteira. A consulta atual mostra apenas quem comprou, fazendo clientes sem movimento desaparecerem. Para planejar uma campanha, essas pessoas também precisam constar.

**Seu objetivo:** produzir uma linha por cliente, mesmo quando ele não tem pedido válido para o relatório.

**Dados de partida:** há oito clientes. Conte somente pedidos não cancelados e some seu líquido contratado. Para quem não tiver venda elegível, mostre contagem e valor zero.

**Passo a passo:**

1. Comece por clientes, a população que precisa ser preservada.
2. Acrescente os pedidos com LEFT JOIN, colocando a condição de status no ON ou em uma CTE que filtra pedidos antes da junção.
3. Agrupe por cliente e conte uma coluna do pedido que não seja NULL quando ele existe. Some o líquido e trate a ausência de soma com COALESCE.
4. Confira que o resultado continua com oito clientes.
5. Em uma cópia da consulta, mova o filtro de status para o WHERE. Observe quem desaparece e explique o efeito.

**Dica para começar:** quando não há pedido, LEFT JOIN preserva o cliente com colunas do pedido NULL. COUNT(*) contaria essa linha preservada; COUNT(p.id) conta somente pedidos encontrados.

**Como conferir seu resultado:** Gabriela e Hugo aparecem com zero; total global contratado=3060 e quantidade=10.

### N2-4.2 — Anti-join resistente a NULL

**Situação:** o marketing precisa localizar pessoas que nunca tiveram uma compra não cancelada. Uma lista de exclusão recebida de outra equipe também pode conter um campo vazio. Você precisa garantir que esse NULL não faça todos os clientes sumirem da consulta.

**Seu objetivo:** aprender a perguntar se uma correspondência existe e comparar isso com uma lista que contém NULL.

**Dados de partida:** primeiro use clientes e pedidos. Depois use a lista de teste VALUES (2),(NULL::integer), que representa cliente 2 bloqueado e uma entrada sem id.

**Passo a passo:**

1. Para cada cliente, pergunte com NOT EXISTS se não há pedido não cancelado associado a ele.
2. Mostre os ids e nomes encontrados.
3. Em um teste separado, selecione clientes cujo id NOT IN a lista de exclusão com NULL.
4. Repita a exclusão usando NOT EXISTS e uma comparação de igualdade entre os ids.
5. Compare a quantidade de resultados e explique por que uma lista com NULL exige cuidado.

**Dica para começar:** a subconsulta de NOT EXISTS pode começar com SELECT 1; o interesse é haver uma linha correspondente, não seu conteúdo. O teste com lista é uma simulação de consulta e não altera nenhum cadastro.

**Como conferir seu resultado:** sem pedidos elegíveis: 7 e 8; exclusão da lista com NOT IN retorna zero clientes; com NOT EXISTS retorna sete, todos exceto 2.

### N2-4.3 — Investigar uma soma inflada

**Situação:** um relatório diz que o pedido 101 vendeu 500 e recebeu 480. Ao abrir a venda, você vê que ela tem apenas dois itens totalizando 250 e dois recebimentos totalizando 240. O erro pode estar na consulta, e não nos dados.

**Seu objetivo:** localizar em que etapa as linhas se multiplicaram e corrigir o cálculo sem apagar valores repetidos legítimos.

**Dados de partida:** o pedido 101 tem duas linhas em itens e duas em pagamentos. O cabeçalho registra bruto 250 e desconto 10.

**Passo a passo:**

1. Faça a junção direta de pedidos, itens e pagamentos filtrando o pedido 101. Antes de somar, exiba produto_id e id do pagamento em cada linha.
2. Conte as combinações: quantas vezes cada item e cada recebimento aparece?
3. Some os subtotais e os pagamentos nessa junção para reproduzir os números incorretos.
4. Refaça com duas CTEs: uma soma itens por pedido, outra soma pagamentos por pedido com sinal do estorno.
5. Ligue os dois resumos ao cabeçalho. Compare bruto dos itens, contratado após desconto e recebido.

**Dica para começar:** duas relações de um para muitos podem formar 2 × 2 combinações. A correção é levar cada origem à mesma unidade de análise, aqui uma linha por pedido, antes de juntá-las. SUM(DISTINCT valor) também descartaria valores iguais de operações diferentes.

**Como conferir seu resultado:** junção ingênua produz quatro linhas, subtotal inflado=500 e recebido inflado=480. A versão correta retorna bruto dos itens=250, recebido=240 e líquido contratado=240. Valores diferentes aqui podem representar desconto, não erro de cadastro.

### N2-4.4 — Último pedido sem perder clientes

**Situação:** o atendimento quer ver a última interação comercial de cada cliente. Mesmo quem nunca pediu precisa aparecer. Um pedido cancelado também conta como interação para esta tela, embora não conte como receita.

**Seu objetivo:** escolher apenas o pedido mais recente de cada pessoa, com uma regra explícita de desempate.

**Dados de partida:** use todos os pedidos, inclusive cancelados. A ordem é data_pedido decrescente e, para datas iguais, id decrescente.

**Passo a passo:**

1. Comece por clientes. Para cada um, procure seu pedido em ordem de recência e mantenha somente o primeiro.
2. Implemente essa busca com LEFT JOIN LATERAL e LIMIT 1; preserve os clientes sem resultado.
3. Entregue cliente_id, pedido_id e data_pedido, ordenados por cliente.
4. Crie uma segunda versão: numere os pedidos por cliente com ROW_NUMBER e ligue somente a posição 1 ao cadastro.
5. Compare as versões com EXCEPT nas duas direções; o resultado da comparação deve ser vazio.

**Dica para começar:** LATERAL permite que a consulta à direita use o id do cliente da linha à esquerda. Na versão com janela, o filtro de posição deve preservar o LEFT JOIN. Retire ORDER BY das consultas internas da comparação por conjuntos.

**Como conferir seu resultado:** ids dos últimos pedidos dos clientes 1 a 6: 108,103,112,111,110,109; clientes 7 e 8 ficam com NULL. As versões devem retornar o mesmo conjunto.

### N2-4.5 — Auditoria com registros ausentes dos dois lados

**Situação:** a contabilidade recebe dois arquivos: um com o total informado no cabeçalho das vendas e outro com os totais calculados pelos itens. Além de valores diferentes, pode faltar um pedido em qualquer dos arquivos. Comparar só os registros presentes nos dois esconderia parte dos problemas.

**Seu objetivo:** gerar uma lista única de divergências, distinguindo valor incorreto de registro ausente.

**Dados de partida:** simule os arquivos em CTEs. Não altere as tabelas reais. O valor comparado aqui é bruto, sem desconto.

**Passo a passo:**

1. Crie cabecalhos a partir de pedidos, deixando o 111 de fora e acrescentando 1 ao valor_total do 101 apenas no SELECT.
2. Crie totais_itens somando quantidade × preco_unitario por pedido, mas deixando o 112 de fora.
3. Faça FULL JOIN pelo id do pedido para preservar registros encontrados em qualquer lado.
4. Mostre o id disponível com COALESCE, o total de cada fonte e o motivo: somente_itens, somente_cabecalho ou valor_divergente.
5. Mantenha somente divergências e explique quais seriam perdidas com INNER JOIN.

**Dica para começar:** a coluna-chave NULL de um dos lados indica ausência naquela fonte. IS DISTINCT FROM compara os totais incluindo casos com NULL; uma comparação comum <> não resolve sozinha esses casos.

**Como conferir seu resultado:** três ocorrências: 101 com diferença de 1; 111 somente nos itens; 112 somente no cabeçalho. Uma junção interna esconderia os dois registros ausentes.

### N2-4.6 — Preço histórico versus preço atual

**Situação:** o catálogo aumentou o preço do Mouse. O comercial quer simular quanto os itens de uma venda antiga custariam hoje, enquanto a contabilidade precisa manter o valor que foi vendido na época. Usar sempre o preço atual reescreveria a história do faturamento.

**Seu objetivo:** distinguir o preço histórico do item do preço atual do produto, observando o efeito de uma alteração controlada.

**Dados de partida:** use o pedido 101. Nele há duas unidades de Mouse com preço histórico 50 e um Teclado de 150. O Mouse custa 50 também no catálogo inicial.

**Passo a passo:**

1. Abra BEGIN. Faça uma consulta com duas somas: quantidade × preço do item e quantidade × preço do cadastro de produtos.
2. Altere somente produtos.preco do Mouse para 60. Não altere itens.
3. Repita as duas somas e explique por que uma mudou e outra permaneceu igual.
4. Termine com ROLLBACK e confira que o preço atual do Mouse voltou a 50.
5. Escreva qual coluna usaria para receita histórica e qual para uma simulação comercial aos preços de hoje.

**Dica para começar:** a junção liga itens.produto_id a produtos.id. Use aliases para nomear claramente preco_historico e preco_atual nas expressões e evitar a troca acidental de origem.

**Como conferir seu resultado:** antes, ambos=250; depois, histórico=250 e cadastro atual=270; após ROLLBACK, preço do Mouse=50. Não reescreva o preço dos itens.

## N2-5 — Desempenho orientado por hipóteses

**Seu papel neste laboratório:** atuar como analista que precisa justificar uma mudança antes de recomendá-la. Você vai levantar uma hipótese, medir o estado atual, mudar um aspecto e comparar. A pergunta não é apenas ficou mais rápido?, mas quanto trabalho o servidor realizou, que resultado produziu e que custo a mudança trouxe?.

Execute **02_Preparacao_Desempenho.sql** uma vez. Esperado: 300000 linhas, 1000 clientes, 15000 pendentes e 82 linhas no filtro de referência. A distribuição UF/cidade tem dependência intencional para estudar estatísticas conjuntas; não é necessário produzir estatísticas desatualizadas. Não altere parâmetros globais nem desative scans para forçar um plano.

Antes de cada etapa, consulte pg_indexes para saber quais índices já existem. Se perdeu a linha de base, recomece em outro banco de treinamento; não compare um estado já reorganizado como se fosse o original. Auto-commit ativo para os experimentos de manutenção, sem transação pendente. Meça três vezes cada consulta em cada condição, mantendo filtro e projeção iguais. Registre versão, CPU/RAM da VM, cache observado e índices existentes. Não há meta fixa de milissegundos nem obrigação de escolher um tipo específico de scan.

### N2-5.1 — Linha de base e seletividade

**Situação:** a aplicação consulta os eventos de um cliente em um período. Antes de criar índices, você precisa descobrir quanto trabalho o PostgreSQL faz hoje. Sem essa referência, não há comparação confiável para dizer se uma mudança ajudou.

**Seu objetivo:** registrar a linha de base e observar como a quantidade de linhas solicitada influencia o plano.

**Dados de partida:** execute 02_Preparacao_Desempenho.sql uma vez. eventos deve ter 300 mil linhas e nenhum índice. As datas desta etapa são de 2026 e os extremos do BETWEEN são inclusivos.

**Passo a passo:**

1. Confira a ausência de índices em pg_indexes. Registre versão do servidor, tamanhos de tabela/índices e recursos da VM; execute ANALYZE.
2. Escreva três SELECT *: cliente 42 entre 1º de março e 10 de abril; somente esse período, sem cliente; tabela inteira.
3. Acrescente EXPLAIN (ANALYZE, BUFFERS) a cada consulta. Execute cada uma três vezes, salvando os nove planos antes de qualquer índice.
4. Na tabela de medições ao final do roteiro, anote scan, linhas estimadas/reais, loops, buffers, planejamento e execução.
5. Compare a parcela da tabela retornada por cada filtro. Essa parcela é sua seletividade: uma busca que retorna poucas linhas é mais seletiva.

**Dica para começar:** EXPLAIN ANALYZE executa a consulta e devolve o plano com medidas. Se houver workers, leia também Gather e loops; actual rows pode ser média por execução do nó. Não some buffers do pai e do filho: eles podem representar o mesmo trabalho. Use o mesmo nível do plano para comparar etapas.

**Como conferir seu resultado:** filtro combinado=82 linhas; intervalo sem cliente=82000; tabela inteira=300000. Guarde os nove planos antes da criação dos índices.

### N2-5.2 — Índice composto e seu custo

**Situação:** a aplicação usa muito a busca por cliente e período. A equipe propôs um índice nas duas colunas, mas quer saber se ele também ajuda uma consulta só por data e se vale a pena para exportar a tabela inteira.

**Seu objetivo:** testar uma hipótese de índice com as mesmas consultas da linha de base e contabilizar seu custo de armazenamento.

**Dados de partida:** preserve eventos como está após N2-5.1. Não recrie nem reorganize os dados. Você precisa ter salvo os planos sem índice.

**Passo a passo:**

1. Crie um índice B-tree com cliente_id primeiro e data_evento depois. Escolha o nome n2_eventos_cliente_data_idx para acompanhar as soluções.
2. Execute novamente cada uma das três consultas anteriores, três vezes, sem mudar filtros nem colunas do SELECT.
3. Compare os planos novos com os anteriores: mudou o tipo de acesso? O trabalho em buffers diminuiu? A contagem retornada permaneceu igual?
4. Consulte pg_relation_size para medir o espaço do índice.
5. Recomende em quais consultas esse índice faz sentido e justifique o comportamento da busca só por data com o plano real.

**Dica para começar:** um índice composto se parece com uma lista organizada por cliente e, dentro de cada cliente, por data. Ele pode reduzir o trabalho da busca seletiva, mas ler grande parte da tabela pode favorecer outra estratégia. Não force o tipo de scan nem trate cost como tempo em milissegundos.

**Como conferir seu resultado:** resultados idênticos aos da linha de base; conclusão baseada em buffers, estimativas, linhas e custo de armazenamento, além do tempo. Não confunda cost com milissegundos.

### N2-5.3 — Índice parcial para a fila pendente

**Situação:** a operação tem uma tela que exibe somente os primeiros 50 eventos pendentes de março. Pendentes são uma pequena parte da tabela. A proposta é indexar apenas essa fila, aproveitando também a ordem usada na tela.

**Seu objetivo:** avaliar um índice parcial e entender quais consultas ficam fora de sua cobertura.

**Dados de partida:** use eventos com o índice composto da etapa anterior. A fila exige status='pendente', data >= 01/03/2026 e < 01/04/2026, ORDER BY data_evento,id e LIMIT 50.

**Passo a passo:**

1. Escreva a consulta da tela com SELECT * e meça três vezes antes do novo índice.
2. Em uma consulta de contagem separada, descubra quantos pendentes de março existem antes do LIMIT.
3. Crie n2_eventos_pendentes_idx em (data_evento,id) com WHERE status='pendente'. Repita as três medições da tela sem mudar o SQL.
4. Teste a mesma consulta trocando somente o status para pago. Explique por que os dados pagos não estão nesse índice parcial.
5. Compare o tamanho do índice parcial com o do composto e registre se o plano aproveitou filtro, ordenação e limite.

**Dica para começar:** o WHERE de CREATE INDEX determina quais linhas entram no índice. Ele não altera nem exclui linhas da tabela. ORDER BY e LIMIT fazem parte do problema: buscar todas as linhas e ordenar no cliente seria outro experimento.

**Como conferir seu resultado:** há 4000 pendentes em março antes do LIMIT; a busca limitada retorna 50 linhas. Não exija uso do índice se o plano real justificar outra estratégia. Sua conclusão deve distinguir predicado do índice, ordenação e limite.

### N2-5.4 — Índice de expressão

**Situação:** os emails dos eventos vieram em maiúsculas, mas a aplicação recebe pesquisas em minúsculas e usa lower(email) no filtro. Um índice na coluna original organiza o texto original; a consulta trabalha com o resultado de uma função.

**Seu objetivo:** testar um índice na expressão realmente usada pela busca e provar que ele não muda os registros encontrados.

**Dados de partida:** o email pesquisado é cliente42@example.test. Use a tabela eventos e preserve os índices já criados; ainda não há índice de expressão.

**Passo a passo:**

1. Meça três vezes SELECT * filtrado por lower(email)='cliente42@example.test'. Salve também uma lista dos ids retornados em ordem.
2. Crie n2_eventos_email_lower_idx sobre a expressão lower(email), com os parênteses exigidos por CREATE INDEX.
3. Execute ANALYZE e repita exatamente a mesma busca três vezes.
4. Confira a contagem e os ids nas duas condições. Compare scans e buffers, além dos tempos.
5. Explique que manutenção extra passa a existir quando o valor usado na expressão muda.

**Dica para começar:** o índice deve corresponder à expressão do filtro, e não apenas mencionar a mesma coluna. Um Bitmap Scan pode ser uma escolha válida: descreva o que o plano fez em vez de exigir o texto Index Scan.

**Como conferir seu resultado:** 300 linhas nas duas condições; expressão no filtro compatível com a expressão indexada. Observe eventuais Bitmap Scans sem tratá-los como falha.

### N2-5.5 — Estatísticas individuais e dependência entre colunas

**Situação:** cada evento tem UF e cidade. Nesta carga, PR aparece sempre com Curitiba e SP sempre com Santos. Filtrar PR e Curitiba não são duas reduções independentes da população. O planejador pode precisar de informação conjunta para estimar melhor a quantidade de linhas.

**Seu objetivo:** relacionar estimativas com a distribuição real e avaliar estatísticas de dependência entre colunas.

**Dados de partida:** mantenha os dados de eventos. Não altere a carga para gerar estatísticas ruins. pg_stats já é uma visão disponível para consulta das tabelas que seu usuário pode ler; não precisa ser ativada.

**Passo a passo:**

1. Meça três vezes SELECT * WHERE uf='PR' AND cidade='Curitiba', antes de criar o objeto de estatísticas. Guarde estimativa, quantidade real e nó/loops usados na comparação.
2. Consulte pg_stats para cliente_id, uf e cidade. Observe n_distinct e as frequências; correlation trata de ordem física, não de dependência entre duas colunas.
3. Agrupe eventos por uf,cidade para comprovar quais combinações existem e suas quantidades.
4. Crie estatísticas com CREATE STATISTICS ... (dependencies) ON uf,cidade FROM eventos. Depois execute ANALYZE: criar o objeto sozinho não coleta os dados.
5. Repita as três medições e consulte pg_stats_ext. Compare as estimativas antes/depois e escreva uma conclusão sem exigir mudança de scan ou de tempo.

**Dica para começar:** 60% das linhas são PR e também Curitiba. Tratar os filtros como independentes sugeriria 60% × 60%=36%; com dependência, eles podem descrever os mesmos 60%. Esse cálculo explica a hipótese, mas a evidência final deve vir do seu plano. Se a estimativa já era boa, registre isso.

**Como conferir seu resultado:** 180000 linhas reais, PR aparece apenas com Curitiba e SP apenas com Santos. As condições são dependentes: não reduzem a população independentemente. Não confunda correlation de pg_stats (ordem física de uma coluna) com dependencies (relação entre colunas). Criar estatísticas não cria índice nem reorganiza a tabela. Se a estimativa já era boa, documente isso.

### N2-5.6 — Organização física, versões mortas e relatório final

**Situação:** depois de testar índices, a equipe quer investigar duas perguntas diferentes: aproximar fisicamente os eventos do mesmo cliente reduz leituras? E o que acontece com o espaço após atualizações e exclusões? Misturar as experiências na tabela original prejudicaria as comparações anteriores.

**Seu objetivo:** separar organização física, limpeza e estatísticas usando uma cópia controlada dos eventos.

**Dados de partida:** crie eventos_fisicos como cópia de eventos e um índice próprio (cliente_id,data_evento), chamado n2_fisicos_cliente_data_idx. Os índices da origem não acompanham CREATE TABLE AS. Não mexa em eventos.

**Passo a passo:**

1. Execute ANALYZE na cópia, consulte correlation de cliente_id e registre os tamanhos da tabela e dos índices. Meça três vezes o filtro de referência: cliente 42 entre 01/03/2026 e 10/04/2026, com SELECT *.
2. Execute CLUSTER na cópia usando seu índice, depois ANALYZE. Repita tamanhos, correlation e as três medições. Essa é a comparação antes/depois da organização física.
3. Só agora altere status para revisado onde id<=60000 e exclua id>270000. Confira quantas linhas cada comando afetou.
4. Consulte total de linhas, revisadas e ids acima do limite; meça novamente os tamanhos. As medições desta fase já incluem alteração dos dados.
5. Com Auto-commit ativo e sem transação pendente, selecione apenas VACUUM (VERBOSE, ANALYZE) bdadosql_n2.eventos_fisicos e execute. Salve as mensagens, depois repita contagens e tamanhos.
6. Explique separadamente o efeito de CLUSTER, ANALYZE e VACUUM. Termine com o relatório de uma página solicitado abaixo.

**Dica para começar:** UPDATE pode deixar uma versão antiga; DELETE torna a linha elegível para limpeza quando ela deixa de ser necessária às transações. Por isso, linhas mortas removidas não são a mesma coisa que linhas vivas excluídas. Autovacuum e poda podem limpar parte delas antes da medição. Um arquivo que não diminuiu pode ter espaço interno pronto para reutilização.

**Como conferir seu resultado:** após as escritas, 270000 linhas vivas, 60000 revisadas e nenhuma com id>270000. Até 90000 versões mortas podem ter sido geradas pelas duas escritas; autovacuum, poda e outras condições afetam o que o VACUUM reporta. Espaço reutilizável não obriga redução do arquivo. CLUSTER exige bloqueio exclusivo e não mantém a organização nas novas escritas.

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
