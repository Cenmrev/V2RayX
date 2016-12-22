# V2RayX: A simple GUI for V2Ray on macOS
## what is V2Ray?
![V2Ray logo](https://raw.githubusercontent.com/v2ray/manual/master/resources/favicon-152.png)
[Project V2Ray](http://www.v2ray.com).

## Download V2RayX
[Releases](https://github.com/Cenmrev/V2RayX/releases)

## How to build
V2RayX.app is built by running one of the following commands in your terminal. You can install this via the command-line with curl.

`sh -c "$(curl -fsSL https://raw.githubusercontent.com/Cenmrev/V2RayX/master/compilefromsource.sh)"`

or step by step:

`git clone --recursive https://github.com/Cenmrev/V2RayX.git`

open V2RayX.xcodeproj and use Xcode to build V2RayX.

## How does V2RayX work
V2RayX provides a GUI to generate the config file for V2Ray. It includes V2Ray's binary executable in the app bundle. V2RayX starts and stops V2Ray with `launchd` of macOS.

V2RayX also allows users to change system proxy settings and switch proxy servers on the macOS menu bar.

### manually update v2ray-core
replace `V2RayX.app/Contents/Resources/v2ray` with the newest v2ray 
version from [v2ray-core 
repo](https://github.com/v2ray/v2ray-core/releases).

### Uninstall
V2RayX will create the following files and folders:

* `/Library/Application Support/V2RayX`
* `~/Library/Application Support/V2RayX`
* `~/Library/Preferences/projectv2ray.V2RayX.plist`

So, to totally uninstall V2RayX, just delete V2RayX.app and the files above. :)

##Acknowledge

V2RayX uses [GCDWebServer](https://github.com/swisspol/GCDWebServer) to provide a local pac server. V2RayX also uses many ideas and codes from [ShadowsocksX](https://github.com/shadowsocks/shadowsocks-iOS/tree/master), especially, the codes of [v2rays_sysconfig](https://github.com/Cenmrev/V2RayX/blob/master/v2rayx_sysconf/main.m) are simply copied from [shadowsocks_sysconf](https://github.com/shadowsocks/shadowsocks-iOS/blob/master/shadowsocks_sysconf/main.m) with some modifications.

## Donation

If Project V2Ray or V2RayX helped you, you can also help us by donation __in your will__. To donate to Project V2Ray, you may refer to [this page](https://www.v2ray.com/chapter_00/02_donate.html). To help this GUI program, you can send gift cards to `cenmrev@tutanota.de`.

## Disclaimer

The developer does not major in CS nor Software Engineer and currently is busy with grad school courses. So V2rayX will not be updated frequently. Users can replace V2RayX.app/Contents/Resources/v2ray with the newest v2ray-core downloaded from [https://github.com/v2ray/v2ray-core/releases](https://github.com/v2ray/v2ray-core/releases).

The developer currently does not have enough time to add more features to V2RayX, nor to merge PRs. However, forking and releasing your own version are always welcome.
