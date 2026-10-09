$glaze = 'C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe'
$focused = (& $glaze query workspaces | ConvertFrom-Json).data.workspaces | Where-Object hasFocus
& $glaze command focus --workspace $(if ($focused.name -eq '1') { '2' } else { '1' })
