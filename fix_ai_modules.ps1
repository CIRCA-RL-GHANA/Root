param(
    [string]$BasePath = "c:\Users\Wisdom Amaniampong\Desktop\Code\thedep\thepg\lib\features"
)

# Module color map
$moduleColors = @{
    "updates"      = "kUpdatesColor"
    "user_details" = "AppColors.primary"
    "utility"      = "kUtilityColor"
    "alerts"       = "kAlertsColor"
    "market"       = "kMarketColor"
    "april"        = "kAprilColor"
}

function Make-Banner {
    param([string]$Color, [string]$Indent = "              ")
    $i2 = $Indent + "  "
    $i4 = $Indent + "    "
    $i6 = $Indent + "      "
    $i8 = $Indent + "        "
    $end_icon = $i8 + "const Icon(Icons.auto_awesome, size: 14, color: $Color),"
    $end_box  = $i8 + "const SizedBox(width: 8),"
    $title_text = "AI: `${ai.insights.first['title'] ?? ''}"
    $banner = @"
${Indent}Consumer<AIInsightsNotifier>(
${i2}builder: (context, ai, _) {
${i4}if (ai.insights.isEmpty) return const SizedBox.shrink();
${i4}return Container(
${i6}color: $Color.withOpacity(0.07),
${i6}padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
${i6}child: Row(
${i8}children: [
${end_icon}
${end_box}
${i8}Expanded(
${i8}  child: Text(
${i8}    '$title_text',
${i8}    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: $Color),
${i8}    maxLines: 1, overflow: TextOverflow.ellipsis,
${i8}  ),
${i8}),
${i8}],
${i6}),
${i4});
${i2}},
${Indent}),
"@
    return $banner
}

$fixed = 0
$skipped = 0
$failed = 0

foreach ($mod in @("updates","user_details","utility","alerts","market","april")) {
    $color = $moduleColors[$mod]
    $screenDir = Join-Path $BasePath "$mod\screens"
    if (-not (Test-Path $screenDir)) { continue }
    
    foreach ($f in Get-ChildItem $screenDir -Filter "*.dart") {
        $path = $f.FullName
        $c = [IO.File]::ReadAllText($path)
        
        if ($c.Contains('Consumer<AIInsightsNotifier>') -or $c.Contains('Consumer2') -and $c.Contains('AIInsightsNotifier')) {
            $skipped++
            continue
        }
        
        $banner = Make-Banner -Color $color
        $inserted = $false
        
        # Pattern A: body: Column( children: [
        if ($c.Contains("body: Column(`r`n            children: [")) {
            $old = "body: Column(`r`n            children: ["
            $new = "body: Column(`r`n            children: [`r`n" + $banner
            $nc = $c.Replace($old, $new)
            if ($nc -ne $c) {
                [IO.File]::WriteAllText($path, $nc)
                $fixed++; $inserted = $true
                Write-Host "[Column] Fixed: $($f.Name)"
            }
        }
        
        # Pattern B: body: ListView(
        if (-not $inserted -and $c.Contains("body: ListView(")) {
            # Find ListView and its children: [ then insert before first real child
            $banner14 = Make-Banner -Color $color -Indent "              "
            $anchors = @(
                "body: ListView(`r`n            padding: const EdgeInsets.all(16),`r`n            children: [`r`n",
                "body: ListView(`r`n            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),`r`n            children: [`r`n",
                "body: ListView(`r`n            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),`r`n            children: [`r`n",
                "body: ListView(`r`n            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),`r`n            children: [`r`n"
            )
            foreach ($anchor in $anchors) {
                if ($c.Contains($anchor)) {
                    $nc = $c.Replace($anchor, $anchor + $banner14)
                    if ($nc -ne $c) {
                        [IO.File]::WriteAllText($path, $nc)
                        $fixed++; $inserted = $true
                        Write-Host "[ListView] Fixed: $($f.Name)"
                        break
                    }
                }
            }
        }
        
        if (-not $inserted) {
            $failed++
            Write-Host "[FAIL] No pattern matched: $($f.Name)"
        }
    }
}

Write-Host "`nResults: Fixed=$fixed, Skipped=$skipped, Failed=$failed"
