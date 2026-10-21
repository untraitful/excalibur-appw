#!/usr/bin/env bash
# Installs the release APK on the emulator, launches it, and records a
# screenshot and logcat so startup problems are visible from CI.
set -u
mkdir -p smoke
adb install -r apk/app-release.apk
adb logcat -c
adb shell am start -W -n dev.excalibur.excalibur/.MainActivity
sleep 25
adb exec-out screencap -p > smoke/screen.png
adb logcat -d > smoke/logcat.txt
adb shell pidof dev.excalibur.excalibur > smoke/pid.txt || echo "app not running" > smoke/pid.txt
grep -E "flutter|AndroidRuntime|FATAL|excalibur" smoke/logcat.txt | tail -100 || true
# Print the on-screen text so the result is readable straight from the job log.
adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
adb pull /sdcard/ui.xml smoke/ui.xml >/dev/null 2>&1
echo "== visible text =="
grep -oE '(text|content-desc)="[^"]+"' smoke/ui.xml | sort -u || echo "(none)"
