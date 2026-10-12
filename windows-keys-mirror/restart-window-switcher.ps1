$exe = "C:\Users\FilipM\AppData\Local\Programs\window-switcher\window-switcher.exe"
Get-Process -Name "window-switcher" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500
Start-Process $exe
