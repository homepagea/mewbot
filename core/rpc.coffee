Mew = require 'mew'
extend  = require 'extend'
Fs      = require 'fs'
Path    = require 'path'
Validator = require 'validator'
wildcard = require 'wildcard'
uuid     = require 'uuid'


rpcHandler = (domain,rpcquery,object,ignored_functions,callback)->
    response = {}
    try
        response.id = rpcquery.id || uuid.v1()
        if rpcquery.method 
            splitindex = rpcquery.method.indexOf(".")
            callparams = []
            if rpcquery.params and Array.isArray(rpcquery.params)
                for param in rpcquery.params
                    callparams.push param
            else
                response.error = {
                    msg  : "method not found",
                    code : 591
                }
                return callback(response)
            responseCallback = (err,result)=>
                if err
                    if typeof err is 'string'
                        response.error = {
                            msg : err,
                            code : 590
                        }
                    else
                        response.error = {
                            msg : err.toString() ,
                            code : 590
                        }
                if result
                    response.result = result
                return callback(response)
            callparams.push responseCallback
            if splitindex >= 0
                subobject = rpcquery.method.substr(0,splitindex)
                method    = rpcquery.method.substr(splitindex + 1)
                if object[subobject] and typeof object[subobject] isnt 'function'
                    if typeof object[subobject][method] is 'function'
                        try
                            object[subobject][method].apply object[subobject],callparams
                        catch e
                            response.error = {
                                msg : e.toString(),
                                code : 590
                            }
                            return callback(response)
                    else
                        response.error = {
                            msg  : "method not found : subobject null",
                            code : 591
                        }
                        return callback(response)
                else
                    response.error = {
                        msg  : "method not found : subobject null",
                        code : 591
                    }
                    return callback(response)
            else
                if rpcquery.method in ignored_functions
                    response.error = {
                        msg  : "method not found : reserved function",
                        code : 591
                    }
                    return callback(response)
                else
                    if typeof object[rpcquery.method] is 'function'
                        try
                            object[rpcquery.method].apply object,callparams
                        catch e
                            response.error = {
                                code : 590,
                                msg : e.toString()
                            }
                            return callback(response)
                    else
                        response.error = {
                            msg  : "method not found : direct call not found",
                            code : 591
                        }
                        return callback(response)
        else
            response.error = {
                msg  : "method not found : definition empty",
                code : 591
            }
            return callback(response)

    catch e
        response.error = {
            code : 590,
            msg : e.toString()
        }
        return callback(response)
        
