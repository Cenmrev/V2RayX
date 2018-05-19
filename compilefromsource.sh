#!/bin/sh

#  compilefromsource.sh
#  V2RayX
#
#  Created by Cenmrev on 10/15/16.
#  Copyright © 2016 Cenmrev. All rights reserved.

# http://apple.stackexchange.com/questions/50844/how-to-move-files-to-trash-from-command-line
function moveToTrash () {
  local path
  for path in "$@"; do
    # ignore any arguments
    if [[ "$path" = -* ]]; then :
    else
      # remove trailing slash
      local mindtrailingslash=${path%/}
      # remove preceding directory path
      local dst=${mindtrailingslash##*/}
      # append the time if necessary
      while [ -e ~/.Trash/"$dst" ]; do
        dst="`expr "$dst" : '\(.*\)\.[^.]*'` `date +%H-%M-%S`.`expr "$dst" : '.*\.\([^.]*\)'`"
      done
      mv "$path" ~/.Trash/"$dst"
    fi
  done
}

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NORMAL='\033[0m'
datetime=$(date "+%Y-%m-%dTIME%H%M%S")
if [[ ! -f /Applications/Xcode.app/Contents/MacOS/Xcode ]]; then
    echo "${RED}Xcode is needed to build V2RayX, Please install Xcode from App Store!${NORMAL}"
    echo "${RED}编译 V2RayX 需要 Xcode.app，请从 App Store 里安装 Xcode.${NORMAL}"
else
    echo "${BOLD}-- Downloading source code --${NORMAL}"
    echo "${BOLD}-- 正在下载源码 --${NORMAL}"
    git clone --recursive https://github.com/Cenmrev/V2RayX.git "V2RayX${datetime}"
    cd "V2RayX${datetime}"
    echo "${BOLD}-- Start building V2RayX --${NORMAL}"
    echo "${BOLD}-- 开始编译 V2RayX --${NORMAL}"
    xcodebuild -project V2RayX.xcodeproj -target V2RayX -configuration Release
    if [[ $? == 0 ]]; then
        echo "${GREEN}-- Build succeeded --${NORMAL}"
        echo "${GREEN}-- 编译成功 --${NORMAL}"
        echo "${BOLD}V2RayX.app: $(pwd)/build/Release/V2RayX.app${NORMAL}"
    else
        echo "${RED}-- Build failed --${NORMAL}"
        echo "${RED}-- 编译失败 --${NORMAL}"
    fi
fi


