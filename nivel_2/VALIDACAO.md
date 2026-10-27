# Validação do nível 2

Os preparadores e os 30 blocos de soluções foram executados em banco temporário **PostgreSQL 18.6 via PGlite 0.5.10 (WebAssembly)**, usando Node.js 24.22.0. Foram aprovadas **33 conferências automatizadas** dos resultados e invariantes.

As tentativas de erro foram executadas separadamente com recuperação transacional, como orientado no roteiro. VACUUM e VACUUM FULL foram enviados como comandos isolados. Os scripts de preparação foram executados na ordem prevista.

Conferências realizadas:

- Rejeições CHECK, unicidade e FK com SQLSTATE 23514, 23505 e 23503; recuperação por SAVEPOINT mantendo a alteração anterior.
- Estoques restaurados por ROLLBACK e preço histórico preservado; diagnóstico do lote, quatro contatos finais e repetição do UPSERT com conteúdo idêntico.
- Datas nas duas configurações de fuso retornando os mesmos ids; ausência de email, NULL nas comparações e escapes de LIKE.
- Receita mensal, posição financeira, estornos, crédito, cobrança, ranking, acumulado e divisão por zero.
- Preservação dos clientes sem pedidos; comportamento de NOT IN com NULL; soma inflada por cardinalidade; equivalência LATERAL/janela e reconciliação das três divergências simuladas.
- Todos os indicadores comerciais de 04_Conferencias.sql, incluindo 15 itens e totais 3060 contratado, 2730 recebido, 350 a receber e 20 em crédito.
- Geração dos 300 mil eventos; filtro combinado com 82 linhas, somente datas com 82000 e pendentes de março com 4000 antes do LIMIT.
- Execução de criação dos índices, estatísticas estendidas, CLUSTER e manutenção na cópia; estado final de 270000 linhas, 60000 revisadas e zero acima do limite de id.

O ambiente embutido permite validar execução SQL e resultados. **Não representa a VM Hyper-V nem a conexão do DBeaver e não valida desempenho, paralelismo, concorrência ou bloqueios entre múltiplas sessões nesse ambiente.** Tempos, scans e efeitos de cache devem ser coletados na VM. Os testes locais não são medições de desempenho para preencher seu relatório.

A versão HTML contém os 30 enunciados e as 30 soluções geradas a partir das fontes. Uma conferência de DOM verificou as contagens, unicidade dos identificadores, âncoras internas, existência dos destinos dos links locais e preservação das 100 questões no HTML do nível 1. Não foi realizada inspeção visual em navegador.

Os arquivos do nível 1 permanecem como trilha inicial; suas alterações nesta edição se limitam aos links e à identificação da nova trilha.

Na revisão didática, os 30 enunciados receberam contexto, objetivo, dados de partida, passos, dica e conferência. Foram verificados os seis componentes em cada tarefa, a numeração dos passos no HTML e a correspondência das 30 soluções incorporadas com o arquivo SQL. Os preparadores, soluções SQL e resultados esperados não foram alterados nessa revisão; não foram repetidas medições de desempenho.

Na revisão de apresentação dos passos, foram conferidas 30 seções HTML details, inicialmente fechadas, com o controle Ver passo a passo e as listas numeradas preservadas. As 30 soluções continuam em seções recolhidas separadas.

A apresentação também recolhe as 30 dicas e as 30 conferências em controles independentes. Foram conferidos o estado inicialmente fechado, uma seção de cada tipo por exercício e a preservação dos textos e das soluções.

Foram acrescentadas 30 soluções expansíveis junto aos exercícios, geradas dos mesmos blocos SQL da coleção final. A conferência de DOM verifica uma solução fechada por exercício, o vínculo correto pelo identificador e a igualdade com o SQL de origem.

Nesta edição, a primeira consulta de 04_Conferencias.sql passou de 12 para 26 conferências: entraram os resultados citados em N2-2.2, N2-2.3, N2-2.4, N2-3.1, N2-4.1 e N2-4.2. O nível 1 ganhou 08_Conferencias.sql, com 26 conferências da carga e das soluções dos capítulos 3 a 6 e outras 4 do Lab11. Em PostgreSQL 18.6 via PGlite 0.5.10, os preparadores e as soluções completas dos dois níveis e do extra de regex foram executados comando a comando, incluindo as tentativas de erro comentadas e o VACUUM FULL opcional. As conferências rodaram nos pontos previstos: no nível 1, após L3 a L6, antes de L11.6 e no final; no nível 2, após N2-1 a N2-4, com N2-1.5 repetido, e no final. Foram 131 verificações sem falhas, e os únicos erros foram os esperados: 23505 em L11.4 e 23514, 23505, 23503 e 23514 em N2-1.1 e N2-1.3. Em PostgreSQL 16.4 (PGlite 0.2.17), uma cópia com o preço do Mouse e o valor de um pedido alterados fez as conferências acusarem as diferenças.
