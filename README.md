
# Android example
<img width="373" height="858" alt="android" src="https://github.com/user-attachments/assets/3ea1909e-95fa-4de6-8519-8cbf2aecb4f2" />


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
