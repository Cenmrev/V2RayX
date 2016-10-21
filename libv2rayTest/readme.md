#尝试用动态库的方法加载V2Ray以及遇到的问题
main.go 修改自[v2ray.com/core/main/main.go](https://github.com/v2ray/v2ray-core/blob/v2.3.3/main/main.go)包含了两个函数loadV2Ray()和unloadV2Ray()，用 build.sh 可以将其编译为动态库并导出头文件 libv2ray.h。

main.c 是一个最简单的调用 libv2ray.dylib 的程序，编译命令为

`clang -L. -lv2ray main.c -o libv2raytest `

执行`./libv2raytest ./config` 可以成功加载libv2ray，并且能完成代理功能，但是很快就会崩溃。目前完全不知道怎么解决。

尝试在 archlinux 下进行类似的测试，libv2raytest 能坚持不崩溃的时间更长一些，但还是会崩溃。