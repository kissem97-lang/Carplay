# DriveHUD 0.2.0 — iOS 15.8 / Dopamine rootless starter

A clean-room prototype, not copied from SidePlay2. It adds separate modules for layout persistence, a speed-provider boundary, and allowlisted navigation URL shortcuts.

## Current functionality
- Rootless Theos configuration for iOS 15+ (`iphoneos-arm64`; arm64/arm64e).
- HUD with normalized position persistence, scale and opacity settings.
- Drag the HUD to reposition it; a tap toggles expanded mode and offers Apple Maps / Google Maps / Waze URL shortcuts.
- The speed provider deliberately displays `-- km/h`; no fake vehicle speed is shown.
- Rebuild on app activation and external display connect/disconnect.

## Important limitations
- This is an experimental scaffold. It has not been compiled on this environment or tested on an iPhone.
- `com.apple.CarPlayApp` in the injection filter is a *candidate*, not confirmed for the user's iOS 15.8 build. Verify the actual process/bundle identifier first, then edit the filter. If the tweak is injected into the wrong process, remove it immediately.
- A `UIWindow` assigned to an external `UIScreen` may not overlay CarPlay due to scene/window routing and system UI restrictions. This prototype cannot guarantee HUD visibility on the car display.
- The speed value is intentionally unavailable until a legitimate source is selected. iOS has no universal public API that exposes vehicle speed in all CarPlay environments.
- The shortcut sheet is UIKit-based and may not be appropriate for use while driving; configure/test while parked. URL schemes require the target app to be installed and may be restricted by the host process.
- Layout `scale`, `opacity`, `x`, `y`, and `enabled` are stored via CFPreferences under domain `com.drivehud.tweak`.

## Build
Install Theos and its iOS SDK/toolchain on macOS or a supported Linux environment, then:

```sh
make clean
make package THEOS_PACKAGE_SCHEME=rootless
```

The package should be in `packages/`. Theos rootless mode sets the `/var/jb` install prefix and `iphoneos-arm64` package architecture. See the official docs:
- https://theos.dev/docs/rootless
- https://theos.dev/docs/packaging

## Find the actual CarPlay process on the iPhone
Connect over SSH while CarPlay is connected and run:

```sh
ps -A -o pid,comm,args | grep -i -E 'carplay|dashboard|nowplaying'
launchctl list | grep -i -E 'carplay|dashboard'
```

If available, inspect process executable paths:

```sh
for p in $(pgrep -if 'carplay|dashboard'); do
  echo "=== PID $p ==="
  launchctl procinfo "$p" 2>/dev/null
done
```

You can also inspect SpringBoard/CarPlay-related processes in a process viewer such as NewTerm + `ps`, or use `frida-ps -Uai` if Frida is already installed. The exact bundle ID may not appear in `ps`; `ps` gives process names, not necessarily bundle IDs.

Then:
1. Keep CarPlay connected and active while capturing the process list.
2. Disconnect CarPlay and repeat the command.
3. Compare results to identify processes that appear/disappear.
4. Use a process/bundle inspection tool to resolve the bundle ID for the candidate.
5. Update `layout/Library/MobileSubstrate/DynamicLibraries/DriveHUD.plist` to target only the verified process.
6. Rebuild and test with a recovery path available.

Do not broaden the filter to every process as a shortcut; injecting into SpringBoard or all apps can cause crashes or boot loops.

## Preferences
Values can be written using a plist editor or `defaults`-style tool that supports the target domain:
- `enabled`: boolean
- `scale`: 0.65–1.8
- `opacity`: 0.2–1.0
- `x`, `y`: normalized 0.0–1.0

## Next implementation steps
1. Verify process target and confirm HUD appears on the CarPlay display.
2. Add a proper Settings bundle / PreferenceLoader panel.
3. Add a real authorized speed provider (navigation app integration or compatible OBD device).
4. Add a CarPlay lifecycle adapter and robust restoration after verified connect/disconnect events.
5. Replace the generic UIKit shortcut sheet with a parked-only configuration flow.


## Optional: build with GitHub Actions
The project includes `.github/workflows/build.yml`. Push the project to a GitHub repository, open **Actions → Build DriveHUD deb → Run workflow**, and download the `DriveHUD-deb` artifact if the workflow succeeds. This builds on a macOS runner with Xcode's iOS SDK. The first build may expose source or toolchain errors; review the workflow log before installing anything on a device.
