Brain         = require './brain.coffee'
ModuleManager = require './mm.coffee'
TestManager   = require './test.coffee'
Path          = require 'path'



class MewBot
    constructor : (adapter)->
        @brain = new Brain @
        @mm    = new ModuleManager @
        @test  = new TestManager @

    module : (module) ->
        return @mm.module(module)



module.exports=MewBot