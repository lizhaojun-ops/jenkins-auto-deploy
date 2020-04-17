#!/bin/bash
source /etc/profile
path=`pwd`
#year=`date +%Y`
#month=`date +%m`
#day=`date +%d`
JAVA_HOME='/srv/app/tools/java/jdk1.8.0_40'
jar_name=`ls | grep boot.jar`

start() {
echo Running ...
cd $path
echo "临时功能:已经将该应用的gc日志备份到了/srv/logs下"
cp ./logs/gc.log  /srv/logs/gc-$(date +%Y%m%d%H%M).log
#测试环境
#开启logback-access
#nohup $JAVA_HOME/bin/java  -jar -Xms1024M -Xmx1024M   -XX:+PrintGCDateStamps -XX:+PrintGCDetails -Xloggc:./logs/gc.log -Dlogging.config=./logback-spring.xml  Dlogback.access.config=./logback-access.xml $jar_name  >> /dev/null  2>&1 &
#不开启logback-access(默认不开启)
nohup $JAVA_HOME/bin/java  -jar -Xms1024M -Xmx1024M  -XX:+PrintGCDateStamps -XX:+PrintGCDetails -Xloggc:./logs/gc.log -Dlogging.config=./logback-spring.xml  $jar_name  >> /dev/null  2>&1 &

#生产环境
#开启logback-access
#nohup $JAVA_HOME/bin/java  -jar -Xms8g -Xmx8g -Xmn3g -Xss256k -XX:PermSize=128m -XX:MaxPermSize=512m -XX:+PrintGCDateStamps -XX:+PrintGCDetails -Xloggc:./logs/gc.log -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=19000 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dlogging.config=./logback-spring.xml -Dlogback.access.config=./logback-access.xml  $jar_name  >> /dev/null  2>&1 &
#不开启logback-access(默认不开启)
nohup $JAVA_HOME/bin/java  -jar -Xms8g -Xmx8g -Xmn3g -Xss256k -XX:PermSize=128m -XX:MaxPermSize=512m -XX:+PrintGCDateStamps -XX:+PrintGCDetails -Xloggc:./logs/gc.log -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=19000 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dlogging.config=./logback-spring.xml  $jar_name  >> /dev/null  2>&1 &

echo  The end!
}

stop() {
echo Stoping ...
ps -ef | grep $jar_name |grep -v grep |awk '{if($3 >1) print $2 " " $3 ; else print $2}' |xargs kill -9
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

