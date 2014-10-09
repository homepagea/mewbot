Brain          = require './brain.coffee'
ModuleManager  = require './mm.coffee'
TestManager    = require './test.coffee'
UpdateManager  = require './update.coffee'
Path           = require 'path'
Fs             = require 'fs'
Log            = require 'log'
Os             = require 'os'
Fse            = require 'fs.extra'
rebotRules     = [
    "1. A robot may not injure a human being or, through inaction, allow a human being to come to harm.",
    "2. A robot must obey any orders given to it by human beings, except where such orders would conflict with the First Law.",
    "3. A robot must protect its own existence as long as such protection does not conflict with the First or Second Law."
]
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
                @brain.adapterManager.initAdapters @options.adapter,(err)=>
                    if err
                        @logger.error err
                    @addTextRespond /^ping$/i,(response)=>
                        response.replyText "PONG"

                    @addTextRespondAll /^ECHO (.*)$/i,(response)=>
                        if response.match[1] and response.match[1].length
                            response.respondText response.match[1]

                    @addTextRespond /^TIME$/i,(response)=>
                        response.replyText "Server time is: #{new Date()}"

                    @addTextRespond /(what are )?the (three |3 )?(rules|laws)/i,(response)=>
                        response.replyText rebotRules
                    
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
            return Path.join(Os.tmpdir(),"#{@name}-#{process.env.MEWBOT_PORT || 3030}",path)
        else
           return Path.join(Os.tmpdir(),"#{@name}-#{process.env.MEWBOT_PORT || 3030}")
           
    getConfFile : (externalPath)->
        if externalPath
            return Path.join(__dirname,"..","var","conf",externalPath)
        else
            return Path.join(__dirname,"..","var","conf")

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
                                    conEntrys = confLine.split("=")
                                    process.env[conEntrys[0].replace(/(^\s*)|(\s*$)/g,"")]=conEntrys[1].replace(/(^\s*)|(\s*$)/g,"")
                            if callback
                                callback()
                        else
                            if callback
                                callback("config profile [#{profileName}] is empty")
            else
                if callback
                    callback("config profile [#{profileName}] is not found")
    
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

    addRpcRespond : (domain,object)->
        @brain.rpcManager.addRpcRespond domain,object

    removeRpcRespond : (domain)->
        @brain.rpcManager.removeRpcRespond



module.exports=MewBot