# PowerShell alias for 'l' to run 'ls'
Set-Alias -Name l -Value Get-ChildItem

# Worktree navigation with @ prefix
$DevRoot = "C:\Dev"

function Get-Worktrees {
    Get-ChildItem $DevRoot -Directory | Where-Object {
        $path = $_.FullName
        # Must have .git (file for worktrees, folder for main repos)
        $hasGit = Test-Path "$path\.git"
        # Match: nested structure (Phoenix\server\Phoenix) OR flat structure (server\Phoenix at root)
        $isNested = Test-Path "$path\Phoenix\server\Phoenix"
        $isFlat = Test-Path "$path\server\Phoenix"
        $hasGit -and ($isNested -or $isFlat)
    } | Select-Object -ExpandProperty Name
}

function Get-WorktreePaths {
    param([string]$worktree)
    $base = "$DevRoot\$worktree"

    # Auto-detect structure: flat (server\ at root) vs nested (Phoenix\server\)
    if (Test-Path "$base\server\Phoenix") {
        # Flat structure - server/client at root level
        @{
            server = "$base\server\Phoenix"
            client = "$base\client\phoenix-client"
        }
    } else {
        # Nested structure - under Phoenix folder
        @{
            server = "$base\Phoenix\server\Phoenix"
            client = "$base\Phoenix\client\phoenix-client"
        }
    }
}

# Resolve @worktree/s, @worktree/c, @worktree/ss, or @worktree/cc to actual path
# Returns hashtable with path and optional action
function Resolve-WorktreePath {
    param([string]$Path)

    # Match @worktree/ss (server + start) or @worktree/cc (client + start)
    if ($Path -match '^@([^/]+)/([sc]{2})$') {
        $wt = $Matches[1]
        $action = $Matches[2]
        $match = Get-Worktrees | Where-Object { $_ -like "*$wt*" } | Select-Object -First 1
        if ($match) {
            $paths = Get-WorktreePaths $match
            $targetPath = if ($action -eq 'ss') { $paths.server } else { $paths.client }
            return @{
                path = $targetPath
                action = $action
            }
        }
    }
    # Match @worktree/s or @worktree/c (navigate only)
    elseif ($Path -match '^@([^/]+)/([sc])$') {
        $wt = $Matches[1]
        $sub = $Matches[2]
        $match = Get-Worktrees | Where-Object { $_ -like "*$wt*" } | Select-Object -First 1
        if ($match) {
            $paths = Get-WorktreePaths $match
            $targetPath = if ($sub -eq 's') { $paths.server } else { $paths.client }
            return @{
                path = $targetPath
                action = $null
            }
        }
    }

    return @{
        path = $Path
        action = $null
    }
}

# Register completer for Set-Location (the real cd)
Register-ArgumentCompleter -CommandName Set-Location -ParameterName Path -ScriptBlock {
    param($cmd, $param, $word)

    if ($word -match '^@([^/]*)/(.*)$') {
        # After slash - show server/client with start variants
        $wt = $Matches[1]
        $sub = $Matches[2]
        $match = Get-Worktrees | Where-Object { $_ -like "*$wt*" } | Select-Object -First 1
        if ($match) {
            $paths = Get-WorktreePaths $match
            @(
                @{ path = "@$match/s"; label = "s"; tooltip = $paths.server }
                @{ path = "@$match/ss"; label = "ss"; tooltip = "$($paths.server) + dotnet run" }
                @{ path = "@$match/c"; label = "c"; tooltip = $paths.client }
                @{ path = "@$match/cc"; label = "cc"; tooltip = "$($paths.client) + yarn start" }
            ) | Where-Object { $_.label -like "$sub*" } | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_.path, "@$match/$($_.label)", 'ParameterValue', $_.tooltip)
            }
        }
    }
    elseif ($word -match '^@(.*)') {
        # List worktrees
        $filter = $Matches[1]
        Get-Worktrees | Where-Object { $_ -like "*$filter*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new("@$_/", "@$_", 'ParameterValue', "$DevRoot\$_")
        }
    }
}

# Override default cd behavior using PSReadLine
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $CommandLookupEventArgs)
}

# Use prompt command preprocessing to handle @ paths
Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    # Replace @worktree/s, @worktree/c, @worktree/ss, or @worktree/cc
    if ($line -match '^(cd|Set-Location|sl)\s+(@[^/]+/[sc]{1,2})(.*)$') {
        $cmd = $Matches[1]
        $wtPath = $Matches[2]
        $rest = $Matches[3]
        $result = Resolve-WorktreePath $wtPath

        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

        if ($result.action -eq 'ss') {
            # Navigate and start server
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("cd `"$($result.path)`" ; dotnet run")
        } elseif ($result.action -eq 'cc') {
            # Navigate and start client
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("cd `"$($result.path)`" ; yarn start")
        } else {
            # Just navigate
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$cmd `"$($result.path)`"$rest")
        }
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
