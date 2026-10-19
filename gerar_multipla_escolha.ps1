$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
$original = [IO.File]::ReadAllText((Join-Path $base 'Questionario_e_Laboratorios.html'), [Text.Encoding]::UTF8)
$questions = (Get-Content (Join-Path $base '05_Questoes_Multipla_Escolha.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
$additional = (Get-Content (Join-Path $base '06_Questoes_Adicionais.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
$contexts = (Get-Content (Join-Path $base '07_Contextos_Questoes.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
$questions = @($questions) + @($additional)
$answers = Get-Content (Join-Path $base '04_Gabarito_Questionario.md') -Encoding UTF8
$explanations = @{}
foreach ($line in $answers) {
    if ($line -match '^\d+\. \*\*(C\d+-Q\d+)\.\*\* (.+)$') { $explanations[$Matches[1]] = $Matches[2] }
}
foreach ($q in $additional) { $explanations[$q.id] = $q.explanation }
foreach ($q in $questions) {
    if (-not $q.context) {
        $contextProperty = $contexts.PSObject.Properties[$q.id]
        if (-not $contextProperty) { throw "Falta contexto para $($q.id)" }
        $q | Add-Member -NotePropertyName context -NotePropertyValue $contextProperty.Value
    }
}
function Encode([string]$text) { return [Net.WebUtility]::HtmlEncode($text) }
function Inline([string]$text) { return [regex]::Replace((Encode $text), '`([^`]+)`', '<code>$1</code>') }
function Shuffle($values, $rng) {
    $items = @($values)
    for ($i = $items.Count - 1; $i -gt 0; $i--) {
        $j = $rng.Next($i + 1); $swap = $items[$i]; $items[$i] = $items[$j]; $items[$j] = $swap
    }
    return $items
}
if ($questions.Count -ne 100 -or $explanations.Count -ne 100) { throw 'Esperadas 100 questões e 100 explicações.' }
if (@($questions.id | Select-Object -Unique).Count -ne 100) { throw 'IDs repetidos.' }
$rng = [Random]::new(20261016)
$blocks = [Collections.Generic.List[string]]::new()
foreach ($chapter in @(3,4,5,6,11)) {
    $chapterQuestions = @($questions | Where-Object { $_.id -match "^C$chapter-Q" })
    if ($chapterQuestions.Count -ne 20) { throw "Capítulo $chapter incompleto." }
    $positions = @(Shuffle @(0,1,2,3,4,0,1,2,3,4,0,1,2,3,4,0,1,2,3,4) $rng)
    $section = [Text.StringBuilder]::new()
    [void]$section.AppendLine("<section class='quiz' id='quiz-$chapter' aria-labelledby='quiz-title-$chapter'>")
    [void]$section.AppendLine("<h3 id='quiz-title-$chapter'>Questionário de múltipla escolha — capítulo $chapter</h3>")
    [void]$section.AppendLine('<p>Marque uma alternativa por questão. Há uma única resposta correta. Depois de tentar, use <strong>Corrigir capítulo</strong> para ver o resultado e a explicação. Você pode mudar suas respostas e corrigir novamente.</p>')
    [void]$section.AppendLine("<p class='quiz-progress' aria-live='polite'>Respondidas: <span class='answered'>0</span>/20</p>")
    for ($n = 0; $n -lt $chapterQuestions.Count; $n++) {
        $q = $chapterQuestions[$n]
        if ($q.a.Count -ne 5 -or @($q.a | Select-Object -Unique).Count -ne 5) { throw "Alternativas inválidas em $($q.id)" }
        $correct = $positions[$n]
        $distractors = @(Shuffle @(1,2,3,4) $rng)
        $order = [Collections.Generic.List[int]]::new(); $k = 0
        for ($i = 0; $i -lt 5; $i++) {
            if ($i -eq $correct) { $order.Add(0) } else { $order.Add($distractors[$k]); $k++ }
        }
        [void]$section.AppendLine("<fieldset class='question' data-answer='$correct' id='$($q.id)'>")
        [void]$section.AppendLine("<legend><strong>$($q.id).</strong> $(Encode $q.q)</legend>")
        [void]$section.AppendLine("<p class='question-context'><strong>Situação:</strong> $(Inline $q.context)</p>")
        for ($i = 0; $i -lt 5; $i++) {
            $letter = [char](65 + $i); $id = "$($q.id)-$letter"
            [void]$section.AppendLine("<label class='option' for='$id'><input type='radio' id='$id' name='$($q.id)' value='$i'><span><strong>$letter.</strong> $(Encode $q.a[$order[$i]])</span></label>")
        }
        [void]$section.AppendLine("<div class='feedback' id='$($q.id)-feedback' hidden><p class='verdict'></p><p><strong>Comentário:</strong> $(Inline $explanations[$q.id])</p></div>")
        [void]$section.AppendLine('</fieldset>')
    }
    [void]$section.AppendLine('<div class="quiz-actions"><button type="button" class="grade">Corrigir capítulo</button><button type="button" class="hide-feedback">Ocultar correção</button></div><p class="quiz-result" role="status" aria-live="polite"></p></section>')
    $blocks.Add($section.ToString())
}
$pattern = '<h3>Question&#225;rio</h3>\s*<ol>.*?</ol>'
$matchesFound = [regex]::Matches($original, $pattern, [Text.RegularExpressions.RegexOptions]::Singleline)
if ($matchesFound.Count -ne 5) { throw 'Esperados cinco questionários na versão original.' }
$html = $original
for ($i = 4; $i -ge 0; $i--) {
    $match = $matchesFound[$i]
    $html = $html.Remove($match.Index, $match.Length).Insert($match.Index, $blocks[$i])
}
$css = @'
.question{margin:24px 0;padding:18px;border:1px solid #364456;border-radius:10px;min-width:0;background:#131b26}.question-context{padding:14px 16px;border-left:3px solid #79c0ff;background:#182230;border-radius:4px;margin:12px 0 18px}.question legend{padding:0 8px;font-size:1.02em}.option{display:flex;align-items:flex-start;gap:12px;padding:12px;margin:8px 0;border:1px solid #364456;border-radius:7px;cursor:pointer;background:#182230}.option:hover{border-color:#79c0ff}.option:focus-within{outline:2px solid #79c0ff;outline-offset:2px}.option:has(input:checked){border-color:#79c0ff;background:#203149}.option input{margin-top:7px;flex-shrink:0;accent-color:#79c0ff}.option span{overflow-wrap:anywhere}.quiz-actions{display:flex;flex-wrap:wrap;gap:12px;margin-top:20px}button{font:inherit;font-weight:600;padding:10px 16px;border:1px solid #79c0ff;border-radius:7px;background:#203149;color:#e6edf3;cursor:pointer}button:hover{background:#2c4564}button:focus-visible{outline:3px solid #b5ddff;outline-offset:3px}.feedback{border-top:1px solid #364456;margin-top:16px;padding-top:8px}.verdict{font-weight:700}.question.correct{border-color:#63ce9a}.question.incorrect{border-color:#ff9f9f}.question.correct .verdict{color:#8be0b1}.question.incorrect .verdict{color:#ffbaba}.quiz-progress,.quiz-result{font-weight:600}.quiz-note{padding:18px;border:1px solid #79c0ff;border-radius:8px;background:#182230}.quiz-note h2{margin-top:0;break-before:auto}[hidden]{display:none!important}@media(max-width:600px){body{padding:0 16px}.question{padding:12px}.option{padding:10px;gap:8px}table{display:block;overflow-x:auto}}@media print{.question-context{background:#f0f3f6;color:#172b3a;border-color:#174d70}.quiz-actions{display:none}.question,.option,.option:has(input:checked),.quiz-note{background:#fff;color:#172b3a}.question{break-inside:avoid;border-color:#777}.option,.feedback{border-color:#aaa}.question.correct .verdict,.question.incorrect .verdict{color:#172b3a}.quiz-note h2{break-before:auto}.question input{accent-color:#174d70}}
'@
$script = @'
<script>
'use strict';
document.querySelectorAll('.quiz').forEach(quiz => {
  const questions = [...quiz.querySelectorAll('.question')];
  const result = quiz.querySelector('.quiz-result');
  const updateCount = () => {
    quiz.querySelector('.answered').textContent = questions.filter(q => q.querySelector('input:checked')).length;
  };
  const hideFeedback = () => {
    questions.forEach(q => {
      q.classList.remove('correct', 'incorrect');
      q.querySelector('.feedback').hidden = true;
    });
    result.textContent = '';
  };
  quiz.addEventListener('change', event => {
    if (!event.target.matches('input[type="radio"]')) return;
    updateCount();
    hideFeedback();
  });
  quiz.querySelector('.grade').addEventListener('click', () => {
    let correct = 0, answered = 0;
    questions.forEach(q => {
      const selected = q.querySelector('input:checked');
      const answer = Number(q.dataset.answer);
      const letter = String.fromCharCode(65 + answer);
      const verdict = q.querySelector('.verdict');
      q.classList.remove('correct', 'incorrect');
      if (!selected) {
        verdict.textContent = `Não respondida. Alternativa correta: ${letter}.`;
      } else {
        answered++;
        const ok = Number(selected.value) === answer;
        if (ok) correct++;
        q.classList.add(ok ? 'correct' : 'incorrect');
        verdict.textContent = ok ? `Resposta correta: ${letter}.` : `Resposta incorreta. Você marcou ${String.fromCharCode(65 + Number(selected.value))}; a correta é ${letter}.`;
      }
      q.querySelector('.feedback').hidden = false;
    });
    const total = questions.length;
    const points = (correct * 10 / total).toLocaleString('pt-BR', {maximumFractionDigits: 1});
    result.textContent = `Resultado: ${correct}/${total} acertos. Respondidas: ${answered}/${total}. Pendentes: ${total - answered}. Nota do questionário: ${points}/10. Cada acerto vale 0,5 ponto.`;
  });
  quiz.querySelector('.hide-feedback').addEventListener('click', hideFeedback);
  updateCount();
});
</script>
'@
$html = $html.Replace('</style>', $css + '</style>')
$html = $html.Replace('</body>', $script + '</body>')
$html = $html.Replace('<title>PostgreSQL — Estudo de Bruce Momjian</title>', '<title>PostgreSQL — Múltipla escolha e laboratórios</title>')
$html = $html.Replace('PostgreSQL — Question&#225;rio e laborat&#243;rios</h1>', 'PostgreSQL — Múltipla escolha e laboratórios</h1>')
$notice = @'
<aside class="quiz-note" aria-label="Instruções da versão de múltipla escolha"><h2>Como usar esta versão</h2><p>São <strong>100 questões contextualizadas — 20 por capítulo — com cinco alternativas e uma única resposta correta por questão</strong>. Leia a situação antes de marcar A, B, C, D ou E. Os cenários de cada questão são independentes: use os dados e as premissas do enunciado, sem presumir que são sempre a carga dos laboratórios. Há conceitos, interpretação de SQL, identificação de erros e decisões de trabalho.</p><p>Depois de tentar as vinte questões, use <strong>Corrigir capítulo</strong> para ver acertos, pendências e comentários. Você pode dividi-las em dois blocos de dez antes da correção. Uma mudança de resposta oculta a correção anterior; clique novamente para atualizar o resultado. Cada acerto vale <strong>0,5 ponto</strong>: o questionário continua valendo 10 pontos por capítulo, além dos 10 pontos do laboratório.</p><p>Os cinco laboratórios e o passo a passo foram preservados. Reserve cerca de 40–60 minutos adicionais por capítulo para as situações e sua revisão; ajuste conforme seu ritmo. Esta página funciona offline. As respostas ficam somente nesta página aberta: <strong>não são salvas ao fechar ou recarregar</strong>. Antes de sair, anote suas escolhas e resultados ou imprima em PDF. Para revisar sem ver as respostas, use <strong>Ocultar correção</strong>; suas escolhas são mantidas. O gabarito comentado aparece aqui após a correção; o arquivo de soluções SQL continua sendo usado para os laboratórios.</p></aside>
'@
$endTitle = $html.IndexOf('</h1>') + 5
$html = $html.Insert($endTitle, "`n" + $notice)
$html = $html.Replace('Responda com suas palavras,', 'Marque uma das cinco alternativas e anote uma justificativa curta,')
$html = $html.Replace('Abra <code>Gabarito_Questionario.html</code> ou <code>04_Gabarito_Questionario.md</code> para conferir a teoria.', 'Use o botão <strong>Corrigir capítulo</strong> desta página para conferir a teoria e ler os comentários.')
$html = $html.Replace('<code>Questionario_e_Laboratorios.html</code> como roteiro principal', '<code>Questionario_Multipla_Escolha.html</code> como roteiro principal nesta versão')
$html = $html.Replace('Uma resposta conceitual recebe o ponto se explicar corretamente o comportamento;', 'No questionário de múltipla escolha, cada alternativa correta vale 0,5 ponto;')
$html = $html.Replace('50 quest', '100 quest').Replace('dez quest', 'vinte quest')
$html = $html.Replace('1 por quest', '0,5 por quest')
$html = $html.Replace('às dez', 'às vinte').Replace('&#224;s dez', '&#224;s vinte')
$html = $html.Replace('6h30 a 9h para o conjunto; acrescente tempo para corre', '6h30 a 9h para leitura e prática da versão original; nesta versão ampliada, reserve também 40–60 minutos adicionais por capítulo para as questões e sua revisão. Acrescente tempo para corre')
$html = $html.Replace('A versão editável é', 'A versão discursiva editável é')
$out = Join-Path $base 'Questionario_Multipla_Escolha.html'
[IO.File]::WriteAllText($out, $html, [Text.UTF8Encoding]::new($false))
Write-Output "Gerado: $out"
