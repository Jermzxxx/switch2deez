# Builds a numbered switch2deez release from 'main' and publishes it to GitHub releases, where the
# built-in updater of every installed release build finds it.
#   powershell -ExecutionPolicy Bypass -File release-local.ps1            build and publish
#   powershell -ExecutionPolicy Bypass -File release-local.ps1 -DryRun    build and zip only
param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$githubRepo = 'Jermzxxx/switch2deez'
$platform = 'windows-x86_64'
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
Set-Location $repo

if (git status --porcelain --untracked-files=no) { throw 'Commit or stash your changes first.' }
if ((git rev-parse --abbrev-ref HEAD) -ne 'main') { throw "Releases are made from 'main'." }
$commit = git rev-parse HEAD

# Next build number: one above the highest build-N already published.
$tags = & $gh release list --repo $githubRepo --limit 200 --json tagName --jq '.[].tagName'
$numbers = @($tags | Where-Object { $_ -match '^build-(\d+)$' } | ForEach-Object { [int]$Matches[1] })
$number = if ($numbers.Count) { ($numbers | Measure-Object -Maximum).Maximum + 1 } else { 1 }
$tag = "build-$number"
Write-Host "Building $tag from $($commit.Substring(0, 10))"

function Invoke-Build([string]$step) {
    cmd /c "`"$repo\build-local.cmd`" $step"
    if ($LASTEXITCODE -ne 0) { throw "build-local.cmd $step failed" }
}

# Test the dev build (build\: Lichii's tests expect its default update repository), then build the
# release variant (build-release\: ThinLTO and profile-guided optimisation) from the same sources.
Remove-Item Env:RELEASE_TAG, Env:RELEASE_PLATFORM -ErrorAction SilentlyContinue
Invoke-Build configure
Invoke-Build build
Invoke-Build test

$env:RELEASE_TAG = $tag
$env:RELEASE_PLATFORM = $platform
try {
    Invoke-Build configure
    Invoke-Build build
} finally {
    Remove-Item Env:RELEASE_TAG, Env:RELEASE_PLATFORM -ErrorAction SilentlyContinue
}

# Package the deployed bin directory (Qt and the other DLLs included).
$stage = Join-Path $repo "build-release\stage\$tag"
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force $stage | Out-Null
Get-ChildItem build-release\bin | Where-Object { $_.Name -notmatch 'tests?\.exe$|_probe\.exe$|\.pdb$' } |
    Copy-Item -Destination $stage -Recurse
$zip = Join-Path $repo "build-release\stage\lichii-$platform.zip"
if (Test-Path $zip) { Remove-Item -Force $zip }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip
Write-Host "Packaged $zip ($([math]::Round((Get-Item $zip).Length / 1MB)) MB)"

# Keep the programs and their debug symbols, which the zip leaves out: a crash dump of this
# release is read against them (llvm-symbolizer --obj=lichii.exe) after build-release changed.
$symbols = Join-Path $repo "build-release\symbols\$tag"
if (Test-Path $symbols) { Remove-Item -Recurse -Force $symbols }
New-Item -ItemType Directory -Force $symbols | Out-Null
foreach ($name in 'lichii.exe', 'lichii.pdb', 'eden-cli.exe', 'eden-cli.pdb') {
    $file = Join-Path $repo "build-release\bin\$name"
    if (Test-Path $file) { Copy-Item $file $symbols }
}
if (-not (Test-Path (Join-Path $symbols 'lichii.pdb'))) { throw 'build-release\bin\lichii.pdb is missing.' }
Write-Host "Symbols kept in $symbols"

if ($DryRun) { Write-Host 'Dry run: not published.'; exit 0 }

git push origin main --quiet
if ($LASTEXITCODE -ne 0) { throw 'Pushing main failed.' }
$notes = "switch2deez $tag, built from $commit.`n`nInstalled switch2deez release builds offer this update when they start."
& $gh release create $tag $zip --repo $githubRepo --target $commit --title "switch2deez $tag" --notes $notes
if ($LASTEXITCODE -ne 0) { throw 'Publishing the release failed.' }
Write-Host "Published https://github.com/$githubRepo/releases/tag/$tag"
