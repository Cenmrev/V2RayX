//
//  main.c
//  libv2rayTest
//
//  Copyright © 2016 Project V2Ray. All rights reserved.
//

#include <stdio.h>
#include "libv2ray.h"

int count(const char* string) {
    int result = 0;
    if (string == NULL) {
        return 0;
    }
    while (string[result] != '\0') {
        result++;
    }
    return result;
}

int main(int argc, const char * argv[]) {
    GoString configPath;
    configPath.p = argv[1];
    configPath.n = count(argv[1]);
    loadV2Ray(configPath);
    getchar();
    return 0;
}

