# Junta os arquivos do botão "Exportar respostas" e mede cada questão da múltipla escolha:
# acerto, discriminação (acerto do grupo superior menos o do inferior, por capítulo) e escolha de cada distrator.
param(
    [string]$Pasta = (Join-Path $PSScriptRoot 'respostas'),
    [string]$Saida = (Join-Path $PSScriptRoot 'analise_respostas.csv')
)
$ErrorActionPreference = 'Stop'
# Variáveis intermediárias: no PowerShell 5.1, @(... | ConvertFrom-Json) embrulharia o array inteiro em um elemento.
$main = Get-Content (Join-Path $PSScriptRoot '05_Questoes_Multipla_Escolha.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$additional = Get-Content (Join-Path $PSScriptRoot '06_Questoes_Adicionais.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$questions = @($main) + @($additional)
# Mesma conta de gerar_multipla_escolha.ps1: só junta respostas dadas ao mesmo texto das questões.
$sha = [Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes((($questions | ForEach-Object { $_.id + '|' + ($_.a -join '|') }) -join "`n")))
$version = -join ($sha[0..5] | ForEach-Object { $_.ToString('x2') })

if (-not (Test-Path $Pasta)) { throw "Pasta não encontrada: $Pasta. Coloque nela os arquivos respostas_*.json dos alunos." }
$valid = [Collections.Generic.List[object]]::new()
foreach ($file in Get-ChildItem $Pasta -Filter *.json) {
    try { $data = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { Write-Warning "$($file.Name): JSON inválido; ignorado."; continue }
    if ($data.formato -ne 'bdlab10-respostas-1') { Write-Warning "$($file.Name): não foi exportado pelo questionário; ignorado."; continue }
    if ($data.versao -ne $version) { Write-Warning "$($file.Name): respondido em outra versão das questões ($($data.versao), atual $version); ignorado."; continue }
    $valid.Add($data)
}
# O aluno pode exportar mais de uma vez: vale o arquivo mais recente de cada código.
$students = @($valid | Group-Object aluno | ForEach-Object {
    if ($_.Name -eq 'sem-codigo') { $_.Group }
    else {
        if ($_.Count -gt 1) { Write-Warning "Código $($_.Name) aparece em $($_.Count) arquivos; usado o mais recente." }
        $_.Group | Sort-Object exportado_em | Select-Object -Last 1
    }
})
if ($students.Count -eq 0) { throw "Nenhum arquivo válido em $Pasta." }

$pt = [Globalization.CultureInfo]::GetCultureInfo('pt-BR')
$short = { param($s) if ($s.Length -gt 60) { $s.Substring(0, 57) + '...' } else { $s } }
$rows = foreach ($chapter in 'C3', 'C4', 'C5', 'C6', 'C11') {
    $chapterQuestions = @($questions | Where-Object { $_.id -like "$chapter-*" })
    $answers = @(foreach ($s in $students) {
        $map = @{}
        foreach ($q in $chapterQuestions) {
            $v = $s.respostas.($q.id)
            $map[$q.id] = if ($null -ne $v -and "$v" -match '^[0-4]$') { [int]$v } else { $null }
        }
        if (@($map.Values | Where-Object { $null -ne $_ }).Count -gt 0) {
            [pscustomobject]@{ aluno = $s.aluno; map = $map; score =@($map.Values | Where-Object { $_ -eq 0 }).Count }
        }
    })
    $n = $answers.Count
    if ($n -eq 0) { continue }
    # shortcut: empates de pontuação na borda dos grupos são desfeitos pelo código do aluno; com turmas grandes o efeito some.
    $k = [Math]::Max(1, [Math]::Round(0.27 * $n))
    $ranked = @($answers | Sort-Object @{ Expression = 'score'; Descending = $true }, aluno)
    $upper = $ranked[0..($k - 1)]
    $lower = $ranked[($n - $k)..($n - 1)]
    foreach ($q in $chapterQuestions) {
        $count = 0..4 | ForEach-Object { $i = $_; @($answers | Where-Object { $_.map[$q.id] -eq $i }).Count }
        $blank = @($answers | Where-Object { $null -eq $_.map[$q.id] }).Count
        if (($count | Measure-Object -Sum).Sum + $blank -ne $n) { throw "Contagem inconsistente em $($q.id)." }
        $share = { param($group, $i) @($group | Where-Object { $_.map[$q.id] -eq $i }).Count / $group.Count }
        $p = $count[0] / $n
        $d = (& $share $upper 0) - (& $share $lower 0)
        $alerts = [Collections.Generic.List[string]]::new()
        if ($n -lt 10) { $alerts.Add('poucos alunos para medir (menos de 10)') }
        else {
            # Em questão fácil, distratores pouco marcados e discriminação baixa são esperados.
            if ($p -ge 0.9) { $alerts.Add('fácil demais') }
            else {
                if ($p -lt 0.3) { $alerts.Add('difícil demais ou ambígua') }
                if ($d -lt 0) { $alerts.Add('o grupo superior erra mais que o inferior: conferir o gabarito') }
                elseif ($d -lt 0.2) { $alerts.Add('não separa quem sabe de quem não sabe') }
                foreach ($i in 1..4) {
                    if ($count[$i] / $n -lt 0.05) { $alerts.Add("distrator $i quase ninguém marca ($(& $short $q.a[$i]))") }
                    if ((& $share $upper $i) -gt (& $share $upper 0)) { $alerts.Add("o grupo superior prefere o distrator $i ($(& $short $q.a[$i]))") }
                }
            }
        }
        $pct = { param($c) [int][Math]::Round(100 * $c / $n) }
        [pscustomobject][ordered]@{
            questao = $q.id; alunos = $n; acerto_pct = & $pct $count[0]; em_branco = $blank
            discriminacao = $d.ToString('0.00', $pt)
            d1_pct = & $pct $count[1]; d2_pct = & $pct $count[2]; d3_pct = & $pct $count[3]; d4_pct = & $pct $count[4]
            alertas = $alerts -join '; '; enunciado = $q.q
        }
    }
}
# Excel no Windows só reconhece os acentos do CSV com BOM.
$encoding = if ($PSVersionTable.PSVersion.Major -ge 6) { 'utf8BOM' } else { 'UTF8' }
$rows | Export-Csv $Saida -Delimiter ';' -NoTypeInformation -Encoding $encoding
$flagged = @($rows | Where-Object alertas)
Write-Output "Alunos: $($students.Count) (versão $version). Questões analisadas: $(@($rows).Count). Com alerta: $($flagged.Count)."
Write-Output "Tabela completa: $Saida"
$severity = { if ($_.alertas -match 'gabarito|prefere') { 0 } elseif ($_.alertas -match 'difícil|não separa') { 1 } else { 2 } }
$flagged | Sort-Object $severity, @{ Expression = { $_.alertas.Split(';').Count }; Descending = $true } | Select-Object -First 15 |
    Format-Table questao, alunos, acerto_pct, discriminacao, alertas -AutoSize -Wrap | Out-String -Width 220
