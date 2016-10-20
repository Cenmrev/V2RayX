package main

import (
    "C"
    
    "os"
    "io"

	"v2ray.com/core"
    "v2ray.com/core/common/log"
    _ "v2ray.com/core/tools/conf"

)

func main() {

}


var running = false
//export loadV2Ray
func loadV2Ray(configFile string) {
    var configInput io.Reader
    fixedFile := os.ExpandEnv(configFile)
    file, err := os.Open(fixedFile)
    if err != nil {
        log.Error("COnfig file not readable: ", err)
        return
    }
    configInput = file
    config, err := core.LoadConfig(core.ConfigFormat_JSON, configInput)
    if err != nil {
        log.Error("filed to read config file (", configFile)
        log.Error(fixedFile, configInput)
        return
    }
    vPoint, err := core.NewPoint(config)
    if err != nil {
        log.Error("failed to create Point server", err)
        return
    }
    err = vPoint.Start()
    if err != nil {
        log.Error("Error starting point server", err)
        return
    }

    running = true
}

//export unloadV2Ray
func unloadV2Ray(configFile string) {
    running = false
}
