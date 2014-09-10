Path  = require 'path'
Fs    = require 'fs'

##Module Manager 
class MewModuleInstance
   constructor : (@mewbot,@moduleName) ->
        @moduleObject = null
   name : ->
        return @moduleName

class ModuleManager
    constructor : (@mewbot)->
        @moduleInitComplete = false
        @actionModuleContainer = {}
        @moduleInstanceContainer = []
        @initCoreModules()
        
    module: (moduleName) ->
        if typeof @actionModuleContainer[moduleName] is 'undefined'
            @initMewModule moduleName
        moduleInstance = new MewModuleInstance(@mewbot,moduleName)
        if @moduleInitComplete
            @initModuleInstance moduleInstance
        else
            @moduleInstanceContainer.push moduleInstance
            return moduleInstance

    initCoreModules : ->
        if Fs.existsSync Path.join(__dirname,"core_modules")
            for aifile in Fs.readdirSync(Path.join(__dirname,"core_modules"))
               if (Path.extname aifile) is '.coffee'
                try
                    aimoduleFile = Path.join(__dirname,"core_modules",aifile)
                    aimoduleClass=require aimoduleFile
                    aimodule = new aimoduleClass @mewbot
                    aimoduleName = aifile.substr(0,aifile.indexOf(".coffee"))
                    @actionModuleContainer[aimoduleName]=aimodule
                    @mewbot.logger.info "loading core module [#{aimoduleName}] success"
                catch error
                    @mewbot.logger.error error
                    @mewbot.logger.error "Unable to load core module : #{aimoduleName} : #{error.stack} "
            for moduleInstance in @moduleInstanceContainer
                @initModuleInstance(moduleInstance)
            @moduleInitComplete = true
        else
            @mewbot.logger.info "ai_modules folder not found "

    initMewModule : (moduleName)->
        moduleFolder = Path.join __dirname,"..","mew_modules",moduleName
        if Fs.existsSync moduleFolder
            try
                if typeof @actionModuleContainer[moduleName] is 'undefined'
                    aimoduleClass=require moduleFolder
                    @actionModuleContainer[moduleName] = new aimoduleClass @mewbot
                    @mewbot.logger.info "loading mew module [#{moduleName}] success"
                return @actionModuleContainer[moduleName]
            catch error
                throw new Error(error)
        else
            throw new Error("module not found")

    initModuleInstance : (moduleInstance) ->
        moduleObject = @actionModuleContainer[moduleInstance.name()]
        methodList = (k for k, v of moduleObject when typeof v is 'function')
        for method in methodList
            do (method) ->
                moduleInstance[method] = ->
                    @mewbot.mm.actionModuleContainer[@moduleName][method].apply(@mewbot.mm.actionModuleContainer[@moduleName],arguments);

        
module.exports = ModuleManager      