$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
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
foreach ($line in [IO.File]::ReadAllLines((Join-Path $base '01_Laboratorio_Regex.md'), [Text.Encoding]::UTF8)) {
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
        if ($title -match '^(RX-\d{2}) ') { $anchor=' id="'+$Matches[1]+'"' }
        $body.Add('<h'+$level+$anchor+'>'+(Inline $title)+'</h'+$level+'>')
    } elseif ($line -match '^(?:- |\d+\. )(.+)$') {
        if (-not $inList) { $inList=$nextList; $body.Add('<'+$inList+'>') }
        $body.Add('<li>'+(Inline $Matches[1])+'</li>')
    } elseif ($line.Trim()) { $body.Add('<p>'+(Inline $line)+'</p>') }
}
if ($inList) { $body.Add('</'+$inList+'>') }
if ($inTable) { $body.Add('</tbody></table></div>') }
$body.Add('<h2 id="solucoes">Soluções comentadas — consulte após tentar</h2><p>Abra somente a tarefa que está corrigindo. Todos os exemplos usam somente SELECT. Compare com sua tentativa antes de executar.</p>')
$solutions = [IO.File]::ReadAllText((Join-Path $base '02_Solucoes_Regex.sql'), [Text.Encoding]::UTF8)
$blocks = [regex]::Matches($solutions, '(?ms)^-- (RX-\d{2}):.*?(?=^-- RX-\d{2}:|\z)')
if ($blocks.Count -ne 12) { throw 'Esperados 12 blocos de soluções.' }
foreach ($block in $blocks) {
    $body.Add('<details><summary>Solução '+$block.Groups[1].Value+'</summary><pre><code>'+
    [Net.WebUtility]::HtmlEncode($block.Value.Trim())+'</code></pre></details>')
}
$body.Add('</main>')
$head = @'
<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>BDLab10 — Extra de expressões regulares POSIX</title>
<style>
:root{color-scheme:dark;background:#0d1117;color:#e6edf3}*{box-sizing:border-box}body{font:16px/1.7 "Segoe UI",Arial,sans-serif;max-width:1100px;margin:0 auto;padding:28px}a{color:#8dcaff}a:focus-visible,summary:focus-visible{outline:3px solid #8dcaff;outline-offset:4px}nav{padding:18px;border:1px solid #364456;border-radius:10px;background:#182230;display:flex;flex-wrap:wrap;gap:12px 20px}h1{font-size:2rem}h1,h2,h3{color:#a6d5ff;line-height:1.35}h2{margin-top:2.5em;border-top:1px solid #364456;padding-top:24px}h3{margin-top:2em;scroll-margin-top:20px}p,li{max-width:95ch}li{margin:10px 0}code{font-family:Consolas,monospace;background:#203149;padding:2px 4px;border-radius:3px}pre{background:#161f2b;border:1px solid #364456;padding:18px;overflow:auto;font-size:14px;line-height:1.6}pre code{padding:0;background:transparent}.table-wrap{overflow:auto}table{border-collapse:collapse;width:100%;font-size:14px}th,td{border:1px solid #364456;padding:10px;text-align:left}th{background:#203149}details{margin:16px 0;border:1px solid #364456;border-radius:8px;padding:14px}summary{cursor:pointer;color:#a6d5ff;font-weight:600}.intro{padding:16px;border-left:4px solid #8dcaff;background:#182230}footer{margin-top:40px;color:#b4c0cf}@media(max-width:600px){body{padding:16px}h1{font-size:1.6rem}}@media print{:root{color-scheme:light;background:white;color:black}body{max-width:none;padding:0;font-size:10pt}nav{display:none}h1,h2,h3,a,summary{color:#163b59}h2,h3{break-after:avoid}pre,code,th,.intro{background:#f0f3f6;color:black}pre{white-space:pre-wrap;overflow-wrap:anywhere}details{break-inside:avoid}a{overflow-wrap:anywhere}@page{size:A4;margin:18mm}}
</style></head><body>
<nav aria-label="Navegação do laboratório"><a href="#RX-01">1–3 · Fundamentos</a><a href="#RX-04">4–6 · Validação</a><a href="#RX-07">7–10 · Transformação</a><a href="#RX-11">11–12 · Diagnóstico</a><a href="#solucoes">Soluções</a><a href="../Laboratorios_Nivel2.html#N2-1.4">Voltar ao N2-1.4</a></nav>
<p class="intro">Extra do nível 2 · 12 exercícios · DBeaver no Windows + PostgreSQL na VM. Abra o preparador uma vez; os exercícios são somente leitura. As quatro ajudas de cada exercício começam recolhidas. Esta página funciona offline e não executa SQL nem salva progresso.</p>
'@
$renderedBody = $body -join "`n"
$stepsPattern = '(?s)<p><strong>Passo a passo:</strong></p>\s*(<ol>.*?</ol>)'
if ([regex]::Matches($renderedBody, $stepsPattern).Count -ne 12) {
    throw 'Esperados 12 passos a passo para recolher.'
}
$renderedBody = [regex]::Replace($renderedBody, $stepsPattern,
    '<details class="passo-a-passo"><summary>Ver passo a passo</summary>$1</details>')
foreach ($section in @(
    @{ Label='Dica para começar:'; Class='dica'; Summary='Ver dica para começar' },
    @{ Label='Como conferir seu resultado:'; Class='conferencia'; Summary='Ver como conferir seu resultado' }
)) {
    $pattern = '(?s)<p><strong>' + [regex]::Escape((Inline $section.Label)) + '</strong>\s*(.*?)</p>'
    if ([regex]::Matches($renderedBody, $pattern).Count -ne 12) {
        throw ('Esperadas 12 seções: ' + $section.Label)
    }
    $replacement = '<details class="' + $section.Class + '"><summary>' +
        (Inline $section.Summary) + '</summary><p>$1</p></details>'
    $renderedBody = [regex]::Replace($renderedBody, $pattern, $replacement)
}
$solutionsById = @{}
foreach ($block in $blocks) {
    $solutionsById[$block.Groups[1].Value] = $block.Value.Trim()
}
$exercisePattern = '(?ms)(<h3 id="(RX-\d{2})">.*?)(?=<h[23]\b|</main>)'
if ([regex]::Matches($renderedBody, $exercisePattern).Count -ne 12) {
    throw 'Esperados 12 exercícios para incorporar soluções.'
}
$renderedBody = [regex]::Replace($renderedBody, $exercisePattern,
    [Text.RegularExpressions.MatchEvaluator]{ param($match)
        $id = $match.Groups[2].Value
        if (-not $solutionsById.ContainsKey($id)) { throw ('Solução ausente: ' + $id) }
        return $match.Groups[1].Value +
            '<details class="solucao-exercicio" id="solucao-' + $id + '">' +
            '<summary>Ver uma solução possível — ' + $id + '</summary>' +
            '<p>Esta é uma forma de resolver o exercício; outras consultas podem atender às mesmas regras. ' +
            'Execute no banco em que preparou o schema <code>bdadosql_regex</code>. ' +
            'As consultas são somente leitura e podem ser repetidas. ' +
            'Os resultados esperados pressupõem a carga original de 12 contatos.</p><pre><code>' +
            [Net.WebUtility]::HtmlEncode($solutionsById[$id]) + '</code></pre></details>' + "`n"
    })
$html = $head + "`n" + $renderedBody + '<footer>BDLab10 · Extra POSIX · Fonte editável: 01_Laboratorio_Regex.md · Veja VALIDACAO.md para as conferências realizadas.</footer></body></html>'
[IO.File]::WriteAllText((Join-Path $base 'Laboratorio_Regex_POSIX.html'), $html, [Text.UTF8Encoding]::new($false))
Write-Output 'Gerado: Laboratorio_Regex_POSIX.html (12 exercícios e 12 soluções).'
