# Fluxo Bash descontinuado: os laboratórios agora são executados no DBeaver.
throw 'Gerador Bash desativado. Siga LEIA-ME.md e execute os laboratórios no DBeaver do Windows conectado à VM.'

$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
function Read-Utf8([string]$name) {
    return [IO.File]::ReadAllText((Join-Path $base $name), [Text.Encoding]::UTF8).Replace("`r`n", "`n").Replace("`r", "")
}
$assets = [ordered]@{}
$assets['00_preparacao.sql'] = Read-Utf8 '00_preparacao.sql'
$assets['02_Lab11_Preparacao.sql'] = Read-Utf8 '02_Lab11_Preparacao.sql'
$solutions = Read-Utf8 '03_Solucoes_Laboratorios.sql'
$matchesFound = [regex]::Matches($solutions, '(?m)^-- (L\d+\.\d+)(?::|\s*$)')
if ($matchesFound.Count -ne 40) { throw 'Esperados 40 blocos SQL.' }
for ($i = 0; $i -lt $matchesFound.Count; $i++) {
    $start = $matchesFound[$i].Index
    $end = if ($i + 1 -lt $matchesFound.Count) { $matchesFound[$i + 1].Index } else { $solutions.Length }
    $task = $matchesFound[$i].Groups[1].Value
    $block = $solutions.Substring($start, $end - $start).Trim()
    if ($task -like 'L11.*') {
        $block = [regex]::Replace($block, '(?s)EXPLAIN \(ANALYZE, BUFFERS\).*?;', {
            param($m)
            return ((1..3 | ForEach-Object { "\echo Medicao $_ de 3`n" + $m.Value }) -join "`n")
        })
    }
    $assets["$task.sql"] = "\timing on`n" + $block + "`n"
}
$taskLines = (Read-Utf8 '01_Questionario_e_Laboratorios.md') -split "`n"
foreach ($line in $taskLines) {
    if ($line -match '^\d+\. \*\*(L\d+\.\d+)\.\*\* (.+)$') {
        $assets["$($Matches[1]).txt"] = $Matches[2].Replace('`', '') + "`n"
    }
}
$hints = @'
L3.1|Defina os cinco tipos e use INSERT com a lista explícita de colunas. Os seis registros estão no arquivo dados_contatos.txt incorporado.
L3.2|A lista depois de SELECT controla colunas; ORDER BY controla a sequência das linhas.
L3.3|Combine UF e limites de idade com AND. Os limites 20 e 31 entram no resultado.
L3.4|O primeiro critério é idade DESC e o segundo nome ASC.
L3.5|Confira WHERE id=2 com SELECT e reutilize esse filtro no UPDATE.
L3.6|Menor que 20 não inclui idade 20. Confira a seleção antes de excluir.
L3.7|DELETE mantém a tabela; DROP TABLE remove o objeto. Use somente rascunho_lab3 neste teste.
L3.8|Compare ids e a cidade do Bruno; verifique se Diego foi removido sem afetar os demais.
L4.1|Use IS NULL para ausência. A igualdade a NULL não se torna verdadeira.
L4.2|Omitir a coluna e usar DEFAULT não equivale a enviar NULL explícito. Duplique a aspa de D'Avila.
L4.3|Use (uf='PR' OR uf='SP') antes do AND ativo=true. AND tem precedência sobre OR.
L4.4|BETWEEN inclui os extremos. IN simplifica igualdades alternativas sobre a mesma coluna.
L4.5|LIKE 'Ana%' testa prefixo. Na regex, ^ marca início e [AB] escolhe A ou B.
L4.6|DISTINCT considera o par completo de colunas. upper() altera a apresentação, não o cadastro.
L4.7|CASE para no primeiro WHEN verdadeiro. Teste os limites 100 e 500.
L4.8|Execute SHOW, SET, SELECT, RESET e SHOW na MESMA sessão ou no mesmo arquivo SQL.
L5.1|COUNT, SUM, AVG, MIN e MAX resumem a coluna. Use round(AVG(...),2).
L5.2|COUNT(*) conta linhas; COUNT(desconto) ignora NULL. AVG considera zero, mas ignora ausência.
L5.3|GROUP BY status define um grupo por status. Ordene a saída para comparar.
L5.4|Agrupe por cliente_id e ordene pelo total somado, com desempate por cliente.
L5.5|Uma condição sobre COUNT(*) do grupo pertence a HAVING.
L5.6|Primeiro WHERE status='pago'; depois agrupe e filtre SUM(valor_total) no HAVING.
L5.7|Uma linha deve representar cada combinação UF/cidade, não somente um dos campos.
L5.8|Sem GROUP BY, a agregação global produz uma linha; sem entradas não existem grupos por status.
L6.1|A ligação é pedidos.cliente_id = clientes.id. Qualifique colunas com aliases.
L6.2|O vendedor do pedido vem de pedidos.vendedor_id. Não ligue ids de entidades diferentes.
L6.3|O caminho é pedidos -> itens -> produtos; quantidade*preco_unitario é o subtotal histórico.
L6.4|O cabeçalho se repete por item. Some subtotais, agrupando pelo pedido e seu valor_total.
L6.5|CROSS JOIN gera todas as combinações. O INNER JOIN só mantém correspondências.
L6.6|Use dois aliases de clientes, igualdade de cidade e UF e a.id<b.id para não repetir pares.
L6.7|Use produtos duas vezes e compare p.preco<ref.preco, fixando ref.id=2.
L6.8|As FKs de itens apontam ao pedido e ao produto. A junção de cinco tabelas deve ter as quatro ligações.
L11.1|A linha de base precisa estar sem índices. Registre três execuções da mesma busca, inclusive buffers e linhas.
L11.2|Crie o índice simples de id e repita a busca três vezes. Retornar toda a tabela pode favorecer Seq Scan.
L11.3|Igualdade na primeira coluna e intervalo na segunda costumam aproveitar bem essa ordem. Compare os planos reais.
L11.4|O segundo 10 deve gerar SQLSTATE 23505. Dois NULL são aceitos pelo índice único padrão. Não envolva a sequência em BEGIN.
L11.5|Compare as mesmas consultas antes e depois de CLUSTER e ANALYZE. Não há ganho percentual obrigatório.
L11.6|São 40 mil atualizações e 20 mil exclusões. VACUUM deve rodar fora de BEGIN; espaço reutilizável não implica arquivo menor.
L11.7|Compare estimated rows e actual rows no mesmo nó, considerando loops. pg_stats ajuda a investigar distribuição.
L11.8|Registre tamanhos, remova apenas o índice simples e repita a busca. Preserve o índice composto e descreva as limitações.
'@
foreach ($line in ($hints -split "`r?`n")) {
    $parts = $line -split '\|', 2
    $assets["$($parts[0]).dica"] = $parts[1] + "`n"
}
$assets['dados_contatos.txt'] = @'
id | nome  | cidade    | uf | idade
1  | Ana   | Curitiba  | PR | 22
2  | Bruno | Londrina  | PR | 31
3  | Carla | São Paulo | SP | 27
4  | Diego | Curitiba  | PR | 19
5  | Elisa | Santos    | SP | 35
6  | Fabio | Recife    | PE | 27
'@
$assets['L3.1.txt'] += "`n" + $assets['dados_contatos.txt'] + "`n"
$assets['L11.1.txt'] += "`nConsulta de medição: SELECT * FROM bdadosql.eventos_lab11 WHERE id=150000;`nUse EXPLAIN (ANALYZE, BUFFERS). Compare três execuções, sem forçar o tipo de scan.`n"
$assets['L11.4_inicio.sql'] = @'
CREATE UNIQUE INDEX codigos_lab11_codigo_idx ON codigos_lab11 (codigo);
INSERT INTO codigos_lab11 VALUES (10);
'@
$assets['L11.4_erro_esperado.sql'] = 'INSERT INTO bdadosql.codigos_lab11 VALUES (10);'
$assets['L11.4_fim.sql'] = @'
INSERT INTO codigos_lab11 VALUES (NULL),(NULL);
SELECT codigo FROM codigos_lab11 ORDER BY codigo NULLS LAST;
'@
$assets['check_base.sql'] = @'
DO $$ BEGIN
 IF (SELECT count(*) FROM bdadosql.clientes) <> 6 OR
    (SELECT count(*) FROM bdadosql.vendedores) <> 2 OR
    (SELECT count(*) FROM bdadosql.produtos) <> 5 OR
    (SELECT count(*) FROM bdadosql.pedidos) <> 8 OR
    (SELECT count(*) FROM bdadosql.itens) <> 10 OR
    (SELECT sum(valor_total) FROM bdadosql.pedidos) IS DISTINCT FROM 2600::numeric THEN
   RAISE EXCEPTION 'A carga compartilhada não corresponde às contagens/totais esperados. Não houve correção automática dos dados.';
 END IF;
