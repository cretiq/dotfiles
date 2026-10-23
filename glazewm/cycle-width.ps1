$glaze = 'C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe'
$config = 'C:\Users\FilipM\.glzr\glazewm\config.yaml'
$text = [IO.File]::ReadAllText($config)
$pattern = "(?s)(outer_gap:\r?\n\s*top: [^\r\n]*\r?\n\s*right: )'([^']*)'(\r?\n\s*bottom: [^\r\n]*\r?\n\s*left: )'([^']*)'"
$m = [regex]::Match($text, $pattern)
$next = if ($m.Groups[4].Value -eq '25%') { "'12%'" } elseif ($m.Groups[4].Value -eq '12%') { "'8px'" } else { "'25%'" }
$text = [regex]::Replace($text, $pattern, { param($x) $x.Groups[1].Value + $next + $x.Groups[3].Value + $next })
[IO.File]::WriteAllText($config, $text, (New-Object Text.UTF8Encoding $false))
& $glaze command wm-reload-config
