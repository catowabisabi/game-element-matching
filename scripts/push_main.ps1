Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repo

Write-Host "Preparing Elementary main push..."

git branch --show-current

git rm -f --ignore-unmatch `
  readme.md `
  element_fusion.apk `
  android/tamagotchi_app_android.iml `
  android/app/src/main/kotlin/com/tamagotchi/tamagotchi_app/MainActivity.kt

git add -A

Write-Host "Staged changes:"
git status --short

git commit -m "Rebuild Elementary Flutter game"
git push origin main

Write-Host "Pushed to origin/main."