END $$;
SELECT 'Carga compartilhada: contagens e soma dos pedidos conferem.' AS resultado;
'@
$assets['check_3.sql'] = @'
DO $$ BEGIN
 IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname='bdadosql' AND tablename='contatos_lab3') THEN
   RAISE EXCEPTION 'Falta contatos_lab3. Execute o laboratório 3.';
 END IF;
 IF (SELECT count(*) FROM bdadosql.contatos_lab3) <> 5 OR
    NOT EXISTS (SELECT FROM bdadosql.contatos_lab3 WHERE id=2 AND nome='Bruno' AND cidade='Maringá') OR
    EXISTS (SELECT FROM bdadosql.contatos_lab3 WHERE id=4 OR idade<20) OR
    (SELECT array_agg(id ORDER BY id) FROM bdadosql.contatos_lab3) IS DISTINCT FROM ARRAY[1,2,3,5,6] OR
    to_regclass('bdadosql.rascunho_lab3') IS NOT NULL THEN
   RAISE EXCEPTION 'O estado final do laboratório 3 ainda não corresponde às tarefas. Confira ids, cidade, idades e remoção do rascunho.';
 END IF;
END $$;
SELECT * FROM bdadosql.contatos_lab3 ORDER BY id;
SELECT 'Estado final do laboratório 3 conferido. Revise também as consultas intermediárias.' AS resultado;
'@
$assets['check_4.sql'] = @'
DO $$ BEGIN
 IF to_regclass('bdadosql.config_lab4') IS NULL THEN RAISE EXCEPTION 'Falta config_lab4 de L4.2.'; END IF;
 IF (SELECT count(*) FROM bdadosql.config_lab4)<>3 OR
    NOT EXISTS (SELECT FROM bdadosql.config_lab4 WHERE id=1 AND descricao='D''Avila' AND status='pendente') OR
    NOT EXISTS (SELECT FROM bdadosql.config_lab4 WHERE id=2 AND status='pendente') OR
    NOT EXISTS (SELECT FROM bdadosql.config_lab4 WHERE id=3 AND status IS NULL) THEN
   RAISE EXCEPTION 'O teste de DEFAULT/NULL ainda não corresponde a L4.2.';
 END IF;
