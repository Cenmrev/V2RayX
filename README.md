![V2RayX](https://raw.githubusercontent.com/Cenmrev/V2RayX/master/V2RayX/Assets.xcassets/AppIcon.appiconset/vx128.png)

# V2RayX: A simple GUI for V2Ray on macOS

## What is V2Ray?

![V2Ray logo](https://raw.githubusercontent.com/v2ray/manual/master/resources/favicon-152.png)

[Project V2Ray](http://www.v2ray.com).

__YOU SHOULD READ V2RAY'S OFFICIAL INSTRUCTION BEFORE USING V2RAYX!__

## Download V2RayX

~~Download from [Releases](https://github.com/Cenmrev/V2RayX/releases).~~ 
 __Precompiled binary version will no longer be provided in the release page.__

By [Homebrew-Cask](https://caskroom.github.io/).

```sh
brew cask install v2rayx
```

## How to build

V2RayX.app is built by running one of the following commands in your terminal. You can install this via the command-line with curl.

`sh -c "$(curl -fsSL https://raw.githubusercontent.com/Cenmrev/V2RayX/master/compilefromsource.sh)"`

or step by step:

`git clone --recursive https://github.com/Cenmrev/V2RayX.git`

open V2RayX.xcodeproj and use Xcode to build V2RayX.

## How does V2RayX work

V2RayX provides a GUI to generate the config file for V2Ray. It includes V2Ray's binary executable in the app bundle. V2RayX starts and stops V2Ray with `launchd` of macOS.

V2RayX also allows users to change system proxy settings and switch proxy servers on the macOS menu bar.

As default, V2RayX will open a socks5 proxy at port `1081` as the main inbound, as well as a http proxy at port `8001` as an inboundDetour.

### auto-run on login

Open macOS System Preferences -> Users & Group -> Login Items, add V2RayX.app to
the list.

### manually update v2ray-core
replace `V2RayX.app/Contents/Resources/v2ray` with the newest v2ray 
version from [v2ray-core 
repo](https://github.com/v2ray/v2ray-core/releases). However, compatibility is not guaranteed.

### Uninstall

V2RayX will create the following files and folders:

* `/Library/Application Support/V2RayX`
* `~/Library/Application Support/V2RayX`
* `~/Library/Preferences/cenmrev.V2RayX.plist`

So, to totally uninstall V2RayX, just delete V2RayX.app and the files above. :)

## Acknowledge

V2RayX uses [GCDWebServer](https://github.com/swisspol/GCDWebServer) to provide a local pac server. V2RayX also uses many ideas and codes from [ShadowsocksX](https://github.com/shadowsocks/shadowsocks-iOS/tree/master), especially, the codes of [v2rays_sysconfig](https://github.com/Cenmrev/V2RayX/blob/master/v2rayx_sysconf/main.m) are simply copied from [shadowsocks_sysconf](https://github.com/shadowsocks/shadowsocks-iOS/blob/master/shadowsocks_sysconf/main.m) with some modifications.

## Donation

If Project V2Ray or V2RayX helped you, you can also help us by donation __in your will__. To donate to Project V2Ray, you may refer to [this page](https://www.v2ray.com/chapter_00/02_donate.html).

## Disclaimer

This tool is mainly for personal usage. For professional users and technique 
support, commercial software like proxifier is recommended. Please refer to [#60](https://github.com/Cenmrev/V2RayX/issues/60#issuecomment-369531443).

The developer does not major in CS nor Software Engineer and currently is busy with grad school courses. So V2rayX will not be updated frequently. Users can replace V2RayX.app/Contents/Resources/v2ray with the newest v2ray-core downloaded from [https://github.com/v2ray/v2ray-core/releases](https://github.com/v2ray/v2ray-core/releases).

The developer currently does not have enough time to add more features to V2RayX, nor to merge PRs. However, forking and releasing your own version are always welcome.
