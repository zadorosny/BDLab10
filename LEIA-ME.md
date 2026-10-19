# Como estudar e executar os laboratórios pelo DBeaver

**Esta é a trilha de nível 1**: 100 questões e 40 tarefas. Para continuar com problemas mais difíceis, use o [guia do nível 2](nivel_2/README.md) ou abra `nivel_2/Laboratorios_Nivel2.html`. O nível 2 oferece 30 desafios e preparação independente no schema bdadosql_n2.


O DBeaver fica no Windows e envia os comandos SQL ao PostgreSQL instalado na VM Ubuntu do Hyper-V. Os arquivos HTML e SQL permanecem no Windows. Não é necessário WSL nem copiar arquivos para a VM. O HTML apresenta os exercícios; a execução dos laboratórios acontece no DBeaver.

## 1. Organize os arquivos

Abra Questionario_Multipla_Escolha.html no navegador: são 100 questões, 20 por capítulo, e 40 tarefas práticas. Abra também PG_BruceMomjian.pdf, na pasta acima. Crie uma pasta pessoal de entregas, com um arquivo de respostas e um arquivo SQL por capítulo, por exemplo capitulo_03_respostas.md e capitulo_03_pratica.sql. Preserve os arquivos originais de preparação e soluções.

## 2. Ligue a VM e confira a conexão

Inicie a VM Ubuntu pelo Hyper-V e verifique se o PostgreSQL está em execução. Identifique o IP da VM (no terminal Ubuntu, hostname -I) e a porta do cluster PostgreSQL que será usado. A porta usual é 5432, mas confirme a porta real. Windows e VM precisam ter comunicação pela rede virtual do Hyper-V.

No DBeaver do Windows, crie uma conexão do tipo PostgreSQL. Informe o IP da VM em Host, a porta do cluster, um banco existente de manutenção (por exemplo postgres), o usuário PostgreSQL e a senha desse usuário. A senha do PostgreSQL não é necessariamente a senha de acesso ao Ubuntu. Teste a conexão; se o DBeaver solicitar o driver PostgreSQL, permita o download e teste novamente. localhost aponta para o Windows quando usado nesse campo; use o IP da VM para a conexão direta.

Se já existe uma conexão funcional com essa VM no DBeaver, reutilize os dados dela. Em caso de timeout ou conexão recusada, confira IP, rede do Hyper-V, serviço, porta, listen_addresses e firewall. Em caso de falha de autenticação, confira usuário, senha e a regra correspondente em pg_hba.conf. O servidor precisa aceitar o IP do Windows; peça ao responsável pela VM para configurar esse acesso, caso necessário. Não abra acesso irrestrito para resolver o problema.

## 3. Crie ou escolha um banco exclusivo de treinamento

Use um banco descartável exclusivo para estes exercícios. Se ainda não existir e seu usuário tiver permissão CREATEDB, abra um editor SQL associado à conexão de manutenção, ative Auto-commit e execute somente este comando, fora de BEGIN:

```sql
CREATE DATABASE bdadosql_estudo;
```

Depois, crie ou edite uma conexão do DBeaver para que o campo Database seja bdadosql_estudo. Abrir um editor na conexão antiga não muda automaticamente o banco. Se você não tiver permissão, solicite um banco de treinamento ao responsável e conecte-se a ele. Não repita CREATE DATABASE se o banco já foi criado. bdadosql_estudo é o banco; bdadosql será o schema dentro dele.

No editor que será usado para os laboratórios, execute:

```sql
SELECT current_database() AS banco, current_user AS usuario, version() AS versao;
```

Confira se o banco retornado é o de treinamento. O material foi preparado para PostgreSQL moderno; use preferencialmente PostgreSQL 18, com usuário que possa criar e alterar seus próprios objetos. Os SQLs serão executados no servidor da VM, mesmo que você os edite no Windows.

## 4. Prepare os dados uma única vez

Abra 00_preparacao.sql no editor SQL do DBeaver e associe o editor à conexão do banco de treinamento. Confira a conexão ativa na barra do editor antes de executar. Use a ação Executar script SQL para executar o arquivo inteiro em sequência; executar apenas a instrução sob o cursor não prepara toda a base. Mantenha Auto-commit ativo e deixe o BEGIN/COMMIT do próprio arquivo controlar essa preparação.

O resultado final deve mostrar clientes = 6, vendedores = 2, produtos = 5, pedidos = 8 e itens = 10. Atualize o navegador de objetos do DBeaver para visualizar o schema bdadosql. A criação e a carga são manuais, por esse SQL; não há menu de laboratório nem preparação automática.

Se ocorrer erro, interrompa a execução e confira a causa. Se a transação ficar abortada, execute ROLLBACK antes de continuar. Se o schema já existir, confira se a preparação anterior foi concluída. Não execute a carga novamente a cada sessão: ela não foi feita para repetição. Para recomeçar do zero, prefira outro banco de treinamento.

## 5. Configure cada editor ou nova sessão

Antes das tarefas, no mesmo editor/conexão que vai executá-las, rode:

```sql
SET search_path TO bdadosql, public;
SELECT current_database() AS banco, current_schema() AS schema;
```

Confira o banco e o schema bdadosql. O search_path vale para a sessão: repita essa configuração ao abrir outra sessão ou reconectar. Coloque SET search_path no início de seus arquivos pessoais; a preparação inicial não precisa ser repetida. Você também pode qualificar nomes, por exemplo bdadosql.clientes.

