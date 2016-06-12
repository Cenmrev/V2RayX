# A simple GUI for V2Ray
## what is V2Ray?
[Project V2Ray](http://www.v2ray.com).

## Download
[Releases](https://github.com/Cenmrev/V2RayX/releases)

## How to build
`git clone --recursive https://github.com/Cenmrev/V2RayX.git`

open V2RayX.xcodeproj and use Xcode to build V2RayX.

## How does V2RayX work
V2RayX provides a GUI to generate the config file for V2Ray. It includes V2Ray's binary executable(v1.7) in the Resources folder. V2RayX starts and stops V2Ray with `launchd` of OS X.

V2RayX also allows users to toggle system proxy and switch proxy servers on the OS X menu bar.

### Uninstall
V2RayX will create the following files and folders:

* `/Library/Application Support/V2RayX`
* `~/Library/Application Support/V2RayX`
* `~/Library/Preferences/projectv2ray.V2RayX.plist`

So, to totoally uninstall V2RayX, just delete V2RayX.app and the files above. :)

## To do
* Localization for Chinese language
* a more detailed configuration window

##Acknowledge
V2RayX uses [GCDWebServer](https://github.com/swisspol/GCDWebServer) to provide a local pac server. V2RayX also uses many ideas and codes from [ShadowsocksX](https://github.com/shadowsocks/shadowsocks-iOS/tree/master), especially, the codes of [v2rays_sysconfig](https://github.com/Cenmrev/V2RayX/blob/master/v2rayx_sysconf/main.m) are simply copied from [shadowsocks_sysconf](https://github.com/shadowsocks/shadowsocks-iOS/blob/master/shadowsocks_sysconf/main.m) with some modifications.