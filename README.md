<!--
# SPDX-FileCopyrightText: Copyright 2025 Eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# SPDX-FileCopyrightText: 2018 yuzu Emulator Project
# SPDX-License-Identifier: GPL-2.0-or-later
-->

# switch2deez

switch2deez is a personal fork of [Lichii](https://github.com/zortos293/Lichii), the open-source Nintendo Switch and Switch 2 emulator. It follows Lichii closely: Lichii's changes are merged in every day, and this fork adds a small set of performance fixes and build changes of its own.

This is an unofficial build. It is not made or supported by the Lichii project or the projects Lichii builds on (Eglantine, Eden, yuzu and Sudachi), and it is not affiliated with Nintendo. Report problems with this build here, not to Lichii.

## Downloads and updates

Download builds only from this repository's [releases page](https://github.com/Jermzxxx/switch2deez/releases).

On Windows, extract the whole archive to a folder of its own and run **lichii.exe**. The program keeps Lichii's file name and data folder.

Release builds check this repository for a newer release when they start and offer to install it. Turn this off in the settings with **Check for updates**. After an update, **Help > Restore Previous Version** goes back to the build you updated from.

Only use games and system files you have legally obtained. Games, keys and firmware are not included.

### Saves and settings

switch2deez uses Lichii's data folder, `%APPDATA%\lichii` on Windows, so your saves, settings and shader caches are shared with Lichii. Builds before build-4 used `%APPDATA%\eden`: on the first launch of a newer build, Lichii offers to import it. Choose **Import**, then **Keep Old Data**, which copies the old folder and leaves it unchanged. Back up your saves before trying a new build.

## What is different from Lichii

- **Fewer duplicate shader pipelines:** tessellation state is left out of pipelines that have no tessellation stages, so the same shaders aren't built twice.
- **Shorter GPU waits on Windows:** waits for GPU submissions sleep for one timer tick instead of a full millisecond or more.
- **Texture cache cleanup in batches:** evicting textures that must be copied back to memory waits for the GPU once per batch instead of once per texture.
- **Less thread wake-up overhead:** the GPU command queues signal the other thread only when it is actually waiting.
- **A warning when the GPU thread split is off:** the log says when GPU or DMA accuracy settings stop the faster split GPU thread from starting.
- **Optimised Windows builds:** release compiler flags for clang-cl, and code built for x86-64-v3 CPUs.

x86-64-v3 builds need a CPU with AVX2: Intel Haswell (4th generation Core, 2013) or newer, or AMD Zen or newer.

Everything else, including game compatibility, comes from Lichii. See [Lichii's compatibility reports](https://lichii.zortos.me/reports) for how games run.

## Reporting problems

[Open an issue](https://github.com/Jermzxxx/switch2deez/issues) with:

- The build number (from the title bar or the first line of the log), the game and its version, your CPU, GPU and driver version.
- Your relevant settings and the steps to reproduce the problem.
- The log from the affected session (`%APPDATA%\lichii\log\eden_log.txt`), after checking it for personal information.

Do not upload game files, keys, firmware or private account information.

If the problem also happens in an official Lichii release, it belongs with Lichii instead.

## Building

On Windows, with Visual Studio 2022 Build Tools, LLVM 22.1.8 in `C:\LLVM22`, Qt 6.8.3 in `C:\Qt`, CMake, Ninja and the Vulkan SDK installed:

```bat
build-local.cmd            :: configure, build and run the tests
build-local.cmd build      :: rebuild after changes
run-local.cmd              :: run the build
run-local.cmd trace        :: run it and log stutters and GPU timing
```

The program is built to `build\bin\lichii.exe`. For other platforms and details, see Lichii's [build guide](docs/Build.md).

### Keeping up with Lichii

`sync-upstream.ps1` merges Lichii's latest changes into `main`, builds them and runs the tests, and pushes only when everything passes. A merge that conflicts or fails is undone and logged in `.git\sync-upstream.log`.

### Publishing a release

`release-local.ps1` builds the next numbered release (`build-N`) from `main`, packages `lichii-windows-x86_64.zip` and publishes it here, where installed builds find it as an update. Run it with `-DryRun` to build and package without publishing.

## Credits and license

switch2deez is built on [Lichii](https://github.com/zortos293/Lichii) and the work of the Eglantine, Eden, yuzu and Sudachi projects and their contributors. Original copyright notices and third-party licenses are kept. The Lichii logo, icon and artwork in [dist/branding](dist/branding) were created by YOB (yobslab) for Lichii.

This program is free software under the GNU General Public License. See [LICENSE.txt](LICENSE.txt) and the source files for the applicable license terms.
