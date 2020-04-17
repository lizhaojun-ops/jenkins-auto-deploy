#!/bin/sh
#edit by lizj2
#最后更新: 修复了一些打包的问题

PART_LIST=$*
PART_T()
{
#参数获取
x=1 # 初始化参数
for n in `echo "$*"`
  do
        case "$n" in
          -i|i|-I|I)
              eval IP_LIST=\${$(($x+1))}     #服务器IP
              ;;
          -u|u|-U|U)
              eval USER=\${$(($x+1))}        #服务器用户
              ;;
#          -p|p|-P|P)
#              eval PWD=\${$(($x+1))}         #服务器密码
#              ;;
          -t|t|-T|T)
              eval TO_DIR=\${$(($x+1))}      #远程目录
              ;;
          -f|f|-F|F)
              eval FROM_DIR=\${$(($x+1))}    #打完的包路径,可以使用正则匹配
              ;;
	  -n|n|-N|N)
              eval SERVER_LIST=\${$(($x+1))}      # 服务名,主要跳板机使用
              ;;
          -w|w)
              eval WAR_NAME=\${$(($x+1))}         #打完的包名,主要是跳板机使用
              ;;
          -h|h|-H|H|help)                         #错误提示
              HELP
              ;;
             *)
              x=$(($x+1))
              continue
        esac
        x=$(($x+1))
  done
}

JUMP_USER=' '     #跳板机用户,建议为root
JUMP_PASSWD=' '   #跳板机用户密码
JUMP_HOST=' '     #跳板机IP
JUMP_SSHPORT=' '  #跳板机SSH端口
JUMP_DIR=' '      #跳板机中的存放目录

#首先进行传包
SCP()
{
#远程scp包
echo '[INFO] -------------------------------------------------------------------------------------------------------'
echo '[INFO] 正在将打包后的jar、war包远程scp到10.100.5.25的跳板机'
echo '[INFO] -------------------------------------------------------------------------------------------------------'
echo "[INFO] 正在检查相关目录是否存在..."
sshpass -p ${JUMP_PASSWD} ssh -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} -o StrictHostKeyChecking=no "if [ ! -d $JUMP_DIR/$SERVER_LIST/appdir ]; then echo '[INFO] 未检测到远程目录,正在自动创建所需目录'; mkdir -p $JUMP_DIR/$SERVER_LIST/{appdir,backup}; else echo '[INFO] 目录已存在,无需重复创建! '; fi "
echo "[INFO] 正在将旧版本包备份到$JUMP_DIR/${SERVER_LIST}/backup"
sshpass -p ${JUMP_PASSWD} ssh -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} -o StrictHostKeyChecking=no "cd ${JUMP_DIR}/${SERVER_LIST}/appdir ;  mv ${WAR_NAME} ../backup/${WAR_NAME}_$(date +%Y-%m-%d-%H:%M) ; rm -rf ${WAR_NAME}"
echo "[INFO] 正在将包scp到10.100.5.25的${JUMP_DIR}/${SERVER_LIST}/appdir "
sshpass -p ${JUMP_PASSWD} scp -r -o StrictHostKeyChecking=no -P${JUMP_SSHPORT} ${FROM_DIR} ${JUMP_USER}@${JUMP_HOST}:${JUMP_DIR}/${SERVER_LIST}/appdir/
sshpass -p ${JUMP_PASSWD} ssh -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} -o StrictHostKeyChecking=no "chmod -Rf 755 $JUMP_DIR"
echo '[INFO] 已将jar、war包scp到10.100.5.25跳板机'
echo '[INFO] -------------------------------------------------------------------------------------------------------'
}

