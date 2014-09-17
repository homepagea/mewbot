Fs = require 'fs'
Path = require 'path'
cpp  = require 'child-process-promise'

class GitUpdater
    constructor : (@mew,@gitFolder)->

    update : (callback)->
        executeCommand = "git --git-dir='#{@gitFolder}' pull origin master"
        
        promise = cpp.exec executeCommand

        promise.then (result)->
            callback(null)

        promise.fail (err)->
            callback(err)

    commit : ->


class UpdateManager 
    constructor : (@mew)->
        @archiver = @mew.module("archiver")

    updateMewModule : (moduleName,callback)->

    executeUpdate : (callback)->
        gitFolder = Path.join __dirname,"..",".git"
        Fs.exists gitFolder,(exists)=>
            if exists
                ##execute git update
                gitUpdater = new GitUpdater @mew,gitFolder
                gitUpdater.update callback
            else
                ##execute remote update
                callback("remote update not supported yet")

module.exports = UpdateManager