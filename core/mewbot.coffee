Brain          = require './brain.coffee'
ModuleManager  = require './mm.coffee'
TestManager    = require './test.coffee'
UpdateManager  = require './update.coffee'
DeployManager  = require './deploy.coffee'
Path           = require 'path'
Fs             = require 'fs'
Log            = require 'log'
Os             = require 'os'
Fse            = require 'fs.extra'
Portfinder     = require 'portfinder'

class MewBot
    constructor : (@options)->
        @name     = @options.name
        @logger   = new Log process.env.MEWBOT_LOG_LEVEL or 'info'
        @mm       = new ModuleManager @
        @brain    = new Brain @
        @test     = new TestManager @
        @updater  = new UpdateManager @
        @deployer = new DeployManager @
        process.on "uncaughtException",(err)=>
            console.log err.stack
            #@logger.error "#{err.stack}"
            #@logger.error err

    init : (profile,callback)->
        @changeProfile profile,(err)=>
            if err
                @logger.error err
            else
                @logger.debug "init profile update complete"
            Portfinder.getPort (err,port)=>
                if err
                    @logger.error err
                    @port=process.env.MEWBOT_PORT || 3030
                else
                    if @options.port
                        @port = @options.port
                    else
                        if process.env.MEWBOT_PORT
                            @port=process.env.MEWBOT_PORT
                        else
                            @port=port
                    @logger.debug "init mewbot start atr port : #{@port}"
                            
                if @options.nameDefined is false
                    if process.env.MEWBOT_NAME
                        @name = process.env.MEWBOT_NAME
                @logger.debug "mewbot has been named into #{@name}"
                tmpFolder = @getTmpFile()
                Fs.exists tmpFolder,(exists)=>
                    if exists is false
                        try
                            Fse.mkdirRecursiveSync tmpFolder
                        catch ex
                            @logger.error "#{ex.stack}"
                    if @options.adapter.length is 0
                        if process.env.MEWBOT_ADAPTER
                            for adapter in process.env.MEWBOT_ADAPTER.split(",")
                                @options.adapter.push adapter
                        else
                            @options.adapter.push "shell"
                    if process.env.MEWBOT_SERVICE
                        for service in process.env.MEWBOT_SERVICE.split(",")
                            if service in @options.services is false
                                @options.services.push service
                    @role = process.env.MEWBOT_ROLE || @options.role || "client"
                    @exportProfile "backup",(err)=>
                        @logger   = new Log process.env.MEWBOT_LOG_LEVEL or 'info'
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
                                @logger.debug "config profile [#{profileName}] is empty"
                                callback()
            else
                if profileName is "default"
                    if callback
                        @logger.debug "default config profile not found"
                        callback()
                else
                    @logger.debug "config profile [#{profileName}] not found, using default profile ..."
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