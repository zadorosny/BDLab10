# Laboratório extra — Expressões regulares POSIX

**Cenário:** a equipe de cadastro da Loja Horizonte recebeu outro arquivo de contatos. Antes de importá-lo, você precisa reconhecer padrões, apresentar os dados padronizados e explicar os problemas encontrados. O objetivo é aprender a construir e testar uma expressão, e não decorar um regex de email.

São **12 exercícios graduais**, com dados próprios. Este extra pode ser feito logo depois de **N2-1.4 — Diagnosticar o lote bruto**, ou de forma independente. Basta conhecer SELECT, WHERE e ORDER BY; CASE e as etapas com WITH são explicados quando necessários.

Abra **Laboratorio_Regex_POSIX.html** no navegador do Windows e execute o SQL no DBeaver conectado ao PostgreSQL 18 da VM Hyper-V. O HTML funciona offline; o SQL é executado no servidor. Reserve duas ou três sessões curtas, conforme seu ritmo.

Em cada exercício, situação, objetivo e dados de partida ficam visíveis. **Passo a passo**, **dica**, **conferência** e **solução possível** começam recolhidos no HTML. Abra somente a ajuda de que precisar. Registre o SQL, a saída e uma explicação curta antes de consultar a solução.

## Prepare e conheça a carga

1. No DBeaver, confirme o banco de treinamento com `SELECT current_database(), current_user, version();`.
2. Abra [00_Preparacao_Regex.sql](00_Preparacao_Regex.sql) e execute o arquivo inteiro **uma vez**. Use Auto-commit ativo; o arquivo controla seu próprio BEGIN/COMMIT.
3. Confira o resultado final: **12 linhas**. O preparador cria o schema independente `bdadosql_regex`; não depende das cargas anteriores.
4. Se o preparador falhar, interrompa, execute ROLLBACK e examine a mensagem. Se o schema já existir, confira a carga anterior; o script não reinicia nem apaga os dados.
5. Use nomes qualificados, como `bdadosql_regex.importacao_contatos`, nas suas consultas. Assim, uma mudança de search_path não seleciona a tabela homônima de outro laboratório.
6. Todos os exercícios são resolvidos com **SELECT**. Você pode repeti-los sem restaurar a carga. Preserve os valores originais como evidência.

```sql
SELECT *
FROM bdadosql_regex.importacao_contatos
ORDER BY id;
```

| Campo | O que representa |
|---|---|
| id | A linha do arquivo, usada para identificar evidências |
| nome | Nome recebido, incluindo brancos extras |
| email | Endereço recebido; pode estar vazio ou ser NULL |
| telefone | Texto recebido, com ou sem pontuação |
| uf | Sigla informada pela outra equipe |
| codigo | Identificador externo, cujo padrão esperado será definido no exercício |
| observacao | Texto livre que pode mencionar pedidos |

Os nomes de Carla e Iara contêm, respectivamente, uma tabulação e uma quebra de linha reais. No script, `E'\t'` e `E'\n'` representam esses caracteres. Dependendo da grade do DBeaver, eles podem parecer espaços ou uma célula com várias linhas.

## Guia de consulta

Uma expressão regular descreve um padrão de texto. No PostgreSQL, coloque o padrão entre aspas simples:

```sql
SELECT 'pedido 123' ~ '[[:digit:]]+' AS encontrou_numero;
```

| Recurso | Leitura |
|---|---|
| `~` / `~*` | Corresponde, distinguindo / ignorando maiúsculas |
| `!~` / `!~*` | Não corresponde, distinguindo / ignorando maiúsculas |
| `^` / `$` | Início / fim do texto |
| `[[:digit:]]` | Um dígito |
| `[[:space:]]` | Um branco, inclusive tabulação e quebra de linha |
| `[^[:space:]@]` | Um caractere que não seja branco nem arroba |
| `.` / `[.]` | Um caractere qualquer / um ponto literal |
| `+` / `*` / `?` | Uma ou mais / zero ou mais / zero ou uma repetição |
| `{3}` / `{2,}` / `{10,11}` | Exatamente 3 / pelo menos 2 / de 10 a 11 repetições |
| `(...)` | Agrupamento e captura |

