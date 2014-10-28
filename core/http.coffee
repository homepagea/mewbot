express = require 'express'

###
    if herokuUrl
      herokuUrl += '/' unless /\/$/.test herokuUrl
      @pingIntervalId = setInterval =>
        HttpClient.create("#{herokuUrl}hubot/ping").post() (err, res, body) =>
          @logger.info 'keep alive ping!'
      , 1200000
###
class HttpServer
    constructor : (@mew,@brain)->
        @app = express()
        
    run : ->
        user    = process.env.EXPRESS_USER
        pass    = process.env.EXPRESS_PASSWORD
        @app.use express.basicAuth user, pass if user and pass
        @app.use express.query()
        @app.use express.bodyParser()
        @app.use express.cookieParser()
        @app.use express.session({secret:"OSESSIONID"})
        try
            @app.listen @mew.port
            @mew.logger.debug "start http server success at port : #{@mew.port}"
        catch err
            @mew.logger.error "error trying to start http server: #{err}"
            @mew.logger.error "#{err.stack}"
            process.exit(1)


module.exports=HttpServer