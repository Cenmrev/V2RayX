isbeta=$(git describe --abbrev=0 --tags | grep beta)
if [[ "$isbeta" != "" ]] 
then 
    xcodebuild -project V2RayX.xcodeproj -target V2RayX -configuration Debug -s
    cd build/Debug/
else
    cd build/Release/
fi
zip -r V2RayX.app.zip V2RayX.app
cd ../..