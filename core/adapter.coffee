Mew = require 'mew'
extend  = require 'extend'
Fs      = require 'fs'
Path    = require 'path'
Validator = require 'validator'
wildcard = require 'wildcard'
uuid     = require 'uuid'

isRegex = (value)->
    return Object.prototype.toString.call(value) is '[object RegExp]';

checkAdapterInstance = (brain,name,profileName,adapterInstance,callback)->
    if adapterInstance instanceof Mew.Adapter or adapterInstance instanceof Mew.Adapter.MultiAdapter
        if typeof brain.adapterPool[name] is 'undefined'
            brain.adapterPool[name] = {}
        else 
            if (adapterInstance instanceof Mew.Adapter.MultiAdapter) isnt true
                return callback("Not a MultiAdapter","#{name}[#{profileName}]")
        brain.adapterPool[name][profileName]=adapterInstance
        brain.adapterIndex[adapterInstance.uuid]=adapterInstance
        callback(null,"#{name}[#{profileName}]")
    else
        callback("Not a MewAdapter","#{name}[#{profileName}]")

class AdapterManager
    constructor : (@mew)->
        @adapters = []
        @adapterPool = {}
        @adapterIndex = {}

    findAdapters : (adapterRule) ->
        if isRegex(adapterRule)
            adapters = []
            for adpaterUUID of @adapterPool
                adapter = @adapterPool[adpaterUUID]
                if adapterRule.test "#{adapter.name}[#{adapter.profileName}]"
                   adapters.push adapter
            return adapters
        else if Validator.isUUID(adapterRule)
            if @adapterIndex[adapterRule]
                return [@adapterIndex[adapterRule]]
            else
                return null
        else if typeof adapterRule is "string"
            if @adapterPool[adapterRule]
                adapters = []
                for adpaterProfile of @adapterPool[adapterRule]
                    adapters.push @adapterPool[adapterRule][adpaterProfile]
                return adapters
            else
                adapters = []
                for adpaterUUID of @adapterIndex
                    adapter = @adapterIndex[adpaterUUID]
                    if wildcard(adapterRule,"#{adapter.name}[#{adapter.profileName}]").length
                        adapters.push adapter
                return adapters
        else
            return []


    addAdapter : (adapter,profileName,profile,callback) ->
        if @adapterPool[adapter]
            if @adapterPool[adapter][profileName]
                callback("same adapter with same profile already defined",adapter)
                return
        defaultAdapterPath = Path.join __dirname,"adapters","#{adapter}.coffee"
        Fs.exists defaultAdapterPath,(exists)=>
            if exists
                adapterClass = require defaultAdapterPath
                if typeof adapterClass is 'function'
                    adapterInstance = new adapterClass @mew,profileName,profile
                    checkAdapterInstance @,adapter,profileName,adapterInstance,callback
                else
                    callback("adapter is not function","#{adapter}[#{profileName}]")
            else
                adapterModuleFolder = Path.join __dirname,"..","mew_modules","@#{adapter}"
                Fs.exists adapterModuleFolder,(exists)=>
                    if exists
                        adapterClass = require adapterModuleFolder
                        if typeof adapterClass is 'function'
                            adapterInstance = new adapterClass @mew,profileName,profile
                            checkAdapterInstance @,adapter,profileName,adapterInstance,callback
                        else
                            callback("adapter is not function","#{adapter}[#{profileName}]")
                    else
                        callback("adapter not found","#{adapter}[#{profileName}]")


    readAdapterConf : (profileName,callback)->
        confFile = @mew.getConfFile "@#{profileName}"
        Fs.exists confFile,(exists)=>
            if exists
                Fs.readFile confFile,(err,content)=>
                    fileContent = content.toString()
                    if fileContent and fileContent.length
                        externOptions = {}
                        for confLine in fileContent.split("\n")
                            if confLine.indexOf("=")  > 0
                                conEntrys = []
                                conEntrys.push confLine.substr(0,confLine.indexOf("="))
                                conEntrys.push confLine.substr(confLine.indexOf("=")+1)
                                externOptions[conEntrys[0].replace(/(^\s*)|(\s*$)/g,"")]=conEntrys[1].replace(/(^\s*)|(\s*$)/g,"")
                        callback(externOptions)
                    else
                        callback(null)
            else
                callback(null)

    initAdapters : (the_adapters,callback)->
        @adapters = the_adapters
        adapterInitCallback = (err,result)=>
            if result
                if err
                    @mew.logger.error "mew adapter <#{result}> init failed : #{err.toString()}"
                else
                    @mew.logger.debug "mew adapter <#{result}> init complete"
            adapter = @adapters.shift()
            if adapter
                profileName = "default"
                optionTest = /^(\S+)\[(\S+)\]$/
                adapterMatch = adapter.match optionTest
                if adapterMatch
                    adapter = adapterMatch[1]
                    profileName = adapterMatch[2]
                    @readAdapterConf profileName,(option)=>
                        if option
                            @addAdapter adapter,profileName,option,adapterInitCallback
                        else
                            if profileName isnt "default"
                                @mew.logger.debug "profile [#{profileName}] for adapter [#{adapter}] not found, using default profile ..."
                            @addAdapter adapter,"default",option,adapterInitCallback
                else
                    @addAdapter adapter,profileName,null,adapterInitCallback
            else
                callback()
        adapterInitCallback()

    run : ->
        for adapter of @adapterPool
            do (adapter)=>
                for profile of @adapterPool[adapter]
                    do (profile)=>
                        if typeof @adapterPool[adapter][profile].run is 'function'
                            try
                                @adapterPool[adapter][profile].run()
                                @adapterPool[adapter][profile].on "error",(e)=>
                                    @mew.logger.info "mew adapter <#{adapter}[#{profile}]> run error  : #{e}"
                                    delete @adapterPool[adapter][profile]
                            catch e
                                @mew.logger.error "mew adapter <#{adapter}[#{profile}]> run error  : #{e}"
                                delete @adapterPool[adapter][profile]

module.exports=AdapterManager                                