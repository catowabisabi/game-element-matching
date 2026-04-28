Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Cleaning Windows case-collision files from Git index..."

git rm --cached -- readme.md
git rm --cached -- element_fusion.apk

Write-Host "Keeping README.md and the source HTML prototype."
Write-Host "Review with: git status --short"
