@echo off
rem Local Windows build matching the CI's clang-cl job (.github/workflows/build-check.yml).
rem Usage: build-local.cmd [configure|build|test|all]   (default: all)
rem Output: build\bin\lichii.exe

setlocal
set "ROOT=%~dp0"
set "LLVM=C:/LLVM22"
set "QT=C:/Qt/6.8.3/msvc2022_64"
set "PATH=C:\Program Files\CMake\bin;%LOCALAPPDATA%\Microsoft\WinGet\Links;%PATH%"
for /d %%V in (C:\VulkanSDK\*) do set "VULKAN_SDK=%%V"
set "PATH=%VULKAN_SDK%\Bin;%QT%/bin;%PATH%"

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
cd /d "%ROOT%"

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
  -DYUZU_USE_BUNDLED_SDL3=ON -DENABLE_UPDATE_CHECKER=OFF -DUSE_DISCORD_PRESENCE=OFF || exit /b 1
if "%STEP%"=="configure" exit /b 0

:build
cmake --build build --parallel || exit /b 1
if "%STEP%"=="build" exit /b 0

:test
ctest --test-dir build --output-on-failure --no-tests=error --parallel %NUMBER_OF_PROCESSORS% || exit /b 1
exit /b 0
