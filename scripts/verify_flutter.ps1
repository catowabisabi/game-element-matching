Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Elementary verification"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "Flutter is not available on PATH."
  Write-Host "Install Flutter, open a new terminal, then run this script again."
  exit 1
}

Write-Host "Flutter:"
flutter --version

Write-Host "Resolving packages..."
flutter pub get

Write-Host "Formatting..."
dart format lib test

Write-Host "Analyzing..."
flutter analyze

Write-Host "Testing..."
flutter test

Write-Host "Done. Start the game with:"
Write-Host "flutter run"
