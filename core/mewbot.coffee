Brain          = require './brain.coffee'
ModuleManager  = require './mm.coffee'
TestManager    = require './test.coffee'
UpdateManager  = require './update.coffee'
Path           = require 'path'
Fs             = require 'fs'
Log            = require 'log'
Os             = require 'os'
Fse            = require 'fs.extra'
Portfinder     = require 'portfinder'

class MewBot
    constructor : (@options)->
        @name    = @options.name
        @role    = @options.role
        @logger  = new Log process.env.MEWBOT_LOG_LEVEL or 'info'
        @brain   = new Brain @
        @mm      = new ModuleManager @
        @test    = new TestManager @
        @updater = new UpdateManager @
        process.on "uncaughtException",(err)=>
            @logger.error "#{err.stack}"
            @logger.error err

    init : (profile,callback)->
        @changeProfile profile,(err)=>
            if err
                @logger.error err
            Portfinder.getPort (err,port)=>
                if err
                    @logger.error err
                    @port=process.env.MEWBOT_PORT || 3030
                else
                    if process.env.MEWBOT_PORT
                        @port=process.env.MEWBOT_PORT
                    else
                        @port=port
                if @options.nameDefined is false
                    if process.env.MEWBOT_NAME
                        @name = process.env.MEWBOT_NAME

                tmpFolder = @getTmpFile()
                Fs.exists tmpFolder,(exists)=>
                    if exists is false
                        Fse.mkdirRecursiveSync tmpFolder
                    if @options.adapter.length is 0
                        if process.env.MEWBOT_ADAPTER
                            for adapter in process.env.MEWBOT_ADAPTER.split(",")
                                @options.adapter.push adapter
                        else
                            @options.adapter.push "shell"
    
                    if process.env.MEWBOT_SERVICE
                        for service in process.env.MEWBOT_SERVICE.split(",")
                            @options.services.push service
                    @exportProfile "backup",(err)=>
                            callback()


    getDataFile : (externalPath) ->
        if externalPath
            return Path.join(__dirname,"..","var","data",externalPath)
        else
            return Path.join(__dirname,"..","var","data")
            
    makeDataDir : (path)->
        dataFile = @getDataFile(path)
        if Fs.existsSync(dataFile) is false
            Fse.mkdirRecursiveSync dataFile
        return dataFile

    makeTmpDir : (path)->
        dataFile = @getTmpFile(path)
        if Fs.existsSync(dataFile) is false
            Fse.mkdirRecursiveSync dataFile
        return dataFile

    getTmpFile : (path)->
        if path
            return Path.join(Os.tmpdir(),"#{@name}-#{@port}",path)
        else
           return Path.join(Os.tmpdir(),"#{@name}-#{@port}")
           
    getConfFile : (externalPath)->
        if externalPath
            return Path.join(__dirname,"..","var","conf",externalPath)
        else
            return Path.join(__dirname,"..","var","conf")

    exportProfile : (profileName,callback)->
        profileFile = Path.join(__dirname,"/../var/conf/#{profileName}")
        profileOutput = ""
        for key of process.env
            if profileOutput.length
                profileOutput="#{profileOutput}\n"
            profileOutput="#{profileOutput}#{key}=#{process.env[key]}"
        Fs.writeFile profileFile,profileOutput,(err)=>
            if callback
                callback(err,profileFile)

    changeProfile : (profileName,callback)->
        profileFile = Path.join(__dirname,"/../var/conf/#{profileName}")
        Fs.exists profileFile,(exists)=>
            if exists
                Fs.readFile profileFile,(err,data)=>
                    if err
                        if callback
                            callback("config profile [#{profileName}] read error : #{err}")
                    else
                        fileContent = data.toString()
                        if fileContent and fileContent.length
                            for confLine in fileContent.split("\n")
                                if confLine.indexOf("=")  > 0
                                    conEntrys = []
                                    conEntrys.push confLine.substr(0,confLine.indexOf("="))
                                    conEntrys.push confLine.substr(confLine.indexOf("=")+1)
                                    process.env[conEntrys[0].replace(/(^\s*)|(\s*$)/g,"")]=conEntrys[1].replace(/(^\s*)|(\s*$)/g,"")
                            if callback
                                callback()
                        else
                            if callback
                                callback("config profile [#{profileName}] is empty")
            else
                if profileName is "default"
                    if callback
                        callback("config profile [#{profileName}] is not found")
                else
                    @logger.debug "config profile [#{profileName}] is not found, using default profile ..."
                    @changeProfile "default",callback
    
    removeTextRespond : (rule)->
        @brain.ruleManager.removeTextRespond rule

    addTextRespond : (rule,callback)->
        @brain.addTextRespond rule,"",callback

    addTextRespondAll : (rule,callback)->
        @brain.addTextRespond rule,"*",callback

    addTextRespondTo : (rule,match,callback)->
        @brain.addTextRespond rule,match,callback

    sendText : (adapterId,messages ...)->
        @brain.sendText adapterId,messages
        
    module : (module) ->
        return @mm.module(module)

    addRpcRespond : (domain,object,ignored_functions)->
        @brain.rpcManager.addRpcRespond domain,object,ignored_functions

    removeRpcRespond : (domain)->
        @brain.rpcManager.removeRpcRespond



module.exports=MewBot