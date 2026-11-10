@echo off
rem Trains a profile-guided optimisation profile on your own play, for release builds to use.
rem   pgo-train.cmd build    build the instrumented emulator (build-pgo\, a full build)
rem   pgo-train.cmd play     run it: play 5-10 minutes of what you want fast, then close it
rem                          (it runs much slower than normal while it records)
rem   pgo-train.cmd merge    turn the recordings into switch2deez.profdata
rem Release builds (release-local.ps1) then use switch2deez.profdata in place of Lichii's profile.
rem Train again after large upstream changes: code that changed since loses its profile data.

setlocal
set "ROOT=%~dp0"
set "RAW=%ROOT%build-pgo\profraw"

if /i "%~1"=="build" goto build
if /i "%~1"=="play" goto play
if /i "%~1"=="merge" goto merge
echo Usage: pgo-train.cmd build ^| play ^| merge
exit /b 1

:build
set "BUILD_VARIANT=pgo"
set "RELEASE_TAG="
call "%ROOT%build-local.cmd" all
exit /b %ERRORLEVEL%

:play
if not exist "%ROOT%build-pgo\bin\lichii.exe" echo Run "pgo-train.cmd build" first. & exit /b 1
start "" /wait "%ROOT%build-pgo\bin\lichii.exe"
echo Recorded. Run "pgo-train.cmd merge" when you have played enough sessions.
exit /b 0

:merge
if not exist "%RAW%\*.profraw" echo No recordings in %RAW%: run "pgo-train.cmd play" first. & exit /b 1
"C:\LLVM22\bin\llvm-profdata.exe" merge -o "%ROOT%switch2deez.profdata" "%RAW%" || exit /b 1
"C:\LLVM22\bin\llvm-profdata.exe" show "%ROOT%switch2deez.profdata"
echo Wrote switch2deez.profdata: the next release build uses it.
exit /b 0
