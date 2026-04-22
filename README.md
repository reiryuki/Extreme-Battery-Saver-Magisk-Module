# Extreme Battery Saver Magisk Module

## DISCLAIMER
- Google app is owned by Google LLC.
- The MIT license specified here is for the Magisk Module only, not for Google app.

## Descriptions
- Extreme Battery Saver app by Google LLC
- Pauses apps while battery saver is activated to save more power

## Changelog

v1.18
- Fix wrong target in latest KernelSU

v1.17
- Fix isAtLeast methods
- Add Action button to clear app caches
- Remove luckypatcher detection and add "not enough space" detection at installation
- Fix bug in uninstall.sh

v1.16
- Android 15 (SDK 35) and up support with disable signature verification (does not patch runtime-permissions.xml)
- Fix Android 12.1 and bellow support
- FlipendoFrameworkOverlay.apk v1.2 (coreApp="true")
- Permission detection in app
- Fix runtime-permissions.xml patch in Android 14 and bellow

v1.15
- Fix conflict with modules_update while installing via recovery if Magisk installed
- Speed up granting permissions at installation
- Fix MagiskHide & SUList
- FlipendoFrameworkOverlay.apk v1.1

v1.14
- Fix grant permissions bug

v1.13
- Whitelist android.permission.QUERY_USERS

v1.12
- Add android.permission.ACCESS_SURFACE_FLINGER, android.permission.ROTATE_SURFACE_FLINGER, & android.permission.INTERNAL_SYSTEM_WINDOW
- Force debug for install log
- Checking each permissions at installation

v1.11
- Fix installation stuck and fatal exceptions in Android 11

v1.10
- Fix a fatal exception

v1.9
- Fix permissions
- Change patching method
- Update sepolicy rules

## Sources
- https://apkmirror.com com.google.android.flipendo by Google LLC
- libmagiskpolicy.so: Kitsune Mask R6687BB53

## Screenshots
- https://t.me/androidryukimods/405
- https://t.me/androidryukimods/418

## Requirements
- Android 11 (SDK 30) until 14 (SDK 34)
- Android 15 (SDK 35) and up with AOSP signatured ROM or disabled Android Signature Verification for non-AOSP sigantured ROM https://t.me/ryukinotes/81
- Magisk or Kitsune Mask or KernelSU or Apatch installed

## Installation Guide & Download Link
- If you are using KernelSU, you need to disable Unmount Modules by Default in KernelSU app settings and install https://github.com/KernelSU-Modules-Repo/meta-overlayfs or https://github.com/KernelSU-Modules-Repo/magic_mount_rs or https://github.com/KernelSU-Modules-Repo/hybrid_mount first depending on ROM compatibility
- Install this module via Magisk app or KernelSU app or Apatch app only
- Reboot
- If you are using KernelSU, you need to allow superuser list manually all package name listed in package.txt (and your home launcher app also) (enable show system apps) and reboot afterwards
- If you are using SUList, you need to allow list manually your home launcher app (enable show system apps) and reboot afterwards
- If android.permission.SUSPEND_APPS is not granted then reinstall the module again and reboot
- Open Extreme Battery Saver app, tap "When to use", choose "Ask every time" or "Always use"
- Enable your built-in battery saver (standar AOSP battery saver) and your apps will be paused immediately if "Always use" is choosen
- Tap the notification that appears if "Ask every time" is choosen to enable the Extreme Battery Saver and your apps will be paused

## Optionals
- Global: https://t.me/ryukinotes/35

## Troubleshootings
- Global: https://t.me/ryukinotes/34

## Support & Bug Report
- https://t.me/ryukinotes/54
- If you don't do above, issues will be closed immediately.

## Credits and Contributors
- @KaldirimMuhendisi
- https://t.me/androidryukimodsdiscussions
- You can contribute ideas about this Magisk Module here: https://t.me/androidappsportdevelopment

## Sponsors
- https://t.me/ryukinotes/25


