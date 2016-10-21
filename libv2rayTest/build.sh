if [ "$(uname)" == "Darwin" ]; then
    go build -x -tags json -buildmode=c-shared -o libv2ray.dylib ./main.go        
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    go build -x -tags json -buildmode=c-shared -o libv2ray.so ./main.go
fi

