#获取 文件名,IP范围,用户名,远程地址
FILE_PATH=$1
REMOTE_IP=$2
REMOTE_USER=$3
REMOTE_PATH=$4

#解析IP表达式
function parse_ip(){
	IP=""
	#echo "parse ip ..."
	IP_STR=$1
	if [[ $IP_STR =~ "," ]];then
		#192.168.1.200,192.168.1.201,192.168.1.201
		IP=`echo $IP_STR | sed "s/,/ /g"`
	elif [[ $IP_STR =~ "-" ]];then
		#192.168.1.200-192.168.1.205
		IP_START=`echo "$IP_STR" | awk -F '-' '{print $1}'`
		IP_END=`echo "$IP_STR" | awk -F '-' '{print $2}'`
		#echo "IP_START: $IP_START  IP_END: $IP_END"

		IP_PRE_FIRST=`echo "$IP_START" | awk -F '.' '{print $1"."$2"."$3}'`
		IP_PRE_LAST=`echo "$IP_END" | awk -F '.' '{print $1"."$2"."$3}'`
		if [[ "$IP_PRE_FIRST" != "$IP_PRE_LAST" ]];then
			echo "ERROR \
				IP参数格式异常,不在同一个网络中 \
				start:$IP_PRE_FIRST  end:$IP_PRE_LAST"
			exit -1
		fi
		IP_PRE=$IP_PRE_FIRST
		#echo "IP_PRE : $IP_PRE"

		IP_NUM_START=`echo "$IP_START" | awk -F '.' '{print $4}'`
		IP_NUM_END=`echo "$IP_END" | awk -F '.' '{print $4}'`
		IP=`eval echo $IP_PRE.{$IP_NUM_START..$IP_NUM_END}`
	else
		IP=$IP_STR
	fi
	#for ip in $IP;do
	#	echo $ip
	#done
	echo $IP
}

#设置默认值
if [[ -z $REMOTE_USER ]];then
	REMOTE_USER="root"
fi
if [[ -z $REMOTE_PATH ]];then
	REMOTE_PATH="/data"
fi

echo "本次复制文件为 $FILE_PATH" 


#解析IP参数
IP_LIST=$(parse_ip $REMOTE_IP)
if [[ $IP_LIST =~ "ERROR" ]];then
	echo $IP_LIST
	exit -1
fi



echo -e "\nip result: $IP_LIST \n"
for ip in $IP_LIST;do
	ssh $REMOTE_USER@$ip "if [[ ! -e $REMOTE_PATH ]];then echo 目录不存在,创建目录$REMOTE_PATH && mkdir $REMOTE_PATH; else echo 目录存在,准备复制文件; fi" 
	#复制文件
	echo "scp $FILE_PATH $REMOTE_USER@$ip:$REMOTE_PATH"
	scp $FILE_PATH $REMOTE_USER@$ip:$REMOTE_PATH
	if [[ $? -eq 0 ]];then
		echo -e "$ip 复制成功! \n"
 	else
		echo -e "$ip 复制失败! \n"
	fi
done

