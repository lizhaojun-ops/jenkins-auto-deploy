#!/bin/bash
source /etc/profile
APP_HOME=`pwd`

start() {
echo Running ...
nohup `pwd`/bin/startup.sh  >> /dev/null 2>&1 &
echo  The end!
}

stop() {
echo Stoping ...
cd $APP_HOME
ps -ef | grep $APP_HOME | grep -v grep | awk '{print $2}' | xargs kill -9
if [ $? -eq 0 ]
then
echo stop ok !
else
echo stop failed,please check !
fi
}

case "$1" in
        start)
          start
           ;;

        stop)
          stop
           ;;

      restart)
          stop
          start
           ;;

           *)
          echo "usage start|stop|restart"
           ;;

esac

