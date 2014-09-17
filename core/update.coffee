Fs = require 'fs'
Path = require 'path'

class UpdateManager 
    constructor : (@mew)->
        @archiver = @mew.module("archiver")

    executeUpdate : (callback)->
        gitFolder = Path.join __dirname,"..",".git"
        Fs.exists gitFolder,(exists)=>
            if exists
                ##execute git update
            else
                ##execute remote update
            callback()

module.exports = UpdateManager