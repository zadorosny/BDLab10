# BDLab10 — Nível 2

Esta trilha continua o nível 1 com **30 desafios distribuídos em cinco laboratórios**. Os problemas exigem escrever SQL, conferir resultados e justificar decisões com evidências.

| Laboratório | Tema | Desafios |
|---|---|---:|
| N2-1 | Integridade, transações, SAVEPOINT, importação e UPSERT | 6 |
| N2-2 | Filtros, NULL, texto literal e datas com fuso horário | 6 |
| N2-3 | Relatórios financeiros, créditos, ranking e acumulados | 6 |
| N2-4 | Ausência de registros, cardinalidade e reconciliação | 6 |
| N2-5 | Índices compostos, parciais e de expressão; estatísticas e manutenção | 6 |

No Windows, baixe e extraia o repositório; abra **Laboratorios_Nivel2.html** no navegador. No GitHub, leia o mesmo conteúdo em [01_Laboratorios_Nivel2.md](01_Laboratorios_Nivel2.md). Os exercícios são executados pelo DBeaver conectado ao PostgreSQL da VM; não é necessário WSL nem Bash.

1. Confirme o banco de treinamento no DBeaver.
2. Execute [00_Preparacao_Nivel2.sql](00_Preparacao_Nivel2.sql) **uma vez**. Ele cria o schema independente `bdadosql_n2`. Não precisa executar os preparadores do nível 1.
3. Em cada nova sessão, execute `SET search_path TO bdadosql_n2, public;`.
4. Siga os laboratórios na ordem. Salve tentativas e evidências em arquivos pessoais. Os testes transacionais terminam em ROLLBACK, conforme os enunciados.
5. Ao chegar ao N2-5, execute [02_Preparacao_Desempenho.sql](02_Preparacao_Desempenho.sql) **uma vez**, antes de criar qualquer índice de desempenho.
6. Consulte [03_Solucoes_Nivel2.sql](03_Solucoes_Nivel2.sql) somente depois de tentar, por tarefa. Não execute o arquivo inteiro.
7. Use [04_Conferencias.sql](04_Conferencias.sql) para conferir as invariantes comerciais. O segundo resultado, de contatos, pressupõe concluir N2-1.5.

Para repetir a trilha, prefira outro banco de treinamento. Os preparadores não apagam objetos nem reiniciam automaticamente um schema existente.

O HTML é gerado a partir do roteiro e das soluções por `gerar_html_nivel2.ps1`, executável no PowerShell do Windows. Você só precisa desse gerador se editar o material; para estudar, abra o HTML já incluído.

Consulte [VALIDACAO.md](VALIDACAO.md) para o que foi testado. O livro não está incluído. Os recursos adicionais do nível 2 vão além do recorte original dos capítulos; referências oficiais estão no roteiro.