class RPCManager
    constructor : (@mew,@brain)->
        @rpcInfoPool = {}
        @httpbind = @mew.module("httpbind")

    getBridge : (callback)->
        bridgeInfo = {}
        for domain of @rpcInfoPool
            bridgeInfo[domain]=[]
            methodList = (k for k, v of @rpcInfoPool[domain].object when typeof v is 'function')
            for method in methodList
                if method in @rpcInfoPool[domain].ignored_functions is false
                    bridgeInfo[domain].push method

        callback(null,bridgeInfo)

    run : ->
        @addRpcRespond "rpc",@,["addRpcRespond","run"]
        @httpbind.bindHttp "/gateway/api/jsonrpc.jsp","post",(req,res,next)=>
            if req.body.query
                try
                    response = {}
                    rpcquery = JSON.parse(req.body.query)
                    response.id = rpcquery.id || uuid.v1()
                    @mew.logger.debug "jsonrpc request : #{JSON.stringify(rpcquery)}"
                    if rpcquery.method
                        splitindex = rpcquery.method.indexOf(".")
                        callparams = []
                        if rpcquery.params and Array.isArray(rpcquery.params)
                            for param in rpcquery.params
                                callparams.push param
                            if splitindex > 0
                                responseCallback = (err,result)=>
                                    if err
                                        if typeof err is 'string'
                                            response.error = {
                                                msg : err,
                                                code : 590
                                            }
                                        else
                                            response.error = {
                                                msg : err.toString() ,
                                                code : 590
                                            }
                                    if result
                                        response.result = result
                                    try
                                        @mew.logger.debug "jsonrpc request : #{JSON.stringify(rpcquery)} finished , with response : #{JSON.stringify(response)}"
                                        res.send JSON.stringify(response)
                                    catch e
                                        response.error = {
                                            msg : e.toString() ,
                                            code : 490
                                        }
                                        res.send JSON.stringify(response)
                                callparams.push responseCallback
                                domain = rpcquery.method.substr(0,splitindex)
                                method = rpcquery.method.substr(splitindex+1)
                                if @rpcInfoPool[domain]
                                    if method in @rpcInfoPool[domain].ignored_functions
                                        response.error = {
                                            msg  : "requested object method is ignored",
                                            code : 591
                                        }
                                        res.send JSON.stringify(response)
                                    else
                                        if typeof @rpcInfoPool[domain].object[method] is 'function'
                                            try
                                                @rpcInfoPool[domain].object[method].apply @rpcInfoPool[domain].object,callparams
                                            catch e
                                                response.error = {
                                                    msg : e.toString() ,
                                                    code : 490
                                                }
                                                res.send JSON.stringify(response)
                                        else
                                            response.error = {
                                                msg  : "requested object method not found",
                                                code : 591
                                            }
                                            res.send JSON.stringify(response)
                                else
                                    response.error = {
                                        msg  : "requested object not found",
                                        code : 591
                                    }
                                    res.send JSON.stringify(response)
                            else
                                response.error = {
                                    msg  : "method not found : method format error",
                                    code : 591
                                }
                                res.send JSON.stringify(response)
                        else
                            response.error = {
                                msg  : "method not found : param error",
                                code : 591
                            }
                            res.send JSON.stringify(response)
                    else
                        response.error = {
                            msg  : "method not found : definition empty",
                            code : 591
                        }
                        res.send JSON.stringify(response)
                catch e
                    @mew.logger.error "#{e.stack}"
                    res.send JSON.stringify({
                        error :{
                            msg  : e.toString(),
                            code : 490
                        }
                    })
                
            else
                res.send JSON.stringify({
                    error :{
                        msg  : "query not found",
                        code : 490
                    }
                })

    makeRpcRequest : (adapterMatchRole,role,timeout,domain,method,params,callback)->
        
    removeRpcRespond : (domain)->
        if @rpcInfoPool[domain]
            rpcmapRequestRegex = eval("/#{domain}:request:(.*)$/")
            delete @rpcInfoPool[domain]
            @brain.ruleManager.removeTextRespond rpcmapRequestRegex

    addRpcRespond : (domain,object,ignored_functions,callback)->
        @removeRpcRespond domain
        if domain and object and (object is @ or domain isnt "rpc" )
            if typeof ignored_functions is 'function'
                callback = ignored_functions
                ignored_functions = []
            else if Array.isArray(ignored_functions) isnt true
                ignored_functions = []
            do (object,domain,ignored_functions)=>
                @rpcInfoPool[domain]={
                    domain : domain,
                    object : object,
                    ignored_functions : ignored_functions
                }
                @mew.logger.debug "rpc add domain : #{domain}"
                rpcmapRequestRegex = eval("/#{domain}:request:(.*)$/")
                @brain.ruleManager.removeTextRespond rpcmapRequestRegex
                @brain.addTextRespond rpcmapRequestRegex,"",(response)=>
                    try
                        rpcquery = JSON.parse(response.match[1])
                        rpcHandler domain,rpcquery,object,ignored_functions,(resp)=>
                            if response.envelop.name
                                return response.replyText "#{response.envelop.name}:#{domain}:response:#{JSON.stringify(resp)}"
                            else
                                return response.replyText "*:#{domain}:response:#{JSON.stringify(resp)}"
                    catch e
                        resp = {
                            error : {
                                code : 590,
                                msg : e.toString()
                            }
                        }
                        if response.envelop.name
                            response.replyText "#{response.envelop.name}:#{domain}:response:#{JSON.stringify(resp)}"
                        else
                            response.replyText "*:#{domain}:response:#{JSON.stringify(resp)}"
                if callback
                    callback()
        else
            if callback
                callback("rpc domain or object not defined")
            else
                @mew.logger.error "rpc add domain : #{domain} failed"

module.exports=RPCManager