A barra vertical entre alternativas significa “ou”. Sem âncoras, o padrão pode corresponder a um trecho. O PostgreSQL usa por padrão uma versão estendida, chamada ARE; aqui praticamos os recursos POSIX e as funções SQL que os utilizam. Consulte a [documentação de expressões regulares](https://www.postgresql.org/docs/18/functions-matching.html#FUNCTIONS-POSIX-REGEXP).

Para a limpeza, `btrim` remove espaços das extremidades, `lower` e `upper` padronizam letras, e `NULLIF(valor, '')` transforma texto vazio em NULL. `btrim` sem segundo argumento não remove toda espécie de branco; o RX-07 trata tabulações e quebras de linha antes dessa etapa. Veja as [funções de texto](https://www.postgresql.org/docs/18/functions-string.html).

Uma regex testa uma regra. “Passou na regra” não significa “o dado existe no mundo real” nem “todas as regras de negócio foram verificadas”. Nos exercícios, você vai encontrar um exemplo concreto dessa diferença.

## Exercícios

### RX-01 — Encontrar texto dentro de um nome

**Situação:** o atendimento procura contatos relacionados ao nome Ana. O arquivo mistura maiúsculas e minúsculas; uma busca por um trecho pode trazer pessoas com outros nomes.

**Seu objetivo:** comparar os quatro operadores de correspondência e explicar por que Mariana aparece em uma busca por `ana`.

**Dados de partida:** consulte `id` e `nome` nas 12 linhas, mantendo o texto original.

**Passo a passo:**

1. Acrescente ao SELECT uma coluna com `nome ~ 'ana'`.
2. Acrescente outra com `nome ~* 'ana'` e compare os resultados por id.
3. Acrescente os testes com `!~` e `!~*`.
4. Anote os ids que passaram em cada busca positiva e explique a diferença entre procurar um trecho e procurar um nome inteiro.

**Dica para começar:** os operadores podem aparecer como colunas do SELECT antes de serem usados no WHERE. Dê um nome a cada coluna com AS; a grade mostrará verdadeiro ou falso.

**Como conferir seu resultado:** `~ 'ana'` passa somente no id 3. `~* 'ana'` passa nos ids 1, 2, 3 e 4. Nos nomes não nulos desta carga, os dois operadores negativos produzem o inverso dos respectivos positivos. Mariana contém o trecho ana, mesmo que ele não seja seu primeiro nome.

### RX-02 — Separar Ana, Anabela e Mariana

**Situação:** a primeira busca trouxe contatos demais. Agora o atendimento quer Ana como primeiro nome, aceitando sobrenome depois, mas sem incluir Anabela ou Mariana.

**Seu objetivo:** construir três testes: ocorrência em qualquer posição, ocorrência no início e primeiro nome exatamente Ana.

**Dados de partida:** use `btrim(nome)` para desconsiderar os espaços nas extremidades. Ignore diferenças entre maiúsculas e minúsculas.

**Passo a passo:**

1. Repita a busca por ana sem âncoras.
2. Acrescente a âncora de início ao padrão e observe quem deixa de passar.
3. Depois de ana, exija um branco ou o fim do texto, agrupando as duas alternativas.
4. Teste separadamente os textos Ana e Ana Silva com um padrão que exija Ana como texto inteiro.

**Dica para começar:** pense na regra em partes: início, letras ana, depois um branco OU fim. Use parênteses para manter as alternativas juntas.

**Como conferir seu resultado:** a busca sem âncora passa nos ids 1, 2, 3 e 4; com início, nos ids 1, 2 e 4; com primeiro nome Ana, somente nos ids 1 e 2. O teste de texto inteiro aceita Ana e rejeita Ana Silva.

### RX-03 — Detectar brancos que a tela pode esconder

**Situação:** a equipe percebe nomes desalinhados, mas olhar a grade não basta para saber se há um espaço, vários espaços ou outro tipo de branco.

**Seu objetivo:** localizar nomes com qualquer branco e nomes com pelo menos dois brancos consecutivos. Depois, comparar zero ou mais repetições com uma ou mais.

**Dados de partida:** use os nomes originais. Os ids 6 e 12 têm tabulação e quebra de linha.

**Passo a passo:**

1. Exiba uma coluna que teste a presença de `[[:space:]]`.
2. Exiba outra que exija pelo menos duas ocorrências consecutivas dessa classe.
3. Em um SELECT separado, teste a string vazia contra padrões ancorados que aceitem somente brancos: um com asterisco e outro com mais.
4. Teste também uma tabulação e uma quebra de linha usando o padrão com mais.

**Dica para começar:** `{2,}` significa pelo menos duas repetições do elemento anterior. Para representar texto vazio em SQL, use `''`. O `+` e o `*` não têm o mesmo comportamento diante desse texto.

**Como conferir seu resultado:** há algum branco nos ids 1, 2, 3, 4, 6, 7 e 12; há pelo menos dois consecutivos nos ids 1 e 7. O padrão ancorado com asterisco aceita vazio; o equivalente com mais rejeita. Tabulação e quebra de linha passam no teste de brancos.

### RX-04 — Reconstruir o regex de email

**Situação:** você encontrou o regex do N2-1.4, mas precisa explicar cada parte antes de usá-lo no diagnóstico. Há também emails ausentes, que a equipe quer contar separadamente.

**Seu objetivo:** classificar cada email como ausente, passa no formato ou fora do formato, mostrando o original e a versão normalizada.

**Dados de partida:** use a regra didática `^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$`. Considere NULL, texto vazio e texto composto somente de espaços comuns como ausentes. Não retire espaços internos do email.

**Passo a passo:**

1. Escreva uma frase explicando cada trecho do padrão: início, trecho sem branco nem arroba, arroba, outro trecho, ponto literal, trecho final e fim.
2. Exiba o email original e `NULLIF(lower(btrim(email)), '')`.
3. Teste o padrão sobre o original e classifique a versão normalizada com CASE, verificando a ausência antes do formato.
4. Observe os ids 1, 8 e 9. Explique o papel da limpeza, do NULL e a limitação revelada pelos dois pontos seguidos.
5. Em outro SELECT, compare `NULL::text ~ 'abc'` e `NULL::text !~ 'abc'`.

**Dica para começar:** dentro de `[^...]`, o circunflexo significa exclusão; no início do padrão, significa início do texto. CASE escolhe uma resposta: `CASE WHEN condição THEN 'resposta' ELSE 'outra' END`. Um teste com NULL continua desconhecido; use IS NULL para classificá-lo.

**Como conferir seu resultado:** após normalizar, 5 passam no formato (1, 3, 6, 9, 12), 2 estão ausentes (2, 8) e 5 estão fora (4, 5, 7, 10, 11). O original do id 1 falha pelos espaços nas bordas. O id 9 passa mesmo com example..test, mostrando que a regra é incompleta. Os dois testes com NULL retornam NULL; um WHERE com esses testes não seleciona essa linha.

### RX-05 — Conferir uma lista de UFs

**Situação:** neste cenário, a loja atende somente PR, SP, PE, RS, RJ e SC. Duas letras quaisquer não bastam para decidir se a UF é atendida.

**Seu objetivo:** reconhecer exatamente uma das seis siglas permitidas, depois de padronizar espaços e letras.

**Dados de partida:** use `upper(btrim(uf))`. Uma UF ausente não pertence à lista.

**Passo a passo:**

1. Exiba a UF original e a normalizada.
2. Monte um grupo com as seis alternativas e ancore o grupo inteiro.
3. Registre quais ids estão fora da regra.
4. Em exemplos separados, compare `^PR|SC$` com `^(PR|SC)$` nos textos PR, PRX, XSC e SP.

**Dica para começar:** coloque as alternativas entre parênteses antes de acrescentar início e fim. Sem o grupo, as âncoras ficam ligadas a alternativas diferentes. Em uma consulta de negócio, IN também seria uma escolha simples; aqui o objetivo é praticar agrupamento.

**Como conferir seu resultado:** 10 UFs passam; os ids 5 e 10 ficam fora. No teste separado, o agrupamento incorreto aceita PRX e XSC; o correto aceita apenas PR entre os quatro exemplos.

### RX-06 — Conferir códigos com tamanho exato

**Situação:** o identificador externo deve conter o prefixo CLI, um hífen e exatamente três dígitos. A equipe quer aceitar diferenças de caixa e espaços nas extremidades, mas rejeitar prefixos ou sufixos extras.

**Seu objetivo:** validar o formato completo do código, sem aceitar somente um pedaço que pareça correto.

**Dados de partida:** normalize com `upper(btrim(codigo))`. Neste exercício, os dígitos esperados são os caracteres de 0 a 9; use `COLLATE "C"` no texto testado para explicitar essa convenção.

**Passo a passo:**

1. Exiba o código original e o normalizado.
2. Escreva o prefixo literal, a classe de dígitos e o quantificador de três posições.
3. Acrescente as âncoras e identifique os ids rejeitados.
4. Como treino curto de opcionalidade, crie um padrão para dois dígitos, um hífen opcional e quatro dígitos. Teste 123456, 12-3456 e 12--3456.

**Dica para começar:** use `{3}` depois da classe. Hífen fora de colchetes é literal; `-?` torna esse hífen opcional. Coloque o texto com COLLATE antes de `~`, como em `codigo COLLATE "C" ~ 'padrão'`.

**Como conferir seu resultado:** 9 códigos passam; 5, 7 e 8 são os ids rejeitados. CLI-05 tem dois dígitos, XCLI-007 tem prefixo extra e CLI-008-extra tem sufixo extra. No treino, os dois primeiros textos passam e o texto com dois hífens falha.

### RX-07 — Padronizar nomes com regexp_replace

**Situação:** o cadastro quer exibir nomes legíveis, com um espaço entre as palavras, preservando o texto recebido para auditoria.

**Seu objetivo:** apresentar uma coluna com o nome normalizado e demonstrar a diferença entre substituir a primeira ocorrência e todas as ocorrências.

**Dados de partida:** use as 12 linhas originais. Não execute UPDATE.

**Passo a passo:**

1. Use regexp_replace para trocar um grupo de brancos por um espaço comum, sem flags.
2. Repita a expressão com a flag g.
3. Aplique btrim ao resultado da segunda expressão.
4. Compare original, primeira substituição e nome final, especialmente nos ids 1, 6, 7 e 12.

**Dica para começar:** a assinatura usada aqui é `regexp_replace(texto, padrão, substituição, 'g')`. Procure grupos de brancos, não letras. A substituição deve ser um espaço, e não texto vazio, para evitar juntar as palavras.

**Como conferir seu resultado:** os nomes finais desses ids são Ana Silva, Carla Souza, Diego Alves e Iara Melo. No id 1, sem g, somente o primeiro grupo de espaços é substituído. Depois das consultas, o original ainda contém seus espaços, tabulação ou quebra de linha.

### RX-08 — Limpar telefones sem esconder problemas

**Situação:** a equipe quer comparar telefones sem pontuação. Porém, apagar tudo que não é dígito pode esconder um erro de digitação, como a letra A recebida no id 7.

**Seu objetivo:** mostrar os dígitos extraídos e classificar cada telefone como ausente, passa na regra local ou revisar, considerando também o original.

**Dados de partida:** a regra didática aceita DDD + número com 10 ou 11 dígitos, sem código do país. O original pode conter dígitos, brancos, parênteses, mais e hífen, mas não letras. NULL e texto só de brancos contam como ausentes. Isso não verifica se o telefone existe.

**Passo a passo:**

1. Gere uma coluna que remova todos os caracteres que não sejam dígitos.
2. Faça um teste separado para os caracteres permitidos no texto original.
3. Confira se o resultado limpo contém exatamente 10 ou 11 dígitos.
4. Use CASE para separar ausência, atendimento às duas condições e revisão.
5. Explique por que os ids 6 e 7 pedem revisão por motivos diferentes.

**Dica para começar:** a classe negada `[^[:digit:]]` localiza o que será removido. Use g para remover todas as ocorrências. Uma CTE `WITH telefones AS (SELECT ...)` pode dar o nome digitos ao resultado para reutilizá-lo no SELECT seguinte; ela não cria uma tabela permanente.

**Como conferir seu resultado:** 7 passam (1, 2, 3, 4, 9, 11, 12), 2 estão ausentes (8, 10) e 3 pedem revisão (5, 6, 7). O id 7 vira uma sequência de 10 dígitos após apagar a letra, mas deve ser rejeitado pelo original. O id 6 tem código do país e está fora do modelo local; isso não prova que seja um telefone inválido.

### RX-09 — Extrair o domínio usando um grupo

**Situação:** a equipe quer saber os domínios informados nos emails, sem manter a parte que identifica o usuário no resultado dessa coluna.

**Seu objetivo:** extrair o domínio dos emails que passam no formato básico e manter todas as 12 linhas no relatório.

**Dados de partida:** use a normalização e o padrão do RX-04. O domínio é a parte depois do arroba. A regra continua simplificada.

**Passo a passo:**

1. Coloque um par de parênteses em volta da parte do padrão que representa o domínio.
2. Use esse padrão em `substring(texto FROM padrão)`.
3. Exiba id, email original e domínio, sem filtrar fora as linhas que não correspondem.
4. Como comparação, teste `regexp_match` no texto CLI-017 com um grupo para CLI e outro para os três dígitos.

**Dica para começar:** nessa forma de substring, o primeiro grupo entre parênteses determina o trecho devolvido. Já regexp_match pode devolver um array com vários grupos. Os parênteses pertencem ao padrão; não devem aparecer no email.

**Como conferir seu resultado:** os ids 1 e 3 retornam example.test; o 6 retorna example.com.br; o 9 retorna example..test; o 12 retorna example.test. Os outros sete retornam NULL, e o relatório continua com 12 linhas. O teste do código retorna os grupos CLI e 017.

### RX-10 — Reaproveitar grupos na substituição

**Situação:** cinco telefones já passaram pela conferência de formato local e têm 11 dígitos. O atendimento quer apresentá-los no formato (DD) NNNNN-NNNN.

**Seu objetivo:** capturar as três partes do número e reconstruir a apresentação, sem alterar a carga.

**Dados de partida:** trabalhe somente com os ids 1, 3, 4, 9 e 12, já conferidos no RX-08. Retire a pontuação antes de formatar.

**Passo a passo:**

1. Gere a sequência de dígitos dos cinco telefones selecionados.
2. Monte um padrão ancorado com três grupos consecutivos: dois, cinco e quatro dígitos.
3. Use regexp_replace com uma substituição que reaproveite os três grupos, acrescentando parênteses, espaço e hífen.
4. Compare telefone original e formatado.

**Dica para começar:** na substituição, `\1`, `\2` e `\3` referem-se aos grupos. Para representar essas barras de forma explícita no SQL, use um literal de escape: `E'(\\1) \\2-\\3'`. Os parênteses desse texto de substituição são os que aparecerão na apresentação.

**Como conferir seu resultado:** aparecem 5 linhas. O id 3 fica (21) 98888-0003; o id 4 fica (48) 98888-0004. Os ids 1, 9 e 12 já tinham essa apresentação. Essa consulta formata os casos selecionados; não substitui a classificação de todo o lote.

### RX-11 — Entender uma ocorrência e várias ocorrências

**Situação:** algumas observações citam pedidos. Uma pessoa pode mencionar mais de um, e outra pode não mencionar nenhum. A equipe quer entender por que um relatório muda de quantidade ou perde um contato ao extrair essas referências.

**Seu objetivo:** comparar regexp_match com regexp_matches e explicar o que cada linha do resultado passa a representar.

**Dados de partida:** examine somente as observações dos ids 1, 3 e 8. Procure PED- seguido de três dígitos e capture esses dígitos.

**Passo a passo:**

1. Exiba o id e o resultado de regexp_match.
2. Faça outra consulta com regexp_matches e a flag g.
3. Compare os ids presentes e a quantidade de vezes em que cada um aparece.
4. Explique por que contar as linhas dos dois resultados não mede necessariamente a mesma coisa.

**Dica para começar:** regexp_match representa a primeira ocorrência como um array, ou NULL. regexp_matches pode produzir várias linhas e não produz uma linha para o contato sem correspondência quando usada dessa maneira no SELECT. Observe os ids, não apenas a contagem total.

**Como conferir seu resultado:** a primeira consulta tem 3 linhas: id 1 com 101, id 3 com 103 e id 8 com NULL. A segunda também tem 3, mas agora o id 1 aparece com 101 e 102, o id 3 com 103, e o id 8 não aparece. A contagem igual esconde populações diferentes; menção no texto também não comprova existência do pedido.

### RX-12 — Escrever um diagnóstico com evidências

**Situação:** a equipe precisa de uma conclusão sobre o lote, não apenas de várias colunas booleanas. Ela também quer saber quais limites das regras continuam pendentes.

**Seu objetivo:** entregar um relatório por linha e um parágrafo que justifique a decisão usando contagens e exemplos concretos.

**Dados de partida:** combine as regras de email, UF e código. Para esta decisão, email ausente é permitido; UF e código precisam passar. Mostre o nome normalizado, mas não o use como critério de rejeição. O telefone está fora desta decisão e foi diagnosticado separadamente no RX-08.

**Passo a passo:**

1. Monte uma etapa com as colunas originais e suas versões normalizadas.
2. Acrescente a situação do email e os testes de UF e código.
3. Acrescente uma decisão: passa nas regras ou revisar. Preserve todas as linhas.
4. Conte as situações de email, as UFs e os códigos rejeitados, e quantos contatos passam nas três regras combinadas. As ocorrências de erro podem se sobrepor; não some essas contagens como se fossem pessoas diferentes.
5. Escreva um parágrafo com os totais e pelo menos duas evidências por id: uma de normalização e outra de limitação da regra.

**Dica para começar:** reutilize as consultas anteriores. Duas CTEs, normalizados e diagnostico, podem organizar as etapas antes do SELECT final. O nome de cada etapa funciona como fonte da seguinte. Para contar, você pode agrupar a classificação ou usar COUNT com FILTER.

**Como conferir seu resultado:** são 12 contatos; 5 emails passam no formato, 2 estão ausentes e 5 estão fora; 2 UFs e 3 códigos não passam. Seis contatos passam nas regras combinadas (1, 2, 3, 6, 9, 12), e seis pedem revisão. O id 1 demonstra normalização útil. O id 9 exige registrar a limitação, pois example..test passa. Não conclua que os seis estão integralmente validados nem importe a carga durante este exercício. A solução possível inclui um exemplo de diagnóstico escrito.

## Retome o laboratório original

Volte ao [N2-1.4 no roteiro de nível 2](../01_Laboratorios_Nivel2.md#n2-14--diagnosticar-o-lote-bruto) ou ao [HTML de nível 2](../Laboratorios_Nivel2.html#N2-1.4). Explique o regex de email com suas palavras e compare a qualidade do seu diagnóstico antes e depois deste extra.

As soluções completas estão em [02_Solucoes_Regex.sql](02_Solucoes_Regex.sql). A [validação](VALIDACAO.md) descreve as conferências executadas. As referências técnicas estão no guia de consulta acima.
