



module.exports = (callback)->
    mewto = @mew.module("mewto")
    instance  = mewto.newClientInstance "http://develop.mewmew.cn:8080/tripmew","homepagea@gmail.com","142857"
    instance.login (err)->
        if err
            callback(err)
        else
            instance.mew.getContext {deviceId : "1111-2222-3333-4444-55" , deviceType : "ios"},(r,e)=>
                instance.mew.getUserContext (r,e)=>
                    console.log r
                instance.mew.getDeviceInfo (r,e)->
                    console.log r

