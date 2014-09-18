Brain          = require './brain.coffee'
ModuleManager  = require './mm.coffee'
TestManager    = require './test.coffee'
UpdateManager  = require './update.coffee'
Path           = require 'path'
Fs             = require 'fs'
Log            = require 'log'
Os             = require 'os'
Fse            = require 'fs.extra'

class MewBot
    constructor : (@name,adapters)->
        @logger  = new Log process.env.MEWBOT_LOG_LEVEL or 'info'
        @brain   = new Brain @,adapters
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
                @brain.adapterManager.initAdapters (err)=>
                    if err
                        @logger.error err
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

    module : (module) ->
        return @mm.module(module)



module.exports=MewBot