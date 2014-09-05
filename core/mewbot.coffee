Brain         = require './brain.coffee'
ModuleManager = require './mm.coffee'
TestManager   = require './test.coffee'
Path          = require 'path'
Fs            = require 'fs'


class MewBot
    constructor : (adapter)->
        @brain  = new Brain @
        @mm     = new ModuleManager @
        @test   = new TestManager @

    init : (profile,callback)->
        @changeProfile profile,(err)=>
            if err
                console.log err
            callback()
            
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