#!/bin/bash

# ########## variable ########## 
redis_NETWORK='gb-net'
redis_IMAGE='hub:5000/gb-redis:3.2.8'
redis_PORT=6379
# 命名规则有要求，请留意awk的匹配
redis_M_LIST=`docker service ls | awk '/.*_redis.*_m/{print $2}'`
redis_S_LIST=`docker service ls | awk '/.*_redis.*_s/{print $2}'`
# 获取当前swarm node ID
node_ID=`docker node ls  | awk  '/\*/{print $1}'`

# ########## function ##########
# 获取各redis vip
get_SERVICE_VIP(){
    for i in $1;do
        echo $( \
            docker service inspect \
                --format "{{ .Endpoint.VirtualIPs }}" \
                $i | \
            grep -Eo "[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}" \
            ):${redis_PORT}
    done
    echo
}

# ##########  __main__ ##########
echo -e "\e[31m====== redis master:======\e[0m"
get_SERVICE_VIP "$redis_M_LIST"

echo -e "\e[31m====== redis slave: ======\e[0m"
get_SERVICE_VIP "$redis_S_LIST"

master_VIP=(`get_SERVICE_VIP "$redis_M_LIST"`)
slave_VIP=`get_SERVICE_VIP "$redis_S_LIST"`
# 在当前节点创建临时容器, 创建master 集群
echo -e "\e[34m即将部署 redis cluster，\e[31m需要输入'yes'+回车...\e[0m"
docker run --rm -ti \
    --network ${redis_NETWORK} \
    ${redis_IMAGE} \
    redis-trib.rb create \
    ${master_VIP[*]}
echo -e "\e[34mmaster部署完成...OK...\n\n\e[0m"
sleep 3

# 逐一将 slave 添加到集群
slave_NO=1
for i in ${slave_VIP};do
    clear
    echo -e "\e[34m\n正在将 slave ${slave_NO} 添加到 redis 集群,请稍等...\t(无需操作)\e[0m"
    docker run --rm -ti \
        --network ${redis_NETWORK} \
        ${redis_IMAGE} \
        redis-trib.rb add-node \
        --slave \
        $i  ${master_VIP[1]}
    echo -e "\e[34m...OK\n\e[0m"
    sleep 2
    let slave_NO++
done
clear