END $$;
SELECT id,nome,email FROM bdadosql.clientes WHERE email IS NULL ORDER BY id;
SELECT * FROM bdadosql.config_lab4 ORDER BY id;
SELECT 'Configuração de L4.2 conferida; compare filtros, padrões e CASE com os registros das tarefas.' AS resultado;
'@
$assets['check_5.sql'] = $assets['check_base.sql'] + "`n" + @'
DO $$ BEGIN
 IF (SELECT round(avg(valor_total),2) FROM bdadosql.pedidos) IS DISTINCT FROM 325::numeric OR
    (SELECT count(desconto) FROM bdadosql.pedidos)<>5 OR
    (SELECT avg(desconto) FROM bdadosql.pedidos) IS DISTINCT FROM 8::numeric THEN
   RAISE EXCEPTION 'As métricas da carga não correspondem ao laboratório 5.';
 END IF;
END $$;
SELECT status,count(*) AS quantidade,sum(valor_total) AS total FROM bdadosql.pedidos GROUP BY status ORDER BY status;
SELECT 'Métricas esperadas conferidas. A correção do SQL escrito e da explicação exige comparar suas tentativas.' AS resultado;
'@
$assets['check_6.sql'] = $assets['check_base.sql'] + "`n" + @'
DO $$ BEGIN
 IF (SELECT count(*) FROM bdadosql.pedidos p JOIN bdadosql.clientes c ON c.id=p.cliente_id)<>8 OR
    (SELECT count(*) FROM bdadosql.pedidos p JOIN bdadosql.itens i ON i.pedido_id=p.id JOIN bdadosql.produtos pr ON pr.id=i.produto_id)<>10 OR
    EXISTS (SELECT p.id FROM bdadosql.pedidos p JOIN bdadosql.itens i ON i.pedido_id=p.id
            GROUP BY p.id,p.valor_total HAVING sum(i.quantidade*i.preco_unitario)<>p.valor_total) THEN
   RAISE EXCEPTION 'Cardinalidade ou subtotais dos itens divergem da carga prevista.';
 END IF;
