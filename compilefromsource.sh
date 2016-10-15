#!/bin/sh

#  compilefromsource.sh
#  V2RayX
#
#  Created by Cenmrev on 10/15/16.
#  Copyright © 2016 Project V2Ray. All rights reserved.

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


if [[ ! -f /Applications/Xcode.app/Contents/MacOS/Xcode ]]; then
    echo "Xcode is needed to build V2RayX, Please install Xcode from App Store!"
    echo "编译 V2RayX 需要 Xcode.app，请从 App Store 里安装 Xcode."
else
    echo "-- downloading source code --"
    echo "-- 正在下载源码 --"
    git clone --recursive https://github.com/Cenmrev/V2RayX.git
    cd V2RayX
    echo "-- start building V2RayX --"
    echo "-- 开始编译 V2RayX --"
    cd V2RayX.git
    xcodebuild -project V2RayX.xcodeproj -target V2RayX -configuration Release
    if [[ $? == 0 ]]; then
        echo "-- build succeeded --"
        echo "-- 编译成功 --"
        echo "Move V2RayX.app to the folder /Applications or not? 是否将编译得到的 V2RayX.app 移到应用程序文件夹？(yes/no)"
        read -r a
        if [[ $a == "yes" ]]; then
            moveToTrash /Applications/V2RayX.app # delete old version
            mv ./build/Release/V2RayX.app /Applications/
            echo "Delete source codes or not? 是否删除下载的源码？(yes/no)"
            read -r a 
            if [[ $a == "yes" ]]; then
                cd ..
                moveToTrash V2RayX
            fi
        else 
            echo "V2RayX.app: $(pwd)/build/Release/V2RayX.app"
        fi
    else
        echo "-- build failed --"
        echo "-- 编译失败 --"
    fi
fi


