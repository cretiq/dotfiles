$engines = @(@{ allow_search_engine_discovery = $true }, @{ is_default = $true; keyword = 'bing.com'; name = 'Bing'; search_url = 'https://www.bing.com/search?q={searchTerms}' })
foreach ($n in 1..6) {
    $engines += @{ keyword = "$n"; name = "localhost 517$n"; search_url = "https://localhost:517$n/#{searchTerms}" }
}
$json = $engines | ConvertTo-Json -Compress -Depth 4
$path = 'HKCU:\Software\Policies\Microsoft\Edge\Recommended'
if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
Set-ItemProperty -Path $path -Name ManagedSearchEngines -Value $json -Type String
(Get-ItemProperty $path).ManagedSearchEngines
