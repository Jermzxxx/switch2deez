@echo off
rem Local Windows build matching the CI's clang-cl jobs.
rem Usage: build-local.cmd [configure|build|test|all]   (default: all)
rem
rem Three variants, each in a build directory of its own:
rem   dev (default)            build\          with the tests; quick to rebuild
rem   release (RELEASE_TAG set) build-release\  ThinLTO and profile-guided optimisation, as Lichii's
rem                             releases; RELEASE_TAG=build-N and RELEASE_PLATFORM=windows-x86_64
rem                             number it for the built-in updater (release-local.ps1 sets them).
rem                             Line-table debug info and lichii.pdb, kept here for reading crash
rem                             dumps (not shipped)
rem   pgo (BUILD_VARIANT=pgo)  build-pgo\      instrumented, writes a profile while it runs
rem                             (pgo-train.cmd drives it)

setlocal
set "ROOT=%~dp0"
set "LLVM=C:/LLVM22"
set "QT=C:/Qt/6.8.3/msvc2022_64"
set "PATH=C:\Program Files\CMake\bin;%LOCALAPPDATA%\Microsoft\WinGet\Links;%PATH%"
for /d %%V in (C:\VulkanSDK\*) do set "VULKAN_SDK=%%V"
set "PATH=%VULKAN_SDK%\Bin;%QT%/bin;%PATH%"

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
cd /d "%ROOT%"

set "BUILD_DIR=build"
set "TESTS=ON"
set "TRANSLATIONS=OFF"
set "EXTRA_FLAGS="
set "LINK_ARG="
rem Release builds update from this fork; the others keep Lichii's default so its tests still match.
set "UPDATE_REPO="
if defined RELEASE_TAG goto variant_release
if /i "%BUILD_VARIANT%"=="pgo" goto variant_pgo
goto variant_done

:variant_release
set "BUILD_DIR=build-release"
set "TESTS=OFF"
set "TRANSLATIONS=ON"
set "UPDATE_REPO=Jermzxxx/switch2deez"
rem A profile trained here (pgo-train.cmd) when there is one, Lichii's Ocarina of Time profile otherwise.
set "PROFILE=%ROOT%switch2deez.profdata"
if not exist "%PROFILE%" set "PROFILE=%ROOT%lichii-windows.profdata"
set "PROFILE=%PROFILE:\=/%"
set "EXTRA_FLAGS= -flto=thin -fprofile-use=%PROFILE% -Wno-error=profile-instr-out-of-date -Wno-error=profile-instr-unprofiled -Wno-error=backend-plugin -gline-tables-only"
rem /DEBUG writes the .pdb; with it lld-link would stop removing and folding unused code unless asked.
set LINK_ARG="-DCMAKE_EXE_LINKER_FLAGS=/machine:x64 /DEBUG /OPT:REF /OPT:ICF"
goto variant_done

:variant_pgo
set "BUILD_DIR=build-pgo"
set "TESTS=OFF"
set "RAW=%ROOT%build-pgo/profraw"
set "RAW=%RAW:\=/%"
set "EXTRA_FLAGS= -flto=thin -fprofile-generate=%RAW% -fprofile-update=atomic"

:variant_done
set "STEP=%~1"
if "%STEP%"=="" set "STEP=all"

if "%STEP%"=="configure" goto configure
if "%STEP%"=="all" goto configure
if "%STEP%"=="build" goto build
if "%STEP%"=="test" goto test
echo Unknown step %STEP% & exit /b 1

:configure
cmake -S . -B %BUILD_DIR% -G Ninja -DCMAKE_BUILD_TYPE=Release ^
  "-DCMAKE_C_COMPILER=%LLVM%/bin/clang-cl.exe" ^
  "-DCMAKE_CXX_COMPILER=%LLVM%/bin/clang-cl.exe" ^
  "-DCMAKE_LINKER=%LLVM%/bin/lld-link.exe" ^
  "-DCMAKE_AR=%LLVM%/bin/llvm-lib.exe" ^
  "-DCMAKE_C_FLAGS=-DWIN32 -D_WINDOWS -DNOMINMAX%EXTRA_FLAGS%" ^
  "-DCMAKE_CXX_FLAGS=-DWIN32 -D_WINDOWS -EHsc -DNOMINMAX%EXTRA_FLAGS%" ^
  "-DCMAKE_PREFIX_PATH=%QT%" %LINK_ARG% ^
  -DYUZU_BUILD_PRESET=v3 ^
  -DENABLE_WERROR=ON -DBUILD_TESTING=%TESTS% -DYUZU_TESTS=%TESTS% -DENABLE_QT=ON -DYUZU_CMD=ON ^
  -DYUZU_ROOM=OFF -DYUZU_ROOM_STANDALONE=OFF -DYUZU_USE_BUNDLED_QT=OFF ^
  -DENABLE_QT_TRANSLATION=%TRANSLATIONS% ^
  -DYUZU_USE_BUNDLED_SDL3=ON -DENABLE_UPDATE_CHECKER=ON -DUSE_DISCORD_PRESENCE=OFF ^
  "-DLICHII_UPDATE_REPO=%UPDATE_REPO%" -DLICHII_APP_NAME=switch2deez ^
  "-DLICHII_BUILD_TAG=%RELEASE_TAG%" "-DLICHII_BUILD_PLATFORM=%RELEASE_PLATFORM%" || exit /b 1
if "%STEP%"=="configure" exit /b 0

:build
cmake --build %BUILD_DIR% --parallel || exit /b 1
if "%STEP%"=="build" exit /b 0
if "%TESTS%"=="OFF" exit /b 0

:test
if "%TESTS%"=="OFF" echo This variant is built without the tests: test the dev build. & exit /b 1
rem Retries: Lichii's shader_cache_v2_programs.cpp(514) check fails intermittently in its own CI too.
ctest --test-dir %BUILD_DIR% --output-on-failure --no-tests=error --parallel %NUMBER_OF_PROCESSORS% --repeat until-pass:3 || exit /b 1
exit /b 0
