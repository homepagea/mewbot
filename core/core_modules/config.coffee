Fs       = require 'fs'
Path     = require 'path'
Fse      = require 'fs.extra'
Cps      = require 'child_process'
Moment   = require 'moment'
Coffee   = require 'coffee-script'
UUID     = require 'uuid'

checkModules = (cm,config,callback)->
    if config.modules
        module = null
        moduleCheckCallback = (exists)->
            if exists
                module = config.modules.shift()
                if module
                    cm.moduleExists module,moduleCheckCallback
                else
                    callback()
            else
                callback("module [#{module}] not found")

        moduleCheckCallback(true)
    else
        callback()

checkAdapters = (cm,config,callback) ->
    if config.adapters
        adapterArray = []
        if config.profile.MEWBOT_ADAPTER is undefined
            config.profile.MEWBOT_ADAPTER = []
        else if typeof config.profile.MEWBOT_ADAPTER is 'string'
            config.profile.MEWBOT_ADAPTER = config.profile.MEWBOT_ADAPTER.split(",")
        else
            return callback("config.profile.MEWBOT_ADAPTER is #{typeof config.profile.MEWBOT_ADAPTER}")
        for adapter of config.adapters
            idxAdapter = adapter.indexOf("$")
            adapterName = ""
            adapterIndex = ""
            if idxAdapter < 0
                adapterName = adapter
                adapterIndex = ""
            else
                adapterName = adapter.substr(0,idxAdapter)
                adapterIndex = adapter.substr(idxAdapter+1)
            adapterArray.push {
                name : adapterName,
                index : adapterIndex,
                config : config.adapters[adapter]
            }
        adapterArrayCallback = ->
            adapter = adapterArray.shift()
            if adapter
                cm.adapterExists adapter.name,(exists)->
                    if exists
                        profileFileContent = ""
                        profileFile = getLocationFile(__dirname,"..","..","var","conf","@#{adapter.name}$#{adapter.index}")
                        for key of adapter.config
                            if typeof key is 'string' and typeof adapter.config[key] isnt 'object'
                                profileFileContent = "#{profileFileContent}\n#{key}=#{adapter.config[key]}"
                        Fs.writeFile profileFile,profileFileContent,(err)->
                            if err
                                callback(err)
                            else
                                adapterArrayCallback()
                    else
                        callback("adapter [#{adapter.name}] not found")
            else
                if config.profile.MEWBOT_ADAPTER.length
                    config.profile.MEWBOT_ADAPTER = config.profile.MEWBOT_ADAPTER.toString()
                else
                    config.profile.MEWBOT_ADAPTER = ""
                callback()
        adapterArrayCallback()
    else
        callback()
checkServices = (cm,config,callback) ->
    if config.services
        if config.profile.MEWBOT_SERVICE is undefined
            config.profile.MEWBOT_SERVICE = []
        else if typeof config.profile.MEWBOT_SERVICE is 'string'
            config.profile.MEWBOT_SERVICE = config.profile.MEWBOT_SERVICE.split(",")
        else
            return callback("config.profile.MEWBOT_SERVICE is #{typeof config.profile.MEWBOT_SERVICE}")
        serviceArray = []
        for skey of config.services
            serviceArray.push {
                name : skey
                config : config.services[skey]
            }
        serviceBlock = null
        serviceSaveCallback = (exists)->
            serviceBlock = serviceArray.shift()
            if serviceBlock
                cm.serviceExists serviceBlock.name,(exists)->
                    if exists
                        Fs.writeFile Path.join(__dirname,"..","..","var","conf","!#{serviceBlock.name}"),JSON.stringify(serviceBlock.config),(err)->
                            if err
                                callback(err)
                            else
                                if (serviceBlock.name in config.profile.MEWBOT_SERVICE) is false
                                    config.profile.MEWBOT_SERVICE.push serviceBlock.name
                                serviceSaveCallback()
                    else
                        callback("service [#{serviceBlock.name}] not found")
            else
                if config.profile.MEWBOT_SERVICE.length
                    config.profile.MEWBOT_SERVICE = config.profile.MEWBOT_SERVICE.toString()
                else
                    config.profile.MEWBOT_SERVICE = ""
                callback()
        serviceSaveCallback()
    else
        callback()

class ConfigModule
    constructor : (@mew)->

    readAndConfig : (configFile,callback)->
        Fs.readFile configFile,(err,data)=>
            config = null
            switch Path.extname(configFile)
                when ".coffee"
                    config = Coffee.eval(data.toString())
                when ".js"
                    eval("config = #{data.toString()}")
                when ".json"
                    config = JSON.parse(data.toString())
                else
                    callback("type not supported")
            @mew.logger.debug "loading config from : #{configFile} , with config : #{JSON.stringify(config,null,4)}"
            if config.profile is undefined
                config.profile = {}
            checkModules @,config,(err)=>
                if err
                    callback(err)
                else
                    checkServices @,config,(err)=>
                        if err
                            callback(err)
                        else
                            checkAdapters @,config,(err)=>
                                profileFileContent = ""
                                profileFile = Path.join(__dirname,"..","..","var","conf","default")
                                for key of config.profile
                                    if typeof key is 'string' and typeof config.profile[key] isnt 'object'
                                        profileFileContent = "#{profileFileContent}\n#{key}=#{config.profile[key]}"
                                Fs.writeFile profileFile,profileFileContent,callback

    serviceExists : (service,callback)->
        @moduleExists "!#{service}",callback

    adapterExists : (adapter,callback)->
        @moduleExists "@#{adapter}",callback

    moduleExists : (module,callback)->
        Fs.exists Path.join(__dirname,"..","..","mew_modules",module),callback

module.exports = ConfigModule   