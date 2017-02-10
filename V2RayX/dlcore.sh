VERSION="v2.17.1"


cd $SRCROOT
output="v0"
if [[ -f ./v2ray-core-bin/v2ray ]]; then
    output=$(./v2ray-core-bin/v2ray --version)
fi
existingVersion=${output:6:${#VERSION}}
if [ "$VERSION" != "$existingVersion" ]; then
    curl -s -L --create-dirs -o v2ray-core-bin/v2ray-macos.zip https://github.com/v2ray/v2ray-core/releases/download/${VERSION}/v2ray-macos.zip
    if [[ $? == 0 ]]; then
        cd v2ray-core-bin
        unzip -o v2ray-macos.zip
        mv v2ray-${VERSION}-macos/v2ray v2ray
        chmod +x ./v2ray
        rm -r v2ray-*
        exit 0
    else
        echo "download failed!"
        exit 1
    fi
else 
    exit 0
fi

