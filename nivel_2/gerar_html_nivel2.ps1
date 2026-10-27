# Gera o HTML do nível 2; o extra de regex chama este script com os próprios parâmetros.
param(
    [string]$Pasta = $PSScriptRoot,
    [string]$Fonte = '01_Laboratorios_Nivel2.md',
    [string]$Solucoes = '03_Solucoes_Nivel2.sql',
    [string]$Saida = 'Laboratorios_Nivel2.html',
    [string]$IdTitulo = 'N2-\d+(?:\.\d+)?',
    [string]$IdExercicio = 'N2-\d+\.\d+',
    [int]$Total = 30,
    [string]$Titulo = 'BDLab10 — Laboratórios de nível 2',
    [string]$Nav = '<nav aria-label="Navegação dos laboratórios"><a href="#N2-1">1 · Transações</a><a href="#N2-2">2 · Filtros</a><a href="#N2-3">3 · Relatórios</a><a href="#N2-4">4 · Junções</a><a href="#N2-5">5 · Desempenho</a><a href="#solucoes">Soluções</a><a href="extra_regex_posix/Laboratorio_Regex_POSIX.html">Extra · Regex POSIX</a><a href="../Questionario_Multipla_Escolha.html">Nível 1</a></nav>',
    [string]$Intro = 'Trilha prática · 5 laboratórios · 30 desafios · DBeaver no Windows + PostgreSQL na VM. Esta página funciona offline após baixar e extrair o repositório. Salve SQL e evidências em arquivos próprios; esta página não executa SQL nem salva progresso. Em cada exercício, passo a passo, dica, conferência e solução começam recolhidos; as soluções também estão reunidas no final.',
    [string]$AvisoSolucoes = 'Abra somente a tarefa que está corrigindo. Não execute o arquivo completo de soluções. Os erros intencionais estão comentados; execute-os separadamente.',
    [string]$AvisoSolucao = 'Use a sessão com <code>SET search_path TO bdadosql_n2, public;</code> já configurado. Execute por etapas: as tentativas que devem gerar erro estão comentadas e precisam ser executadas separadamente. Confira o estado atual antes de repetir alterações ou criar objetos.',
    [string]$Rodape = 'BDLab10 · Nível 2 · Fonte editável: 01_Laboratorios_Nivel2.md · Veja VALIDACAO.md para os checks realizados.',
    [string]$ScriptCopia = '../copiar_codigo.js'
)
$ErrorActionPreference = 'Stop'
function Inline([string]$value) {
    $encoded = [Net.WebUtility]::HtmlEncode($value)
    $encoded = [regex]::Replace($encoded, '`([^`]+)`', '<code>$1</code>')
    $encoded = [regex]::Replace($encoded, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
    return [regex]::Replace($encoded, '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>')
}
$body = [Collections.Generic.List[string]]::new()
$body.Add('<main>')
$inCode = $false
$inTable = $false
$inList = ''
foreach ($line in [IO.File]::ReadAllLines((Join-Path $Pasta $Fonte),[Text.Encoding]::UTF8)) {
    if ($line.StartsWith('```')) {
        if ($inCode) { $body.Add('</code></pre>') } else { $body.Add('<pre><code>') }
        $inCode = -not $inCode
        continue
    }
    if ($inCode) { $body.Add([Net.WebUtility]::HtmlEncode($line)); continue }
    $nextList = ''
    if ($line -match '^\d+\. ') { $nextList = 'ol' }
    elseif ($line.StartsWith('- ')) { $nextList = 'ul' }
    if ($inList -and $inList -ne $nextList) { $body.Add('</'+$inList+'>'); $inList='' }
    if ($inTable -and -not $line.StartsWith('|')) { $body.Add('</tbody></table></div>'); $inTable=$false }
    if ($line.StartsWith('|')) {
        if ($line -match '^\|[-| ]+\|$') { continue }
        $cells = $line.Trim().Trim('|').Split('|')
        if (-not $inTable) {
            $body.Add('<div class="table-wrap"><table><thead><tr>')
            foreach ($cell in $cells) { $body.Add('<th scope="col">' + (Inline $cell.Trim()) + '</th>') }
            $body.Add('</tr></thead><tbody>'); $inTable=$true
        } else {
            $body.Add('<tr>')
            foreach ($cell in $cells) { $body.Add('<td>' + (Inline $cell.Trim()) + '</td>') }
            $body.Add('</tr>')
        }
    } elseif ($line -match '^(#{1,3}) (.+)$') {
        $level = $Matches[1].Length; $title = $Matches[2]; $anchor=''
        if ($title -match ('^(' + $IdTitulo + ') ')) { $anchor=' id="'+$Matches[1]+'"' }
        $body.Add('<h'+$level+$anchor+'>'+(Inline $title)+'</h'+$level+'>')
    } elseif ($line -match '^(?:- |\d+\. )(.+)$') {
        if (-not $inList) { $inList=$nextList; $body.Add('<'+$inList+'>') }
        $body.Add('<li>'+(Inline $Matches[1])+'</li>')
    } elseif ($line.Trim()) { $body.Add('<p>'+(Inline $line)+'</p>') }
}
if ($inList) { $body.Add('</'+$inList+'>') }
if ($inTable) { $body.Add('</tbody></table></div>') }
$body.Add('<h2 id="solucoes">Soluções comentadas — consulte após tentar</h2><p>' + $AvisoSolucoes + '</p>')
$solutions = [IO.File]::ReadAllText((Join-Path $Pasta $Solucoes), [Text.Encoding]::UTF8)
$blocks = [regex]::Matches($solutions, '(?ms)^-- (' + $IdExercicio + '):.*?(?=^-- ' + $IdExercicio + ':|\z)')
if ($blocks.Count -ne $Total) { throw "Esperados $Total blocos de soluções." }
foreach ($block in $blocks) {
    $body.Add('<details><summary>Solução '+$block.Groups[1].Value+'</summary><pre><code>'+
    [Net.WebUtility]::HtmlEncode($block.Value.Trim())+'</code></pre></details>')
}
$body.Add('</main>')
$head = @'
<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{{TITULO}}</title>
<style>
:root{color-scheme:dark;background:#0d1117;color:#e6edf3}*{box-sizing:border-box}body{font:16px/1.7 "Segoe UI",Arial,sans-serif;max-width:1100px;margin:0 auto;padding:28px}a{color:#8dcaff}a:focus-visible,summary:focus-visible{outline:3px solid #8dcaff;outline-offset:4px}nav{padding:18px;border:1px solid #364456;border-radius:10px;background:#182230;display:flex;flex-wrap:wrap;gap:12px 20px}h1{font-size:2rem}h1,h2,h3{color:#a6d5ff;line-height:1.35}h2{margin-top:2.5em;border-top:1px solid #364456;padding-top:24px}h3{margin-top:2em;scroll-margin-top:20px}p,li{max-width:95ch}li{margin:10px 0}code{font-family:Consolas,monospace;background:#203149;padding:2px 4px;border-radius:3px}pre{background:#161f2b;border:1px solid #364456;padding:18px;overflow:auto;font-size:14px;line-height:1.6}pre code{padding:0;background:transparent}.table-wrap{overflow:auto}table{border-collapse:collapse;width:100%;font-size:14px}th,td{border:1px solid #364456;padding:10px;text-align:left}th{background:#203149}details{margin:16px 0;border:1px solid #364456;border-radius:8px;padding:14px}summary{cursor:pointer;color:#a6d5ff;font-weight:600}.intro{padding:16px;border-left:4px solid #8dcaff;background:#182230}footer{margin-top:40px;color:#b4c0cf}@media(max-width:600px){body{padding:16px}h1{font-size:1.6rem}}@media print{:root{color-scheme:light;background:white;color:black}body{max-width:none;padding:0;font-size:10pt}nav{display:none}h1,h2,h3,a,summary{color:#163b59}h2,h3{break-after:avoid}pre,code,th,.intro{background:#f0f3f6;color:black}pre{white-space:pre-wrap;overflow-wrap:anywhere}details{break-inside:avoid}a{overflow-wrap:anywhere}@page{size:A4;margin:18mm}}
</style></head><body>
{{NAV}}
'@
$head = $head.Replace('{{TITULO}}', $Titulo).Replace('{{NAV}}', $Nav)
$renderedBody = ($body -join "`n").Replace("<pre><code>`n", '<pre><code>')
$renderedBody = ([regex]'</h1>').Replace($renderedBody, "</h1>`n" + '<p class="intro">' + $Intro + '</p>', 1)
$stepsPattern = '(?s)<p><strong>Passo a passo:</strong></p>\s*(<ol>.*?</ol>)'
if ([regex]::Matches($renderedBody, $stepsPattern).Count -ne $Total) {
    throw "Esperados $Total passos a passo para recolher."
}
$renderedBody = [regex]::Replace($renderedBody, $stepsPattern,
    '<details class="passo-a-passo"><summary>Ver passo a passo</summary>$1</details>')
foreach ($section in @(
    @{ Label='Dica para começar:'; Class='dica'; Summary='Ver dica para começar' },
    @{ Label='Como conferir seu resultado:'; Class='conferencia'; Summary='Ver como conferir seu resultado' }
)) {
    $pattern = '(?s)<p><strong>' + [regex]::Escape((Inline $section.Label)) + '</strong>\s*(.*?)</p>'
    if ([regex]::Matches($renderedBody, $pattern).Count -ne $Total) {
        throw ("Esperadas $Total seções: " + $section.Label)
    }
    $replacement = '<details class="' + $section.Class + '"><summary>' +
        (Inline $section.Summary) + '</summary><p>$1</p></details>'
    $renderedBody = [regex]::Replace($renderedBody, $pattern, $replacement)
}
$solutionsById = @{}
foreach ($block in $blocks) {
    $solutionsById[$block.Groups[1].Value] = $block.Value.Trim()
}
$exercisePattern = '(?ms)(<h3 id="(' + $IdExercicio + ')">.*?)(?=<h[23]\b|</main>)'
if ([regex]::Matches($renderedBody, $exercisePattern).Count -ne $Total) {
    throw "Esperados $Total exercícios para incorporar soluções."
}
$renderedBody = [regex]::Replace($renderedBody, $exercisePattern,
    [Text.RegularExpressions.MatchEvaluator]{ param($match)
        $id = $match.Groups[2].Value
        if (-not $solutionsById.ContainsKey($id)) { throw ('Solução ausente: ' + $id) }
        return $match.Groups[1].Value +
            '<details class="solucao-exercicio" id="solucao-' + $id + '">' +
            '<summary>Ver uma solução possível — ' + $id + '</summary>' +
            '<p>Esta é uma forma de resolver o exercício; outras consultas podem atender às mesmas regras. ' +
            $AvisoSolucao + '</p><pre><code>' +
            [Net.WebUtility]::HtmlEncode($solutionsById[$id]) + '</code></pre></details>' + "`n"
    })
$html = $head + "`n" + $renderedBody + '<footer>' + $Rodape + '</footer>' + "`n" +
    '<script src="' + $ScriptCopia + '"></script>' + "`n</body></html>"
[IO.File]::WriteAllText((Join-Path $Pasta $Saida), $html, [Text.UTF8Encoding]::new($false))
Write-Output "Gerado: $Saida ($Total exercícios e $Total soluções)."
