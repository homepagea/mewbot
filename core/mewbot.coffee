Brain         = require './brain.coffee'
ModuleManager = require './mm.coffee'
TestManager   = require './test.coffee'
Path          = require 'path'
Fs            = require 'fs'


class MewBot
    constructor : (adapter)->
        @changeProfile "default",(err)=>
            if err
                console.log err
            @brain  = new Brain @
            @mm     = new ModuleManager @
            @test   = new TestManager @

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
                                conEntrys = confLine.split("=")
                                process.env[conEntrys[0]]=conEntrys[1]
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