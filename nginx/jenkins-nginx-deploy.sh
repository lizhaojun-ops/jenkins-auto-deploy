#!/bin/sh
#自动发版静态页面

PART_LIST=$*
PART_T()
{
#参数获取
x=1 # 初始化参数
for n in `echo "$*"`
  do
        case "$n" in
          -f|f|-F|F)
              eval FROM_DIR=\${$(($x+1))}
              ;;
	  -n|n|-N|N)
              eval SERVER_LIST=\${$(($x+1))}
              ;;
          -w|w)
              eval PACKAGE_NAME=\${$(($x+1))}
              ;;
          -h|h|-H|H|help)
              HELP
              ;;
             *)
              x=$(($x+1))
              continue
        esac
        x=$(($x+1))
  done
}

SCP()
{
JUMP_USER='root'
JUMP_PASSWD='root'
JUMP_HOST='1.1.1.1'
JUMP_SSHPORT='22'
JUMP_DIR='/srv/data/autofaban/project'
#远程scp包
echo "[INFO]"
echo '[INFO] -------------------------------------------------------------------------------------------------------'
echo '[INFO] 正在将打包后的NGINX静态页tar包远程scp到192.168.1.2的跳板机'
echo '[INFO] -------------------------------------------------------------------------------------------------------'
echo "[INFO] 正在检查相关目录是否存在..."
sshpass -p ${JUMP_PASSWD} ssh -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} -o StrictHostKeyChecking=no "if [ ! -d $JUMP_DIR/$SERVER_LIST/appdir ]; then echo '[INFO] 未检测到远程目录,正在自动创建所需目录'; mkdir -p $JUMP_DIR/$SERVER_LIST/{appdir,backup}; else echo '[INFO] 目录已存在,无需重复创建! '; fi "
echo "[INFO] 正在将旧版本包备份到$JUMP_DIR/${SERVER_LIST}/backup"
sshpass -p ${JUMP_PASSWD} ssh -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} -o StrictHostKeyChecking=no "cd ${JUMP_DIR}/${SERVER_LIST}/appdir ;  mv ${PACKAGE_NAME} ../backup/${PACKAGE_NAME}_$(date +%Y-%m-%d-%H:%M) ; rm -rf ${PACKAGE_NAME}"
echo "[INFO] 正在将包scp到192.168.1.2的${JUMP_DIR}/${SERVER_LIST}/appdir "
sshpass -p ${JUMP_PASSWD} scp -r -o StrictHostKeyChecking=no -P${JUMP_SSHPORT} ${FROM_DIR} ${JUMP_USER}@${JUMP_HOST}:${JUMP_DIR}/${SERVER_LIST}/appdir/
sshpass -p ${JUMP_PASSWD} ssh -p ${JUMP_SSHPORT} ${JUMP_USER}@${JUMP_HOST} -o StrictHostKeyChecking=no "chmod -Rf 755 $JUMP_DIR"
echo '[INFO] 已将tar包scp到192.168.1.2跳板机'
echo '[INFO] -------------------------------------------------------------------------------------------------------'
}

if [ "$*x" != "x" ]
  then
    PART_T ${PART_LIST}
  else
    FROM_DIR=""
    SERVER_LIST=""
    if [ "${FROM_DIR}x" == "x" ] && [ "${SERVER_LIST}x" == "x" ] && [ "${PACKAGE_NAME}x" == "x" ]
      then
        echo 请正确传递参数，参数为 -f 包路径 -n 服务名 -w 包名称
        exit
    fi
fi

SCP

