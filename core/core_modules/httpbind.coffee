Fs   = require 'fs'
Fse  = require 'fs.extra'
Path = require 'path'
express = require 'express'
os      = require 'os'
url = require 'url'
http = require 'http'

httpProxyHeaderFilter = {
    "connection" : true,
    "cache-control"  : true
    "user-agent" : true,
    "accept-language" : true,
    "cookie" : true
}


findTargetPath = (folder,filename,index,callback)->
    targetPath = ""
    if index
        targetPath = Path.join(folder,"#{Path.basename(filename,Path.extname(filename))}-#{index}#{Path.extname(filename)}")
    else
        targetPath = Path.join(folder,filename)
    Fs.exists targetPath,(exists)->
        if exists
            findTargetPath folder,filename,(index + 1),callback
        else
            callback(targetPath)

class HttpBind
    constructor : (@mew)->
        @staticPathDefinitionPool = {}

    getLocalIP : ->
        ifaces = os.networkInterfaces()
        addresses = []
        for dev of ifaces
            ifaces[dev].forEach (details)->
                if details.family is 'IPv4' and details.internal is false
                    addresses.push(details.address)
        if addresses.length is 0
            return "127.0.0.1"
        else
            return addresses[0]


    handleHttpAuth : (req,res,possibleAuthPool,next) ->
        authorization = req.headers.authorization
        if req.user
            next()
        else
            unless authorization
                res.statusCode = 401
                res.setHeader('WWW-Authenticate', 'Basic realm="Authorization Required"')
                return res.end('Unauthorized')
            parts = authorization.split(' ')
            if parts.length isnt 2
                return res.send 400
            scheme = parts[0]
            credentials = new Buffer(parts[1], 'base64').toString()
            index = credentials.indexOf(':')
            if 'Basic' isnt scheme || index < 0
                return res.send 400
            user = credentials.slice(0, index)
            pass = credentials.slice(index + 1)
            if possibleAuthPool[user] and possibleAuthPool[user] is pass
                req.user = user
                next()
            else
                res.statusCode = 401
                res.setHeader('WWW-Authenticate', 'Basic realm="Authorization Required"')
                return res.end('Unauthorized')

    bindStatic : (context,location)->
        if location and context
            if Fs.existsSync(location)
                bindFunction = {
                    route : context,
                    handle : express.static(location)
                }
                if @staticPathDefinitionPool[context]
                    for stack in @mew.brain.httpManager.app.stack
                        if stack.route is context
                            stack.handle = bindFunction.handle
                else
                    @mew.brain.httpManager.app.use context,bindFunction.handle
                    @mew.logger.debug "http bind [#{context}] <=static=> [#{location}]"
                @staticPathDefinitionPool[context]=bindFunction
            else
                throw new Error("location not exists")
        else
            throw new Error("location or context not defined")

    getHostBaseURL : ->
        if process.env.MEWBOT_ROOTURL
            return process.env.MEWBOT_ROOTURL
        else if process.env.MEWBOT_HOST
            return "#{process.env.MEWBOT_HOST}:#{@mew.port}"
        else
            return "http://#{@getLocalIP()}:#{@mew.port}"

    bindMiddleware : (path,callback)->
        do(path)=>
            @mew.brain.httpManager.app.use path,callback

    bindProxy : (path,target)->
        if typeof path is "string"
            unless path.match /^\/(.*)$/
                path = "/" + path
            unless path.match /^(.*)\/$/
                path =  path + "/"
            pathURLMathRegex = eval("/^#{path.replace(/\//g,'\\/')}(.*)$/")
            targetURL = url.parse(target)
            @bindHttp pathURLMathRegex,(req,res)=>
                rawBody = ""
                urlToRequest = req.originalUrl
                unless path.match /^\/(.*)$/
                    urlToRequest = "/" + urlToRequest
                unless path.match /^(.*)\/$/
                    urlToRequest =  urlToRequest + "/"
                urlToRequest = urlToRequest.replace(path,"/")
                headers = {}
                for hkey of req.headers
                    if httpProxyHeaderFilter[hkey]
                        headers[hkey]=req.headers[hkey]
                req.on "data" , (chunk)=>
                    rawBody = rawBody + chunk
                req.on "end" ,=>
                    opt = {
                        host: targetURL.host ,
                        port: targetURL.port || 80 ,
                        method:req.method,
                        path: urlToRequest,
                        headers:headers
                    }
                    proxiedRequest = http.request opt,(pres)=>
                        pres.pipe(res)
                    if rawBody
                        proxiedRequest.write rawBody

                    proxiedRequest.end()

        else
            throw new Error("only string path supported")

    bindUpload : (path,folder,callback)->
        do(folder)=>
            @bindHttp path,"post",(req,res,next)=>
                Fs.exists folder,(exists)=>
                    if exists is false
                        Fse.mkdirRecursiveSync folder
                    try
                        if req.files.file
                            tempPath = req.files.file.path
                            @mew.logger.debug "uploading file : #{req.files.file.name}"
                            findTargetPath folder,req.files.file.name,0,(targetPath)=>
                                try
                                    Fse.move tempPath,targetPath,(err)=>
                                        if err
                                            @mew.logger.error err
                                            Fs.unlink tempPath
                                            return res.json({status:'ERROR',msg : err.toString()})
                                        else
                                            try
                                                callback targetPath,req,(err,path)=>
                                                    if err
                                                        @mew.logger.error err
                                                        Fs.unlink tempPath
                                                        return res.json({status:'ERROR',msg : err.toString()})
                                                    else
                                                        if path
                                                            return res.json({status:'SUCCESS',path : path})
                                                        else
                                                            return res.json({status:'SUCCESS',path : Path.basename(targetPath)})
                                            catch ex
                                                @mew.logger.error "#{ex.stack}"
                                                Fs.unlink tempPath
                                                return res.json({status:'ERROR',msg : "#{ex.toString()}"})
                                catch ex
                                    @mew.logger.error "#{ex.stack}"
                                    Fs.unlink tempPath
                                    return res.json({status:'ERROR',msg : "#{ex.toString()}"})
                        else
                            if req.files.files
                                if Array.isArray(req.files.files) is false
                                    req.files.files=[req.files.files]
                                multipleFileHandleResult = []
                                multipleFileHandleCallback = =>
                                    fileInfo = req.files.files.shift()
                                    if fileInfo
                                        tempPath = fileInfo.path
                                        @mew.logger.debug "uploading multiple file : #{fileInfo.name}"
                                        findTargetPath folder,fileInfo.name,0,(targetPath)=>
                                            try
                                                Fse.overwrite tempPath,targetPath,(err)=>
                                                    if err
                                                        @mew.logger.error err
                                                        Fs.unlink tempPath
                                                        multipleFileHandleResult.push {
                                                            status : 'error'
                                                            name : fileInfo.name,
                                                            msg : err.toString()
                                                        }
                                                        multipleFileHandleCallback()
                                                    else
                                                        try
                                                            callback targetPath,req,(err)=>
                                                                if err
                                                                    Fs.unlink tempPath
                                                                    @mew.logger.error err
                                                                    multipleFileHandleResult.push {
                                                                        status : 'error'
                                                                        name : fileInfo.name,
                                                                        msg : err.toString()
                                                                    }
                                                                    multipleFileHandleCallback()
                                                                else
                                                                    multipleFileHandleResult.push {
                                                                        status : 'success'
                                                                        name : fileInfo.name
                                                                    }
                                                                    multipleFileHandleCallback()
                                                        catch ex
                                                            Fs.unlink tempPath
                                                            @mew.logger.error "#{ex.stack}"
                                                            multipleFileHandleResult.push {
                                                                status : 'error'
                                                                name : fileInfo.name,
                                                                msg : ex.toString()
                                                            }
                                                            multipleFileHandleCallback()
                                            catch ex
                                                Fs.unlink tempPath
                                                @mew.logger.error "#{ex.stack}"
                                                multipleFileHandleResult.push {
                                                    status : 'error'
                                                    name : fileInfo.name,
                                                    msg : ex.toString()
                                                }
                                                multipleFileHandleCallback()
                                    else
                                        return res.json({status:'SUCCESS', result : multipleFileHandleResult})
                                multipleFileHandleCallback()
                            else
                                return res.json({status:'ERROR',msg : "file not found"})
                    catch ex
                        @mew.logger.error "#{ex.stack}"
                        return res.json({status:'ERROR',msg : "#{ex.toString()}"})
    bindHttp : (path,type,callback) ->    
        if path and (typeof path is "string" or Object.prototype.toString.call(path) is "[object RegExp]")
            if typeof type is 'function'
                callback = type
                type = "all"
            if typeof callback isnt 'function'
                throw new Error("callback is not a function")
            @mew.logger.debug "#{@mew.name} bind http[#{type}] to #{path.toString()}"
            switch type
                when "all" 
                    @mew.brain.httpManager.app.all path,callback
                when "get" 
                    @mew.brain.httpManager.app.get path,callback
                when "post"
                    @mew.brain.httpManager.app.post path,callback
                else
                    throw new Error("type : [#{type}] not defined")
        else
            throw new Error("path not defined or type error")




module.exports=HttpBind