#两层SSH,通过跳板机进行版本更新
YCFB()
{
echo '[INFO] -------------------------------------------------------------------------------------------------------'
echo '[INFO] 正在跳板机上进行远程发版'
echo '[INFO] -------------------------------------------------------------------------------------------------------'
echo '[INFO] 正在将新版本包SCP到远程服务器上'
echo "[INFO] 准备更新 ${IP_LIST} 上的 ${SERVER_LIST} 服务,请稍后"
#for循环进行SCP包
  for IP in `echo "${IP_LIST}"|awk -F, 'BEGIN{OFS=" "}{$1=$1;printf("%s",$0);}'`
   do 
    for NAME in `echo "${SERVER_LIST}" |awk -F, 'BEGIN{OFS=" "}{$1=$1;printf("%s",$0);}'`
      do 
       if [ ! $FROM_DIR ] 
         then 
           echo "复制源文件或者目录不存在,请检查是否设置jar/war包路径"   
           exit
         else
          echo "检查远程目录是否正确"
          IF_ID=`sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} "ssh ${USER}@${IP} 'if [ -d ${TO_DIR}/${NAME} ]; then echo yes;else echo no;fi' "`
          if [ "${IF_ID}x" == "yesx" ]
           then 
            IF_DIR=`sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} "ssh ${USER}@${IP} 'if [ -d ${TO_DIR}/${NAME}/bak ]; then echo yes;else no; fi' "`
              if [ "${IF_DIR}x" == "yesx" ]
              then
                #############
                ## jar服务 ##
                #############
                echo "识别为jar服务"
              #  if [ -x ${RUN_DIR}/fbauto.sh ]
              #   then
              #     nohup sh ${RUN_DIR}/fbauto.sh ${IP} ${NAME} >/dev/null &
              #   fi
                  echo "${USER}@${IP} cd ${TO_DIR}/${NAME}/; mv ${WAR_NAME} ./bak/${WAR_NAME}_$(date +%Y%m%d%H);rm -rf ${WAR_NAME%.*}"
                  echo 1
                  echo "停止服务中"
                  sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} "ssh ${USER}@${IP} 'cd ${TO_DIR}/${NAME}/; bash app.sh stop;' "
                  echo 2
                  echo "备份旧版本包"
                  sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} "ssh ${USER}@${IP} 'cd ${TO_DIR}/${NAME}/;mv ${WAR_NAME} ./bak/${WAR_NAME}_$(date +%Y%m%d%H);rm -rf ${WAR_NAME%.*};' "
                  echo 3
                  echo "将${JUMP_DIR}/${NAME}/appdir/${WAR_NAME} 拷贝到 ${USER}@${IP}:${TO_DIR}/${NAME}/."
                  sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} "scp -r -o StrictHostKeyChecking=no -P22 ${JUMP_DIR}/${NAME}/appdir/${WAR_NAME}  ${USER}@${IP}:${TO_DIR}/${NAME}/."
                  sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} "ssh ${USER}@${IP} 'cd ${TO_DIR}/${NAME}/; chmod 644 ${WAR_NAME}' "
                  echo 4
                  echo "远程重启 cd ${TO_DIR}/${NAME}/; source ~/.bash_profile; bash app.sh start"
                  sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} "ssh ${USER}@${IP} 'cd ${TO_DIR}/${NAME}/;  source ~/.bash_profile; bash app.sh start' "
              else 
                 #############
                 ## war服务 ## 
                 #############
                  echo "识别为war服务"
                  # if [ -x ${RUN_DIR}/fbauto.sh ]
                  #   then
                  #   nohup sh ${RUN_DIR}/fbauto.sh ${IP} ${NAME} >/dev/null &
                  # fi
                  echo "${USER}@${IP} cd ${TO_DIR}/${NAME}/webapps; mv ${WAR_NAME} ./bak/${WAR_NAME}_$(date +%Y%m%d%H);rm -rf ${WAR_NAME%.*}"
                  echo 1
                  echo "停止服务中"
                  sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} "ssh ${USER}@${IP} 'cd ${TO_DIR}/${NAME}/; bash app.sh stop;' "
                  echo 2
                  echo "备份旧版本包"
                  sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} " ssh ${USER}@${IP} 'cd ${TO_DIR}/${NAME}/webapps;mv ${WAR_NAME} ./bak/${WAR_NAME}_$(date +%Y%m%d%H);rm -rf ${WAR_NAME%.*};' "
                  echo 3
                  echo "将${JUMP_DIR}/${NAME}/appdir/${WAR_NAME} 拷贝到 ${USER}@${IP}:${TO_DIR}/${NAME}/webapps/."
                  sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} "scp -r -o StrictHostKeyChecking=no -P22 ${JUMP_DIR}/${NAME}/appdir/${WAR_NAME}  ${USER}@${IP}:${TO_DIR}/${NAME}/webapps/."
                  sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} "ssh ${USER}@${IP} 'cd ${TO_DIR}/${NAME}/webapps/; chmod 644 ${WAR_NAME}' "
                  echo 4
                  echo "远程重启 cd ${TO_DIR}/${NAME}/; source ~/.bash_profile; bash app.sh start"
                  sshpass -p ${JUMP_PASSWD} ssh -o StrictHostKeyChecking=no -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} "ssh ${USER}@${IP} 'cd ${TO_DIR}/${NAME}/;  source ~/.bash_profile; bash app.sh start' "
              fi
           fi
        fi
     done
   done

#    if [[ "${NAME}x" =~ _[0-6] ]]
#        then
#          SERVER_NAME=${NAME%_*}
#        else
#          SERVER_NAME=${NAME}
#      fi
#      if [ -x ${RUN_DIR}/fbauto.sh ]
#        then
#          nohup sh ${RUN_DIR}/fbauto.sh fbjs ${SERVER_NAME} >/dev/null &
#          sleep 2
#      fi    

}


if [ "$*x" != "x" ]
  then
    PART_T ${PART_LIST}
  else
    IP_LIST=""
    USER=""
#   PWD=""
    TO_DIR=""
    FROM_DIR=""
    SERVER_LIST=""
    if [ "${IP_LIST}x" == "x" ] && [ "${SERVER_LIST}x" == "x" ] && [ "${WAR_NAME}x" == "x" ]
      then
        echo "请正确传递参数，参数为 -i 192.168.1.1 -u user -t todir -f fromdir -n servername -w war_name"
        exit
    fi
fi

SCP
YCFB


