# Merges the latest upstream (zortos293/Lichii, branch nx2) into your personal 'main' branch.
# Safe by design: skips if you have uncommitted changes, aborts cleanly on merge conflicts.
# Log: .git\sync-upstream.log

$ErrorActionPreference = 'Continue'
$repo = $PSScriptRoot
$log  = Join-Path $repo '.git\sync-upstream.log'
$upstreamBranch = 'nx2'
$myBranch = 'main'

function Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Add-Content -Path $log -Value $line
    Write-Host $line
}

Set-Location $repo

if (git status --porcelain --untracked-files=no) {
    Log "SKIPPED: uncommitted changes present. Commit or stash them, then run again."
    exit 1
}

$current = git rev-parse --abbrev-ref HEAD
if ($current -ne $myBranch) {
    Log "SKIPPED: currently on '$current', not '$myBranch'."
    exit 1
}

git fetch upstream --prune --quiet
if ($LASTEXITCODE -ne 0) { Log "FAILED: could not fetch upstream."; exit 1 }

$behind = git rev-list --count "$myBranch..upstream/$upstreamBranch"
if ([int]$behind -eq 0) { Log "Up to date."; exit 0 }

$before = git rev-parse HEAD
git merge --no-edit "upstream/$upstreamBranch" -m "Merge upstream/$upstreamBranch ($(Get-Date -Format 'yyyy-MM-dd'))"
if ($LASTEXITCODE -ne 0) {
    $conflicts = (git diff --name-only --diff-filter=U) -join ', '
    git merge --abort
    Log "CONFLICT: merge aborted, nothing changed. Resolve by hand with: git merge upstream/$upstreamBranch  Files: $conflicts"
    exit 2
}
Log "Merged $behind new upstream commit(s)."

# Build and test the merge before it goes anywhere (skipped until build-local.cmd configure has run).
if (Test-Path (Join-Path $repo 'build\CMakeCache.txt')) {
    $buildLog = Join-Path $repo '.git\sync-build.log'
    foreach ($step in 'build', 'test') {
        cmd /c "`"$repo\build-local.cmd`" $step" *> $buildLog
        if ($LASTEXITCODE -ne 0) {
            git reset --hard $before --quiet
            Log "FAILED: the merge did not pass '$step', so it was undone and nothing was pushed. See $buildLog; retry by hand with: git merge upstream/$upstreamBranch"
            exit 3
        }
    }
    Log "Build and tests passed."
}

# Push to your own GitHub fork if one is configured as 'origin'.
if ((git remote) -contains 'origin') {
    git push origin $myBranch --quiet
    if ($LASTEXITCODE -eq 0) { Log "Pushed to origin/$myBranch." } else { Log "WARNING: push to origin failed." }
}
