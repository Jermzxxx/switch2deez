@echo off
rem Launch the locally built lichii.exe. Pass "trace" to log stutters and frame times:
rem   run-local.cmd          normal run
rem   run-local.cmd trace    logs Nx2Stutter / Nx2StutterSummary lines and GPU profile
rem Log: %APPDATA%\eden\log\eden_log.txt
setlocal
if /i "%~1"=="trace" (
    set "EDEN_NX2_STUTTER_TRACE=1"
    set "EDEN_NX2_GPU_PROFILE=1"
    set "EDEN_DKB_FRAME_TRACE=1"
)
start "" "%~dp0build\bin\lichii.exe"
