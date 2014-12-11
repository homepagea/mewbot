express = require 'express'



class HttpServer
    constructor : (@mew,@brain)->
        @app = express()
        
    run : ->
        user    = process.env.HTTP_USER
        pass    = process.env.HTTP_PASSWORD
        @app.use express.basicAuth user, pass if user and pass
        @app.use express.query()
        @app.use express.compress()
        @app.use express.bodyParser()
        @app.use express.cookieParser()
        @app.use express.session({secret:"MSESSIONID"})
        if process.env.HTTP_ENABLE_MONITOR
            @app.use (req,res,next) =>
                start = new Date()
                res.on "finish",=>
                    end = new Date()
                    elapsed = end - start
                    @mew.logger.debug "mewbot finished http request to url : #{req.originalUrl} , end with status code [#{res.statusCode}] and time elapsed [#{elapsed}ms] \n"
                next()
        try
            @app.listen @mew.port
            @mew.logger.debug "start http server success at port : #{@mew.port}"
            @app.all "/gateway/api/ping.jsp",(req,res,next)=>
                res.send "SUCCESS"
        catch err
            @mew.logger.error "error trying to start http server: #{err}"
            @mew.logger.error "#{err.stack}"
            process.exit(1)




module.exports=HttpServer