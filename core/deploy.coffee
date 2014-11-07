Path           = require 'path'
Fs             = require 'fs'
Log            = require 'log'
Os             = require 'os'
Fse            = require 'fs.extra'
checkPermission = (file, mask, cb)->
    Fs.stat file,(error, stats)->
        if (error)
            cb(error,false);
        else
            cb(null,!!(mask & parseInt((stats.mode&parseInt("777",8)).toString(8)[0])),stats.mode)

makeTargetExecutable = (file,callback)->
    checkPermission file,1,(err,execute,mode)->
        return callback(err) if err
        if execute is false
            Fs.chmod file,mode|parseInt("111",8),(err)->
                if err
                    callback(err)
                else
                    callback()
        else
            callback()

getLocationFile = (location,path)->
    if path
        return Path.join location,path
    else
        return location

makeLocationDir = (location,path)->
    file = getLocationFile(location,path)
    if Fs.existsSync(file) is false
        Fse.mkdirRecursiveSync file
    return file

getSourceFile = (path)->
    if path
        Path.join(__dirname,"..",path)
    else
        return Path.join(__dirname,"..")

initLocationDataCopy  = (mew,location,config,callback)->
    if config.datas and Array.isArray(config.datas)
        dataCopyCallback = ->
            makeLocationDir(location,"/var/data")
            data = config.datas.shift()
            if data
                dataFile = mew.getDataFile(data)
                Fs.exists dataFile,(exists)->
                    if exists
                        Fs.stat dataFile,(err,stat)->
                            if err
                                callback(err)
                            else
                                if stat.isDirectory()
                                    Fse.overwriteRecursive dataFile,makeLocationDir(location,"/var/data/#{data}"),(err)->
                                        if err
                                            callback(err)
                                        else
                                            dataCopyCallback()
                                else
                                    Fse.overwrite dataFile,getLocationFile(location,"/var/data/#{data}"),(err)->
                                        if err
                                            callback(err)
                                        else
                                            dataCopyCallback()
                    else
                        callback("data file to copy : [#{data}] doesnt exists")
            else
                callback()
        dataCopyCallback()
    else
        callback()
initLocationBasicHirastructor = (location,callback)->
    Fse.overwriteRecursive getSourceFile("node_modules"),makeLocationDir(location,"node_modules"),(err)->
        return callback(err) if err
        Fse.overwriteRecursive getSourceFile("core"),makeLocationDir(location,"core"),(err)->
            return callback(err) if err
            Fse.overwriteRecursive getSourceFile("bin"),makeLocationDir(location,"bin"),(err)->
                return callback(err) if err
                Fse.overwrite getSourceFile("Procfile"),getLocationFile(location,"Procfile"),(err)->
                    return callback(err) if err
                    Fse.overwrite getSourceFile("README.md"),getLocationFile(location,"README.md"),(err)->
                        return callback(err) if err
                        Fse.overwrite getSourceFile("package.json"),getLocationFile(location,"package.json"),(err)->
                            makeLocationDir(location,"/var/conf")
                            makeLocationDir(location,"/mew_modules")
                            if process.platform isnt "win32"
                                makeTargetExecutable getLocationFile(location,"/bin/mewbot.sh"),(err)->
                                    return callback(err) if err
                                    makeTargetExecutable getLocationFile(location,"/bin/mewbot"),(err)->
                                        return callback(err) if err
                                        makeTargetExecutable getLocationFile(location,"/node_modules/coffee-script/bin/coffee"),(err)->
                                            return callback(err) if err
                                            makeTargetExecutable getLocationFile(location,"/node_modules/forever/bin/forever"),(err)->
                                                return callback(err) if err
                                                makeTargetExecutable getLocationFile(location,"/node_modules/forever/bin/monitor"),(err)->
                                                    return callback(err) if err
                                                    callback()
                            else
                                callback()

initIgnoreProfile = (location,config,callback)->
    if config.ignores and Array.isArray(config.ignores)
        ignoreFileContent = ""
        for ignore in config.ignores
            ignoreFileContent = "#{ignoreFileContent}\n#{ignore}"
        ignoreFile = getLocationFile(location,".gitignore")
        Fs.writeFile ignoreFile,ignoreFileContent,callback
    else
        callback()


initLocationProfile = (location,config,callback)->
    if config.profile
        profileFileContent = ""
        profileFile = getLocationFile(location,"/var/conf/default")
        for key of config.profile
            if typeof key is 'string' and typeof config.profile[key] is 'string'
                profileFileContent = "#{profileFileContent}\n#{key}=#{config.profile[key]}"
        Fs.writeFile profileFile,profileFileContent,callback
    else
        callback()

initLocationModule = (location,config,callback)->
    moduleArray = []
    if config.modules and Array.isArray(config.modules)
        for module in config.modules
            if Fs.existsSync(getSourceFile("/mew_modules/#{module}/package.json"))
                moduleArray.push module
    moduleArrayCallback = ->
        module = moduleArray.shift()
        if module
            Fse.overwriteRecursive getSourceFile("/mew_modules/#{module}"),makeLocationDir(location,"/mew_modules/#{module}"),(err)->
                if err
                    callback(err)
                else
                    moduleArrayCallback()
        else
            callback()
    moduleArrayCallback()

initLocationService = (location,config,callback)->
    serviceArray = []
    if config.services
        for service of config.services
            if Fs.existsSync(getSourceFile("/mew_modules/!#{service}/package.json"))
                serviceArray.push {
                    name : service,
                    config : config.services[service]
                }
    serviceArrayCallback = =>
        service = serviceArray.shift()
        if service
            Fs.writeFile getLocationFile(location,"/var/conf/!#{service.name}"),JSON.stringify(service.config),(err)->
                return callback(err) if err
                Fse.overwriteRecursive getSourceFile("/mew_modules/!#{service.name}"),makeLocationDir(location,"/mew_modules/!#{service.name}"),(err)->
                    if err
                        callback(err)
                    else
                        if typeof config.profile is 'undefined'
                            config.profile={}
                        if config.profile.MEWBOT_SERVICE
                            config.profile.MEWBOT_SERVICE = "#{config.profile.MEWBOT_SERVICE},#{service.name}"
                        else
                            config.profile.MEWBOT_SERVICE = "#{service.name}"
                        serviceArrayCallback()
        else
            callback()
    serviceArrayCallback()

class DeployerManager
    constructor : (@mew)->

    ###
    deploy mewbot to target location : 
    config file format : {
        profile : {
                key value pair write to default profile
        },
        modules : [modules to include],
        services :{
               service_name : {
                         service configuration
               }
        }
    }
    ###
    deployTo : (location,config,callback) ->
        if location
            if typeof config is 'function'
                callback = config
                config = {}
            Fs.exists location,(exists)=>
                if exists is false
                    Fse.mkdirRecursiveSync location
                Fs.stat location,(err,stat)=>
                    if err
                        callback(err)
                    else
                        if stat.isDirectory()
                            initLocationBasicHirastructor location,(err)=>
                                return callback(err) if err
                                initLocationModule location,config,(err)=>
                                    return callback(err) if err
                                    initLocationService location,config,(err)=>
                                        return callback(err) if err
                                        initLocationProfile location,config,(err)=>
                                            return callback(err) if err
                                            initLocationDataCopy @mew,location,config,(err)=>
                                                return callback(err) if err
                                                initIgnoreProfile location,config,(err)=>
                                                    callback(err)
                        else
                            callback("location is not a directory")
        else
            throw new Error("location not defined")

module.exports=DeployerManager
