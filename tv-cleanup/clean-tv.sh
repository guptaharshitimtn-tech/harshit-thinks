#!/usr/bin/env bash
# Clean up a Sony BRAVIA Google TV (built for K-55S25B / BRAVIA 2) over ADB.
# Nothing is deleted: apps are disabled for user 0 and can be brought back with restore-tv.sh.
#
# Usage: ./clean-tv.sh <tv-ip-address>
set -u

TV="${1:-}"
[ -z "$TV" ] && { echo "Usage: $0 <tv-ip-address>   (find it in TV Settings > Network & Internet)"; exit 1; }
command -v adb >/dev/null || { echo "adb not found. Install Android platform-tools first (see README)."; exit 1; }

LOG="disabled-$(date +%Y%m%d-%H%M%S).txt"

adb connect "$TV:5555" >/dev/null
if ! adb -s "$TV:5555" get-state >/dev/null 2>&1; then
  echo "Could not connect. Check the TV screen for an 'Allow USB debugging?' prompt, tick 'Always allow', then rerun."
  exit 1
fi
A=(adb -s "$TV:5555" shell)
echo "Connected to $("${A[@]}" getprop ro.product.model | tr -d '\r') on Android $("${A[@]}" getprop ro.build.version.release | tr -d '\r')"

"${A[@]}" pm list packages | sed 's/package://' | tr -d '\r' | sort > "packages-before.txt"
echo "Saved the full package list to packages-before.txt"

has() { grep -qx "$1" packages-before.txt; }

ask_disable() {  # $1 package, $2 what it is
  has "$1" || return
  read -r -p "Disable $1  ($2)? [y/N] " r
  if [[ "$r" =~ ^[Yy]$ ]]; then
    if "${A[@]}" pm disable-user --user 0 "$1" | grep -q "new state"; then
      echo "$1" >> "$LOG"; echo "  disabled"
    else
      echo "  could not disable (protected system app), skipped"
    fi
  fi
}

echo
echo "== 1. Google bloat and ad surfaces =="
ask_disable com.google.android.apps.tv.dreamx          "Ambient Mode screensaver, shows promoted content"
ask_disable com.google.android.videos                  "Google TV / Play Movies store"
ask_disable com.google.android.play.games              "Play Games"
ask_disable com.google.android.youtube.tvmusic         "YouTube Music"
ask_disable com.google.android.youtube.tvkids          "YouTube Kids"
ask_disable com.google.android.feedback                "Google feedback reporter"
ask_disable com.google.android.tvrecommendations       "recommendation feed provider"
echo "Keep: Play Store, Chromecast (com.google.android.apps.mediashell), Sony TV app (com.sony.dtv.tvx)."

echo
echo "== 2. Voice assistant =="
echo "Disabling this kills the mic button and voice search. Skip it if anyone at home uses voice."
ask_disable com.google.android.katniss                 "Google Assistant / voice search"

echo
echo "== 3. Preinstalled Sony and streaming apps found on this TV =="
echo "Say yes only to apps you never open. Netflix/Prime/YouTube buttons on the remote stop working if you disable those apps."
grep -Ei 'sony|samba|netflix|amazon|hotstar|jio|zee5|sonyliv|erosnow|hungama|spotify|gaana|disney|apple' packages-before.txt \
  | grep -Ev '^com\.sony\.dtv\.(tvx|tvinput|settings|systemui|osat|hdmicec|inputs)' \
  | grep -Ev 'com\.sony\.(dtv\.)?.*(setting|framework|provider|service|system|input|hdmi|tuner|remote|audio|picture)' \
  | while read -r p; do ask_disable "$p" "preinstalled app" </dev/tty; done

echo
echo "== 4. Network ad and tracker blocking (AdGuard DNS) =="
read -r -p "Route the TV's DNS through AdGuard to block ads and trackers system-wide? [y/N] " r
if [[ "$r" =~ ^[Yy]$ ]]; then
  "${A[@]}" settings put global private_dns_mode hostname
  "${A[@]}" settings put global private_dns_specifier dns.adguard-dns.com
  echo "private_dns" >> "$LOG"; echo "  done. If an app breaks, run restore-tv.sh."
fi

echo
echo "== 5. Replace the home screen =="
if has com.spocky.projengmenu; then
  echo "Projectivy is installed. Two ways to make it the home screen:"
  echo "  Safe:   in Projectivy settings, turn on 'Override Home button' (uses an accessibility service). Recommended."
  echo "  Strong: disable the Google TV launcher completely. Cleaner, but a factory reset is the fallback if the TV gets stuck."
  read -r -p "Do the strong version and disable the Google TV launcher? [y/N] " r
  if [[ "$r" =~ ^[Yy]$ ]]; then
    for p in com.google.android.apps.tv.launcherx com.google.android.tungsten.setupwraith; do
      has "$p" && "${A[@]}" pm disable-user --user 0 "$p" >/dev/null && echo "$p" >> "$LOG"
    done
    echo "  done. Press Home on the remote and pick Projectivy if asked."
  fi
else
  echo "Install 'Projectivy Launcher' from the Play Store on the TV, then rerun this script for this step."
fi

echo
[ -f "$LOG" ] && echo "Changes logged to $LOG. Undo them with: ./restore-tv.sh $TV $LOG" || echo "No changes made."
