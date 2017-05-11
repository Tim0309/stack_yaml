#!/bin/bash

my_STACK=APP

if [[  $# -ne 0 ]];then
    deploy_LIST="$@"
else
    clear 
    deploy_LIST="`ls *.yaml`"
    echo -e "\n\e[31m 清除旧stack ,请稍等...\e[m"
    docker stack rm  ${my_STACK}
    sleep 3
fi

clear
echo -e "\n即将部署stack为：\n\t${my_STACK}，\n部署服务文件为：\n\t${deploy_LIST}"
sleep 5

for i in ${deploy_LIST};do
    if [ -f ./$i ];then
        echo -e "\n\e[31m 开始部署服务 ${i%%.*} ,请稍等...\e[m"
        docker stack deploy -c $i ${my_STACK}
        echo -e "\n\e[31m 服务 ${i%%.*} 启动中,请稍等...\e[m"
        sleep 10
    else
        echo cannot access ${i}: No such file.
        sleep 3
        clear
    fi
    clear
done