## 6. Estude um capítulo por vez

Siga a ordem 3 → 4 → 5 → 6 → 11. No PDF, leia as páginas do arquivo: capítulo 3 = 39–50; capítulo 4 = 51–75; capítulo 5 = 77–83; capítulo 6 = 85–105; capítulo 11 = 159–164. São posições no PDF, não a numeração impressa. Consulte também as observações do roteiro sobre diferenças entre a edição histórica e o PostgreSQL atual.

Responda às 20 questões do capítulo no HTML, lendo o cenário de cada uma. Depois de tentar, clique em Corrigir capítulo para ver a nota e os comentários; cada acerto vale 0,5 ponto. Ocultar correção mantém as escolhas enquanto a página estiver aberta. As respostas não são salvas ao fechar ou recarregar: anote as alternativas, justificativas e notas ou imprima em PDF antes de sair. O questionário funciona offline; o laboratório precisa da conexão com a VM.

## 7. Execute as oito tarefas do capítulo no DBeaver

Leia o enunciado do laboratório no HTML e escreva sua tentativa no arquivo SQL pessoal. Identifique cada exercício com um comentário, por exemplo -- L3.1. Selecione apenas o comando ou bloco daquela tarefa e use Executar instrução SQL; para um conjunto de comandos selecionados, use a ação de executar script sobre a seleção. Confira a seleção e a conexão antes de executar. Não execute o arquivo inteiro de tentativas a cada nova tarefa.

Confira a grade de resultados, a quantidade de linhas afetadas e as mensagens do DBeaver. Guarde o SQL, o resultado obtido e uma explicação curta. Salve o arquivo SQL no disco do Windows e exporte resultados ou registre capturas quando necessário. A execução não possui correção automática dos laboratórios: compare suas evidências com o resultado esperado na solução.

No capítulo 3, você cria e altera contatos_lab3. O capítulo 4 usa config_lab4 para as demonstrações de escrita. Preserve os dados iniciais de clientes, vendedores, produtos, pedidos e itens, usados nos capítulos 4, 5 e 6. Antes de UPDATE ou DELETE, confira as linhas com SELECT usando o mesmo filtro. Com Auto-commit ativo, alterações bem-sucedidas são confirmadas imediatamente; ROLLBACK posterior não as desfaz.

## 8. Prepare e execute o capítulo 11 na ordem

Somente ao chegar ao capítulo 11, abra 02_Lab11_Preparacao.sql no mesmo banco e execute o script inteiro uma única vez. Confira 200000 linhas em bdadosql.eventos_lab11. Comece L11.1 antes de criar qualquer índice: essa medição é a referência sem índices. Siga L11.1 a L11.8 na sequência, pois as etapas criam índices e alteram os dados usados pelas seguintes.

Execute cada consulta de medição EXPLAIN (ANALYZE, BUFFERS) três vezes nas comparações indicadas. Salve os planos textuais completos, buffers, linhas estimadas/reais e tempos. EXPLAIN ANALYZE executa a consulta; diferencie o tempo do plano no servidor do tempo total exibido pelo cliente. Registre também versão do PostgreSQL e condições da VM; planos e tempos variam conforme recursos, cache e ambiente.

Em L11.4, a tentativa de inserir novamente o código 10 deve ser executada separadamente; o erro de chave duplicada (23505) é esperado. Na solução, essa instrução está comentada: copie-a para sua tentativa sem o marcador de comentário somente quando chegar nessa etapa. Não repita as inserções anteriores. Se estiver em uma transação manual e ela ficar abortada, use ROLLBACK e confira quais etapas foram desfeitas antes de continuar.

Execute cada VACUUM isoladamente, com Auto-commit ativo, sem BEGIN e sem transação pendente. Se houver uma transação aberta, conclua-a conscientemente com COMMIT ou ROLLBACK antes de executar VACUUM. Consulte a saída de mensagens para os detalhes de VERBOSE. Se ocorrer erro de execução dentro de bloco de transação, revise o modo de transação do editor.

## 9. Corrija depois de tentar

Para a teoria, use Corrigir capítulo no próprio HTML. Para a prática, abra 03_Solucoes_Laboratorios.sql e leia somente o bloco correspondente à tarefa, como L5.3. Não execute esse arquivo inteiro: ele cria objetos, altera dados e depende da ordem das atividades. Compare SQL, resultados e comentários; explique os erros e refaça apenas o necessário, verificando antes o que já foi executado.

04_Gabarito_Questionario.md e Gabarito_Questionario.html atendem às 50 questões discursivas da versão original. Para as 100 questões de múltipla escolha, a correção completa está no próprio Questionario_Multipla_Escolha.html.

## 10. Salve o progresso e retome

Ao encerrar, guarde as respostas e notas, os cinco arquivos SQL pessoais, resultados e o relatório de desempenho do capítulo 11. Anote o último exercício concluído, o banco usado, os scripts de preparação executados e os objetos já criados. Os arquivos pessoais não são salvos automaticamente por este material.

Na próxima sessão, ligue a VM, conecte o DBeaver, confirme current_database(), configure search_path e continue do exercício registrado. Não repita preparação, CREATE TABLE, CREATE INDEX ou alterações já concluídas sem conferir o estado. O estudo termina quando as 100 questões e as 40 tarefas estiverem feitas e revisadas. Reserve o tempo de leitura e prática, além de cerca de 40–60 minutos adicionais por capítulo para o questionário ampliado, ajustando ao seu ritmo.
