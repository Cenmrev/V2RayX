# V2RayX: A simple GUI for V2Ray on macOS

[![Build Status](https://travis-ci.org/Cenmrev/V2RayX.svg?branch=master)](https://travis-ci.org/Cenmrev/V2RayX)

## What is V2Ray?

__READ THIS__: [Project V2Ray](http://www.v2ray.com).

__YOU SHOULD READ V2RAY'S OFFICIAL INSTRUCTION BEFORE USING V2RAYX!__

Other V2Ray clients on macOS: [V2RayU](https://github.com/yanue/v2rayu).
(Not related to or endorsed by authors of this repo. USE AT YOUR OWN RISK.)

## Download V2RayX

Download from [Releases](https://github.com/Cenmrev/V2RayX/releases). (compiled by [travis-ci.org](https://travis-ci.org/Cenmrev/V2RayX)).

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

V2RayX provide three modes:
* Global Mode: V2RayX asks macOS to route all internet traffic to v2ray core if the network traffic obeys operating system's network rules.
* PAC Mode: macOS will determine the routing based on a pac file and some traffic may be routed to v2ray core.
* Manual Mode: V2RayX will not modify any macOS network settings, but only start or stop v2ray core.

Options in menu list `Routing Rule` determine how v2ray core deals with incoming traffic. Core routing rules apply to all three modes above.

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
