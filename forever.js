var path = require('path');
var fs   = require('fs');
var coffee = require('coffee-script')
coffee.register();
jxcore.monitor.followMe(function(err,txt){
	require('./core/startup.coffee')
});