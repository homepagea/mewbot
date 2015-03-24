#!/bin/bash
PRG="$0"
PRGDIR=`dirname "$PRG"`
NODE=node
PATH=/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PRGDIR/../node_modules/.bin:$PRGDIR/../node_modules/other-hubot/node_modules/.bin:$PATH

which jx > /dev/null 2>&1
if [ $? == 0 ]; then
    NODE=jx
fi

$NODE $PRGDIR/../node_modules/coffee-script/bin/coffee $PRGDIR/../core/startup.coffee $@