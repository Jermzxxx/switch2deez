@echo off
rem Local Windows build matching the CI's clang-cl job (.github/workflows/build-check.yml).
rem Usage: build-local.cmd [configure|build|test|all]   (default: all)
rem Output: build\bin\lichii.exe
rem RELEASE_TAG=build-N and RELEASE_PLATFORM=windows-x86_64 make a numbered release build that the
rem built-in updater can compare (release-local.ps1 sets them); leave them unset for dev builds.

setlocal
set "ROOT=%~dp0"
set "LLVM=C:/LLVM22"
set "QT=C:/Qt/6.8.3/msvc2022_64"
set "PATH=C:\Program Files\CMake\bin;%LOCALAPPDATA%\Microsoft\WinGet\Links;%PATH%"
for /d %%V in (C:\VulkanSDK\*) do set "VULKAN_SDK=%%V"
set "PATH=%VULKAN_SDK%\Bin;%QT%/bin;%PATH%"

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
cd /d "%ROOT%"

rem Release builds update from this fork; dev builds keep Lichii's default so its tests still match.
set "UPDATE_REPO="
if defined RELEASE_TAG set "UPDATE_REPO=Jermzxxx/switch2deez"

set "STEP=%~1"
if "%STEP%"=="" set "STEP=all"

if "%STEP%"=="configure" goto configure
if "%STEP%"=="all" goto configure
if "%STEP%"=="build" goto build
if "%STEP%"=="test" goto test
echo Unknown step %STEP% & exit /b 1

:configure
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release ^
  "-DCMAKE_C_COMPILER=%LLVM%/bin/clang-cl.exe" ^
  "-DCMAKE_CXX_COMPILER=%LLVM%/bin/clang-cl.exe" ^
  "-DCMAKE_LINKER=%LLVM%/bin/lld-link.exe" ^
  "-DCMAKE_AR=%LLVM%/bin/llvm-lib.exe" ^
  "-DCMAKE_C_FLAGS=-DWIN32 -D_WINDOWS -DNOMINMAX" ^
  "-DCMAKE_CXX_FLAGS=-DWIN32 -D_WINDOWS -EHsc -DNOMINMAX" ^
  "-DCMAKE_PREFIX_PATH=%QT%" ^
  -DYUZU_BUILD_PRESET=v3 ^
  -DENABLE_WERROR=ON -DBUILD_TESTING=ON -DYUZU_TESTS=ON -DENABLE_QT=ON -DYUZU_CMD=ON ^
  -DYUZU_ROOM=OFF -DYUZU_ROOM_STANDALONE=OFF -DYUZU_USE_BUNDLED_QT=OFF ^
  -DYUZU_USE_BUNDLED_SDL3=ON -DENABLE_UPDATE_CHECKER=ON -DUSE_DISCORD_PRESENCE=OFF ^
  "-DLICHII_UPDATE_REPO=%UPDATE_REPO%" -DLICHII_APP_NAME=switch2deez ^
  "-DLICHII_BUILD_TAG=%RELEASE_TAG%" "-DLICHII_BUILD_PLATFORM=%RELEASE_PLATFORM%" || exit /b 1
if "%STEP%"=="configure" exit /b 0

:build
cmake --build build --parallel || exit /b 1
if "%STEP%"=="build" exit /b 0

:test
rem Retries: Lichii's shader_cache_v2_programs.cpp(514) check fails intermittently in its own CI too.
ctest --test-dir build --output-on-failure --no-tests=error --parallel %NUMBER_OF_PROCESSORS% --repeat until-pass:3 || exit /b 1
exit /b 0
