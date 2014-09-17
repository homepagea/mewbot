Fs = require 'fs'
Path = require 'path'
cps  = require 'child_process'

class GitUpdater
    constructor : (@mew,@gitFolder)->

    update : (callback)->
        cps.exec "git --git-dir='#{@gitFolder}' pull origin master",(err,stdout,stderr)->
            if err
                callback(err)
            else
                callback()
                
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