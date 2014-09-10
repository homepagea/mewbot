archiver = require 'archiver'
Fs = require 'fs'

class ArchiverModule 
    ###
    @moduleName archiver
    ###
    constructor:(@mewbot) ->

    zipFolder : (zipFile,folder,callback) ->
        archive = archiver('zip')
        output = Fs.createWriteStream(zipFile)
        archive.pipe(output)
        archive.bulk [{ expand: true, cwd: folder, src: ["**","!.git/**"] , dot : true }]
        archive.on "error",(err)->
            callback(err,null)
        output.on "close",->
            callback(null,archive.pointer())
        archive.finalize()

module.exports = ArchiverModule