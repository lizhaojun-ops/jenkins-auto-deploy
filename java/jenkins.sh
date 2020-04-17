#/bin/bash!
# 打包命令区,如果配置成Maven类的JOB,可以去掉打包的步骤,执行脚本中只加入环境信息和最后的sh脚本就行,但是需要保留`set +x`
set +x
source ~/.bash_profile > /dev/null 2>&1
# 进行mvn打包或者ant打包,可以进行选择,如果是ant打包需要在JOB中配置选项参数 
mvn -U clean install -Dmaven.test.skip=true
#ant -f $xml

#如果配置成Maven类的JOB,可以去掉以上打包的步骤,配置下面的内容即可,但是需要保留`set +x`
#JOB中添加选项参数,判断属于哪个环境
if [ $ENV = test ]; then
   ip_list='测试服务器IP,如果多个IP可用英文格式,隔开'
elif [ $ENV = pre ]; then
   ip_list='预发布服务器IP,如果多个IP可用英文格式,隔开'
elif [ $ENV = pro ]; then
   ip_list='生产服务器IP,如果多个IP可用英文格式,隔开'
fi
 
US='root'          #默认为root
FROM_DIR=''        #这里是打完的jar或者是war包的路径,可用正则匹配
TO_HOME=''         #服务所在的目录
SERVER_NAME=''     #服务名,必须要和服务器上的目录保持一致,否则发版会失败
WAR_NAME=''        #jar,war包名,正则匹配就可以

# UPLOAD  1.上传到跳板机 2.远程登录跳板机实行ssh命令,下面则两行一般不做变化 
echo "时间:$(date +%Y-%m-%d-%H:%M) 服务:${SERVER_NAME}  发布环境:$ENV " >> /srv/logs/jenkins/deploy/${SERVER_NAME}-deplot.log
sh  /srv/app/jenkins/scripts/jenkins-java-deploy.sh -i ${ip_list} -u ${US} -f ${FROM_DIR} -t ${TO_HOME} -n ${SERVER_NAME} -w ${WAR_NAME}

