# Extra — Expressões regulares POSIX

São **12 exercícios** sobre busca, âncoras, classes POSIX, repetições, grupos, limpeza, extração e diagnóstico de dados. Cada tarefa apresenta contexto, objetivo e dados de partida. No HTML, passo a passo, dica, conferência e solução ficam em quatro seções expansíveis, fechadas inicialmente.

1. Abra [Laboratorio_Regex_POSIX.html](Laboratorio_Regex_POSIX.html) no navegador após baixar e extrair o repositório.
2. No DBeaver conectado ao PostgreSQL 18 da VM, execute [00_Preparacao_Regex.sql](00_Preparacao_Regex.sql) uma vez no banco de treinamento.
3. Confira as **12 linhas** em `bdadosql_regex.importacao_contatos`.
4. Faça RX-01 a RX-12 em ordem. Os exercícios usam somente SELECT; os dados originais permanecem disponíveis para conferência.
5. Consulte [02_Solucoes_Regex.sql](02_Solucoes_Regex.sql) por exercício, depois de tentar.

O extra tem carga independente e pode ser feito após N2-1.4. Não precisa reiniciar os outros laboratórios. No GitHub, leia o [roteiro em Markdown](01_Laboratorio_Regex.md); para estudar com as ajudas recolhidas, abra o HTML local.

| Arquivo | Função |
|---|---|
| 00_Preparacao_Regex.sql | Criar o schema e o lote fictício uma vez |
| 01_Laboratorio_Regex.md | Fonte dos enunciados, explicações e conferências |
| 02_Solucoes_Regex.sql | Soluções comentadas, todas de leitura |
| Laboratorio_Regex_POSIX.html | Roteiro offline com ajudas expansíveis |
| gerar_html_regex.ps1 | Regenerar o HTML pelo PowerShell, caso edite as fontes |
| VALIDACAO.md | Registrar o que foi executado e conferido |

Para estudar, não é necessário executar o gerador, instalar WSL nem usar arquivos .sh. O HTML não executa SQL nem salva progresso. Salve suas tentativas e evidências em arquivos próprios.

Consulte a [documentação oficial de regex POSIX no PostgreSQL 18](https://www.postgresql.org/docs/18/functions-matching.html#FUNCTIONS-POSIX-REGEXP) e volte ao [guia do nível 2](../README.md) quando concluir.
