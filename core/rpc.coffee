Mew = require 'mew'
extend  = require 'extend'
Fs      = require 'fs'
Path    = require 'path'
Validator = require 'validator'
wildcard = require 'wildcard'
uuid     = require 'uuid'


rpcHandler = (rpcquery,object,ignored_functions,callback)->
    response = {}
    try
        response.id = rpcquery.id || uuid.v1()
        if rpcquery.method and rpcquery.method.length
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
                            content : err ,
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
                            object[subobject][method].apply object,callparams
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
        @addRpcRespond "rpc",@
        @rpcInfoPool = {}

    makeRpcRequest : (adapterMatchRole,role,timeout,domain,method,params,callback)->
        
    removeRpcRespond : (domain)->
        rpcmapRequestRegex = eval("/#{domain}:request:(.*)$/")
        @brain.ruleManager.removeTextRespond rpcmapRequestRegex

    addRpcRespond : (domain,object,ignored_functions,callback)->
        if domain and object and (object is @ or domain isnt "rpc" )
            if typeof ignored_functions is 'function'
                callback = ignored_functions
                ignored_functions = []
            else if Array.isArray(ignored_functions) isnt true
                ignored_functions = []
            do (object,domain,ignored_functions)=>
                @mew.logger.debug "rpc add domain : #{domain}"
                rpcmapRequestRegex = eval("/#{domain}:request:(.*)$/")
                @brain.ruleManager.removeTextRespond rpcmapRequestRegex
                @brain.addTextRespond rpcmapRequestRegex,"",(response)=>
                    try
                        rpcquery = JSON.parse(response.match[1])
                        rpcHandler rpcquery,object,ignored_functions,(resp)=>
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