Fs   = require 'fs'
Fse  = require 'fs.extra'
Path = require 'path'
express = require 'express'

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

    bindStatic : (location,context)->
        if location and context
            if Fs.existsSync(location)
                if @staticPathDefinitionPool[context]
                    throw new Error("target static context already bind to : #{@staticPathDefinitionPool[context]}")
                else
                    @mew.brain.httpManager.app.use context,express.static(location)
                    @staticPathDefinitionPool[context]=location
            else
                throw new Error("location not exists")
        else
            throw new Error("location or context not defined")

    bindUpload : (path,folder,callback)->
        @bindHttp path,"post",(req,res,next)=>
            Fs.exists folder,(exists)=>
                if exists is false
                    Fse.mkdirRecursiveSync folder
                try
                    if req.files.file
                        tempPath = req.files.file.path
                        findTargetPath folder,req.files.file.name,0,(targetPath)=>
                            try
                                Fse.move tempPath,targetPath,(err)=>
                                    if err
                                        @mew.logger.error err
                                        Fs.unlink tempPath
                                        return res.json({status:'ERROR',msg : err.toString()})
                                    else
                                        try
                                            callback null,targetPath,req,(err)=>
                                                if err
                                                    @mew.logger.error err
                                                    return res.json({status:'ERROR',msg : err.toString()})
                                                else
                                                    return res.json({status:'SUCCESS',path : Path.basename(targetPath)})
                                        catch ex
                                            @mew.logger.error "#{ex.stack}"
                                            return res.json({status:'ERROR',msg : "#{ex.toString()}"})
                            catch ex
                                @mew.logger.error "#{ex.stack}"
                                return res.json({status:'ERROR',msg : "#{ex.toString()}"})
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