END $$;
SELECT p.id,p.valor_total,sum(i.quantidade*i.preco_unitario) AS soma_itens FROM bdadosql.pedidos p
JOIN bdadosql.itens i ON i.pedido_id=p.id GROUP BY p.id,p.valor_total ORDER BY p.id;
SELECT 'Cardinalidade e totais conferidos; compare os joins escritos nas suas tentativas.' AS resultado;
'@
$assets['check_11.sql'] = @'
DO $$ BEGIN
 IF to_regclass('bdadosql.eventos_lab11') IS NULL OR to_regclass('bdadosql.codigos_lab11') IS NULL THEN
   RAISE EXCEPTION 'Faltam tabelas do laboratório 11.';
 END IF;
 IF (SELECT count(*) FROM bdadosql.eventos_lab11)<>180000 OR
    (SELECT count(*) FROM bdadosql.eventos_lab11 WHERE status='revisado')<>40000 OR
    EXISTS (SELECT FROM bdadosql.eventos_lab11 WHERE id>180000) OR
    to_regclass('bdadosql.eventos_lab11_id_idx') IS NOT NULL OR
    to_regclass('bdadosql.eventos_lab11_cliente_data_idx') IS NULL OR
    (SELECT count(*) FROM bdadosql.codigos_lab11)<>3 OR
    (SELECT count(*) FROM bdadosql.codigos_lab11 WHERE codigo=10)<>1 OR
    (SELECT count(*) FROM bdadosql.codigos_lab11 WHERE codigo IS NULL)<>2 THEN
   RAISE EXCEPTION 'Estado final diverge: esperados 180 mil eventos, 40 mil revisados, só índice composto e códigos 10/NULL/NULL.';
 END IF;
END $$;
SELECT indexrelid::regclass AS indice,indisclustered,pg_size_pretty(pg_relation_size(indexrelid)) AS tamanho
FROM pg_index WHERE indrelid='bdadosql.eventos_lab11'::regclass;
SELECT 'Estado final conferido. Planos, três medições e relatório devem ser revisados nos registros; não há meta fixa de tempo.' AS resultado;
'@
$assetFunction = [Text.StringBuilder]::new()
[void]$assetFunction.AppendLine('materialize_assets() {')
$i = 0
foreach ($entry in $assets.GetEnumerator()) {
    if ($entry.Key -notmatch '^[A-Za-z0-9_.]+$') { throw 'Nome de asset inválido.' }
    $i++
    $delimiter = "BDADOSQL_ASSET_${i}_END"
    if ($entry.Value.Contains($delimiter)) { throw 'Delimitador em conflito.' }
    [void]$assetFunction.AppendLine(('cat > "$ASSET_DIR/{0}" <<''{1}'' || return 1' -f $entry.Key,$delimiter))
    [void]$assetFunction.AppendLine($entry.Value.TrimEnd().Replace("`r",''))
    [void]$assetFunction.AppendLine($delimiter)
}
[void]$assetFunction.AppendLine('}')
$template = Read-Utf8 'runner_ubuntu.template.sh'
if (-not $template.Contains('# GENERATED_ASSETS')) { throw 'Marcador ausente no template.' }
$output = $template.Replace('# GENERATED_ASSETS', $assetFunction.ToString()).Replace("`r",'')
[IO.File]::WriteAllText((Join-Path $base 'laboratorios_interativos.sh'), $output, [Text.UTF8Encoding]::new($false))
Write-Output "Runner autônomo gerado com $($assets.Count) arquivos incorporados, 40 tarefas e 5 conferências de laboratório."
