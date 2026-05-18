
# Android example
<img width="373" height="858" alt="android" src="https://github.com/user-attachments/assets/3ea1909e-95fa-4de6-8519-8cbf2aecb4f2" />

  Key lessons / gotchas we hit:

  1. Homebrew did not install Koala
     brew install --cask android-studio installed Android Studio 2025.3, not Koala. For the constraint, we needed the official archive version: Android Studio Koala 2024.1.1 Patch 2.
  2. Koala-compatible AGP is 8.5.2
     The project had AGP 8.6.1, which lines up more with Koala Feature Drop, not the stricter Koala 2024.1.1 pairing. We pinned:
     com.android.tools.build:gradle:8.5.2
  3. Capacitor 7 requires Java 21
     The repeated failure:
     invalid source release: 21
     was because Capacitor Android 7 sets Java 21 compatibility. CLI eventually worked, but Android Studio kept using its bundled JBR.
  4. Android Studio had its own JDK override
     The real hidden issue was:
     android/.gradle/config.properties
     pointing to:
     /Applications/Android Studio.app/Contents/jbr/Contents/Home

     We changed it to JDK 21:
     /Users/username/Library/Java/JavaVirtualMachines/openjdk-21.0.1/Contents/Home
  5. SDK existed, but Gradle could not see it
     Android Studio installed the SDK at:
     ~/Library/Android/sdk

     We added:
     android/local.properties
     with:
     sdk.dir=/Users/choipco/Library/Android/sdk
  6. AGP 8.5.2 warns on compileSdk 35
     That warning is expected because AGP 8.5.2 was tested up to SDK 34. Since Cap 7 generated SDK 35 and the build works, we suppressed only the warning:
     android.suppressUnsupportedCompileSdk=35
  7. Angular needed newer Node
     Shell Node was 18.18.0; Angular 19 wants at least 18.19. Using installed Node 20.18.1 fixed the frontend build.
  8. Android native payload needed to be generalized
     The UI was named


     
# mx2-protoware

Two-app prototype repo. Each subdirectory is an independent build.

| Folder | Type | Stack |
|---|---|---|
| `native/` | Native iOS app | Swift / SwiftUI / Xcode |
| `capacitor/` | Hybrid web-to-iOS app | Angular 19 + Capacitor 7 |

---

## capacitor — build & run

**Prerequisites (one-time)**

```bash
# CocoaPods must be installed
brew install cocoapods
# or: sudo gem install cocoapods
```

**Every time you want to build and run in Xcode:**

```bash
cd /Users/your-username/path/to/mx2-protoware/capacitor

npm install                  # install/sync node packages
npm run build                # compile Angular → dist/protoware-capacitor/browser/
npx cap sync ios             # copy web build into ios/, runs pod install automatically

open ios/App/App.xcworkspace # open in Xcode — must be .xcworkspace not .xcodeproj
```

Then in Xcode: select your simulator or device and hit **Run**.

**Run in browser only (no Xcode needed):**

```bash
npm start
```

**If pods get out of sync** (e.g. after adding a Capacitor plugin):

```bash
cd /Users/your-username/path/to/mx2-protoware/capacitor/ios/App
pod install
```

**Key things to know:**
- Always open `App.xcworkspace` — opening `App.xcodeproj` directly skips CocoaPods and will fail to build
- `npx cap sync` = `npx cap copy` + `npx cap update` + pod install — use this rather than `cap copy` alone
- If Xcode says it can't find a module after adding a new Capacitor plugin, run `pod install` manually then clean build (`Cmd+Shift+K`)

---

## native — build & run

Open `native/protoware.xcodeproj` in Xcode, select a simulator or device, and hit Run.

> Xcode 26 required — [download from Apple](https://developer.apple.com/download/all/?q=xcode%2026.0)
