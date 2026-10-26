# Cleaning up the Sony BRAVIA 2 (K-55S25B)

The TV runs Google TV, so we can swap the home screen, switch off the ad surfaces and remove preinstalled apps. None of this needs root, and nothing is deleted. Every change is a "disable" that `restore-tv.sh` or a factory reset reverses.

## What you end up with

- A plain home screen with only your apps (Projectivy Launcher), no "Top picks" or sponsored rows
- No Ambient Mode screensaver pushing content
- Sony and Indian OTT preloads you never open, gone from the app list
- Ads and trackers blocked at the DNS level across the whole TV (AdGuard DNS)
- Optional: YouTube without ads via SmartTube

## Do these on the TV first (10 minutes, no laptop)

1. **Apps only mode, if you want the quick version.** Settings > Accounts & Sign In > your account > Apps only mode. This kills recommendations in one switch. The catch is that it also turns off Google Assistant and some Google features. If that's enough for you, stop here.
2. **Turn off autoplay previews.** Settings > System > (look for "Enable video previews" / "Enable audio previews") and switch both off.
3. **Turn off viewing tracking.** Go through Settings > Privacy and Sony's "Samba Interactive TV" / viewing information option if it's there, and decline everything optional.
4. **Install from the Play Store on the TV:** "Projectivy Launcher" (new home screen). Optional: "Downloader by AFTVnews" if you want SmartTube (its download code is on smarttubeapp.github.io).

## Connect a laptop over Wi-Fi

1. On the TV: Settings > System > About > scroll to "Android TV OS build" and press OK on it 7 times. You'll see "You are now a developer".
2. Settings > System > Developer options > turn on **USB debugging**.
3. Note the TV's IP address: Settings > Network & Internet > your Wi-Fi network.
4. On the laptop, install Android platform-tools:
   - Mac: `brew install android-platform-tools`
   - Windows: download "SDK Platform-Tools for Windows" from developer.android.com, unzip, and run the scripts from Git Bash or WSL
5. Laptop and TV must be on the same Wi-Fi.

## Run it

```bash
./clean-tv.sh 192.168.1.23        # your TV's IP
```

The first time, the TV shows "Allow USB debugging?". Tick "Always allow" and press OK, then run the command again.

The script asks before every change. It goes through five steps: Google bloat, voice assistant, Sony/OTT preloads it finds on your set, DNS ad blocking, and the home screen swap. Say no to anything you're unsure about. You can rerun it any time.

For the home screen, use Projectivy's own "Override Home button" setting first. Disable the Google TV launcher completely only if that override feels laggy.

## Undo

```bash
./restore-tv.sh 192.168.1.23 disabled-20261026-203000.txt   # undo one run
./restore-tv.sh 192.168.1.23 all                            # re-enable everything
```

If the TV ever gets stuck with no home screen, a factory reset brings it all back: Settings > System > About > Reset, or hold the power button on the TV itself.

## Worth knowing

- Sony firmware updates sometimes re-enable apps. Rerun the script after a big update.
- If you disable Netflix, Prime Video or YouTube, the matching button on the remote stops working.
- When you're done, switch USB debugging off again.
