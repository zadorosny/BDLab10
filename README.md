# BDLab10

Material de estudo de PostgreSQL, com execução pelo DBeaver no Windows conectado ao PostgreSQL da VM Ubuntu no Hyper-V.

| Trilha | Conteúdo | Comece aqui |
|---|---|---|
| **Nível 1 — Fundamentos** | 100 questões e 40 tarefas dos temas dos capítulos 3, 4, 5, 6 e 11 de Bruce Momjian | [Guia do nível 1](LEIA-ME.md) |
| **Nível 2 — Problemas aplicados** | 30 desafios em 5 laboratórios: transações, filtros, relatórios financeiros, cardinalidade e desempenho | [Guia do nível 2](nivel_2/README.md) |
| **Extra — Regex POSIX** | 12 exercícios graduais de busca, validação de formato, limpeza, extração e diagnóstico | [Guia do extra](nivel_2/extra_regex_posix/README.md) |

Comece pelo [LEIA-ME.md](LEIA-ME.md), que explica a conexão do DBeaver no Windows ao PostgreSQL da VM Ubuntu no Hyper-V e a execução dos laboratórios.

Para usar o questionário interativo, baixe o repositório (Code → Download ZIP), extraia os arquivos e abra `Questionario_Multipla_Escolha.html` no navegador. A visualização de código do GitHub não executa o questionário.

Para o nível 2, abra `nivel_2/Laboratorios_Nivel2.html`: contém enunciados, resultados esperados e soluções recolhidas por tarefa. Use o preparador próprio do nível 2, que cria o schema `bdadosql_n2` e não depende do estado das tabelas do nível 1. Os SQLs são executados pelo DBeaver; o HTML é o roteiro de estudo.

Para praticar expressões regulares, abra `nivel_2/extra_regex_posix/Laboratorio_Regex_POSIX.html`. O extra tem sua própria preparação, com 12 contatos no schema `bdadosql_regex`, e pode ser feito após N2-1.4. Passos, dicas, conferências e soluções ficam recolhidos por exercício.

O livro `PG_BruceMomjian.pdf` não está incluído. Utilize sua própria cópia para acompanhar as referências de leitura.
