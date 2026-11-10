@echo off
rem Launch the locally built lichii.exe (build\bin).
rem   run-local.cmd            normal run
rem   run-local.cmd trace      logs stutters and their causes, frame times and per-thread CPU time;
rem                            light, frame rates are close to a normal run
rem   run-local.cmd profile    as trace, plus the GPU thread profile (time per zone); it takes the
rem                            emulator off its fast paths, so frame rates are lower than normal
rem Log: %APPDATA%\eden\log\eden_log.txt
setlocal
if /i "%~1"=="trace" goto trace
if /i "%~1"=="profile" goto profile
goto run
:profile
set "EDEN_NX2_GPU_PROFILE=1"
:trace
set "EDEN_NX2_STUTTER_TRACE=1"
set "EDEN_DKB_FRAME_TRACE=1"
:run
start "" "%~dp0build\bin\lichii.exe"
