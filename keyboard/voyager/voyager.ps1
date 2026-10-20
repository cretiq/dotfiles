# Windows: save the Voyager layout from Oryx for the Convey cheat sheet keyboard view.
#   voyager.ps1 refresh                   fetch the newest revision of layout 5L3pB
#   voyager.ps1 refresh -Revision pjMyob  fetch that revision
# Writes the whole GraphQL reply to %LOCALAPPDATA%\voyager\oryx-layout.json (Convey: Settings > Voyager Keymap).
# Only reads from Oryx; nothing is sent to the keyboard.
param(
    [Parameter(Position = 0)][ValidateSet('refresh')][string]$Mode = 'refresh',
    [string]$Hash = '5L3pB',
    [string]$Revision = 'latest',
    [string]$Out = (Join-Path $env:LOCALAPPDATA 'voyager\oryx-layout.json')
)
$ErrorActionPreference = 'Stop'

$query = 'query($h:String!,$g:String!,$r:String!){layout(hashId:$h,geometry:$g,revisionId:$r){revision{hashId title createdAt layers{title position keys} combos{keyIndices layerIdx name trigger}}}}'
$body = @{ query = $query; variables = @{ h = $Hash; g = 'voyager'; r = $Revision } } | ConvertTo-Json -Depth 4 -Compress
$reply = Invoke-WebRequest -Uri 'https://oryx.zsa.io/graphql' -Method Post -ContentType 'application/json' -Body $body -UseBasicParsing
$text = [System.Text.Encoding]::UTF8.GetString($reply.RawContentStream.ToArray())
$found = ($text | ConvertFrom-Json).data.layout.revision
if (-not $found) { throw "Oryx returned no revision for $Hash/$Revision`: $text" }

New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
[System.IO.File]::WriteAllText($Out, $text, (New-Object System.Text.UTF8Encoding($false)))
"Saved '$($found.title)' ($($found.hashId)) to $Out"
