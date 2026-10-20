# Validação do extra POSIX

O preparador e os **12 blocos de soluções** foram executados em PostgreSQL 18.6 via PGlite 0.5.10, com Node.js 24.22.0, em um banco temporário. Passaram **36 conferências SQL**.

Foram conferidos:

- A carga de 12 contatos e sua preservação depois de todas as soluções.
- As diferenças entre busca sensível ou insensível a caixa, negação, trecho, início e primeiro nome.
- Espaços, tabulações, quebras de linha e quantificadores diante de texto vazio.
- Emails originais e normalizados, ausência, comportamento de NULL e o caso que revela a limitação do filtro.
- UFs permitidas, agrupamento de alternativas, prefixos, sufixos, tamanho dos códigos e hífen opcional.
- Substituição da primeira ocorrência ou de todas, mantendo os nomes esperados.
- Classificação de telefones pelo original e pelos dígitos, incluindo a letra indevida e o código do país.
- Extração de domínios, arrays de grupos e remontagem dos cinco telefones selecionados.
- Diferença entre regexp_match e regexp_matches: expansão de ocorrências e ausência de linha sem correspondência.
- O relatório final: 5 emails no formato, 2 ausentes, 5 fora; 2 UFs e 3 códigos rejeitados; 6 contatos que passam nas três regras combinadas.

A conferência estrutural do HTML verifica os 12 exercícios, as 48 ajudas locais inicialmente fechadas, as 12 soluções agrupadas no final, a correspondência exata entre SQL incorporado e arquivo de soluções, identificadores únicos, links locais e âncoras HTML. Também verifica a preservação de caracteres dos padrões. O HTML principal do nível 2 foi regenerado e suas 30 soluções e ajudas foram conferidas.

O ambiente PGlite executa PostgreSQL em WebAssembly. Essa validação confirma os resultados nessa carga, mas não substitui uma execução na VM pelo DBeaver. Não foram feitas medições de desempenho nem inspeção visual em navegador. Os exercícios de dígitos com regra ASCII explicitam COLLATE "C"; classes de caracteres em outros dados e configurações podem depender da locale.

As soluções usam somente leitura. Não houve conexão nem alteração no banco do usuário.
