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
