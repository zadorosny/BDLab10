$ErrorActionPreference = 'Stop'
$parametros = @{
    Pasta = $PSScriptRoot
    Fonte = '01_Laboratorio_Regex.md'
    Solucoes = '02_Solucoes_Regex.sql'
    Saida = 'Laboratorio_Regex_POSIX.html'
    IdTitulo = 'RX-\d{2}'
    IdExercicio = 'RX-\d{2}'
    Total = 12
    Titulo = 'BDLab10 — Extra de expressões regulares POSIX'
    Nav = '<nav aria-label="Navegação do laboratório"><a href="#RX-01">1–3 · Fundamentos</a><a href="#RX-04">4–6 · Validação</a><a href="#RX-07">7–10 · Transformação</a><a href="#RX-11">11–12 · Diagnóstico</a><a href="#solucoes">Soluções</a><a href="../Laboratorios_Nivel2.html#N2-1.4">Voltar ao N2-1.4</a></nav>'
    Intro = 'Extra do nível 2 · 12 exercícios · DBeaver no Windows + PostgreSQL na VM. Execute o preparador uma única vez; depois, os exercícios usam somente SELECT. Em cada exercício, passo a passo, dica, conferência e solução começam recolhidos. Esta página funciona offline e não executa SQL nem salva progresso.'
    AvisoSolucoes = 'Abra somente a tarefa que está corrigindo. Todos os exemplos usam somente SELECT. Compare com sua tentativa antes de executar.'
    AvisoSolucao = 'Execute no banco em que preparou o schema <code>bdadosql_regex</code>. As consultas são somente leitura e podem ser repetidas. Os resultados esperados pressupõem a carga original de 12 contatos.'
    Rodape = 'BDLab10 · Extra POSIX · Fonte editável: 01_Laboratorio_Regex.md · Veja VALIDACAO.md para as conferências realizadas.'
    ScriptCopia = '../../copiar_codigo.js'
}
& (Join-Path $PSScriptRoot '../gerar_html_nivel2.ps1') @parametros
