OTHERWebInstance = require 'otherweb.coffee'

class B2B2CModule 
    constructor : (@mewbot)->
        @b2b2c_store_function = [
            "getContext",
            "searchProduct",
            "makeOrder",
            "!uploadOrderAttachment",
            "bookmarkProduct",
            "unbookmarkProduct",
            "!repostAttachment"
        ]
        @b2b2c_admin_function = [
            "listProductCategoriesByType",
            "updateProductCategoryStatus",
            "saveProductCategory",
            "getProductCategory",
            "getContext",
            "updateTraderStatus",
            "updateTraderStatusByAccount",
            "getAllStoreUnAuthed",
            "updateStoreStatus",
            "listProductTypes",
            "updateProductTypeStatus",
            "saveProductType",
            "getProductTypeById",
            "getProductTypeByName",
            "getProductTypeAttributeKeys",
            "getProductTypeAttributeKeyInfo",
            "getProductTypeAccessoryTags",
            "saveProductTypeAttributeKey",
            "newProductObject",
            "saveProductInfo",
            "getProduct",
            "saveProductAttribute",
            "saveProductAccessory",
            "saveProductPhoto",
            "getAllPhotos",
            "!uploadPhoto",
            "updatePhoto",
            "searchProduct",
            "searchProductUsedByAccessory",
            "getTraderInfo",
            "saveTraderInfo",
            "updateTraderPassword",
            "findRelatedProduct",
            "relateProduct",
            "unrelateProduct",
            "findTraders",
            "findTraderStores",
            "updatePaymentAccount",
            "listAllActivePaymentAccount",
            "updatePaymentAccountStatus",
            "updateVIPLevelDiscount",
            "listAvailableVIPLevelDiscount",
            "removeProductTypeAttributeKey",
            "getAllAccessories"
        ]
        @b2b2c_trader_function = [
            "register",
            "getMyInfo",
            "saveStoreInfo",
            "getAllMyStore",
            "getStoreBindSecret"
        ]
        
    newAdminInstance: (rootURL,username,password)->
        userAgent = process.env.AINETWORK_DEFAULT_UA || "otherbot/crawler"
        instance  = new OTHERWebInstance userAgent,rootURL,username,password
        instance.compileObject "bizadmin",@b2b2c_admin_function
        return instance
        
    newTraderInstance : (rootURL,username,password)->
        userAgent = process.env.AINETWORK_DEFAULT_UA || "otherbot/crawler"
        instance  = new OTHERWebInstance userAgent,rootURL,username,password
        instance.compileObject "biztrader",@b2b2c_trader_function
        instance.loginStatus = "complete"
        return instance

    newStoreInstance : (rootURL,authType,authKey,authSecret)->
        userAgent = process.env.AINETWORK_DEFAULT_UA || "otherbot/crawler"
        instance  = new OTHERWebInstance userAgent,rootURL,username,password
        instance.compileObject "bizstore",@b2b2c_store_function
        instance.loginStatus = "complete"
        instance.data.authType=authType
        instance.data.authKey=authKey
        instance.data.authSecret=authSecret
        instance.login = (callback)->
            if @loginStatus is 'incomplete' or @loginStatus is 'proceeding'
                @loginStatus = "complete"
                @bizstore.getContext {
                    type   : @data.authType,
                    key    : @data.authKey,
                    secret : @data.authSecret
                },(r,e) ->
                    if r
                        if callback
                            callback()
                    else
                        if callback
                            callback(e)
            else
                if callback
                    callback()
        return instance

module.exports = B2B2CModule        