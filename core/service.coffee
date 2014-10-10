Mew = require 'mew'
Extend  = require 'extend'
Fs      = require 'fs'
Path    = require 'path'
Validator = require 'validator'
wildcard = require 'wildcard'
uuid     = require 'uuid'

class ServiceWrapper
    constructor : (@mew,@name)->

    start : (callback)->
        servicePath = Path.join __dirname,"..","mew_modules","!#{@name}"
        Fs.exists servicePath,(exists)=>
            if exists
                try
                    serviceClass = require servicePath
                    serviceConfigPath = Path.join __dirname,"..","var","conf","!#{@name}"
                    Fs.readFile serviceConfigPath,(err,data)=>
                        serviceConfig = {}
                        if err
                            @mew.logger.debug "reading service [#{@name}] config error : #{err}"
                        else
                            try
                                serviceConfig = Extend(serviceConfig,JSON.parse(data.toString()))
                            catch e
                                @mew.logger.debug "reading service [#{@name}] config error : #{e}"
                        @instance = new serviceClass @mew,serviceConfig
                        if @instance instanceof Mew.Service
                            @instance.start (err)=>
                                if err
                                    callback(err)
                                else
                                    @mew.addRpcRespond @name,@instance,Mew.Service.ignored_functions,(err)=>
                                        if err
                                            callback(err)
                                        else
                                            callback()
                        else
                            callback("service module isnt a mew service")
                catch ex
                    callback(ex)
            else
                callback("service module not exists")


class ServiceManager
    constructor: (@mew,@brain)->
        @serviceIndex={}

    persistConfig : (service,callback)->
        if @serviceIndex[service]
            try
                serviceConfigPath = Path.join __dirname,"..","var","conf","!#{service}"
                Fs.writeFile serviceConfigPath,JSON.stringify(@serviceIndex[service].instance.config,null,4),callback
            catch ex
                if callback
                    callback(ex)
        else
            if callback
                callback("service not found")
    run: ->
        serviceWrapperArray=[]
        for service in @mew.options.services
            if @serviceIndex[service]
                @mew.logger.debug "service [#{service}] already started"
            else
                @serviceIndex[service]=new ServiceWrapper @mew,service
                serviceWrapperArray.push @serviceIndex[service]

        serviceStartupCallback = =>
            wrapperInstance = serviceWrapperArray.shift()
            if wrapperInstance
                wrapperInstance.start (err)=>
                    if err
                        delete @serviceIndex[wrapperInstance.name]
                        @mew.logger.error "service [#{service}] start error : #{err}"
                    else
                        @mew.logger.debug "service [#{service}] start complete"
                    serviceStartupCallback()

        serviceStartupCallback()

module.exports=ServiceManager        