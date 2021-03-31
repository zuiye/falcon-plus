# docker 17.5以上版本



# 1. Start mysql and init the mysql table before the first running

mkdir -p /opt/openfalcon/mysql-data
chmod 777 /opt/openfalcon/mysql-data

## start mysql in container
docker run -itd \
    --name falcon-mysql \
    -v /opt/openfalcon/mysql-data:/var/lib/mysql \
    -e MYSQL_ROOT_PASSWORD=test123456 \
    -p 3306:3306 \
    mysql:5.7

sleep 10s


## init mysql table before the first running
cd /tmp && \
git clone --depth=1 https://github.com/open-falcon/falcon-plus.git && \
cd /tmp/falcon-plus/ && \
for x in `ls ./scripts/mysql/db_schema/*.sql`; do
    echo init mysql table $x ...;
    docker exec -i falcon-mysql mysql -uroot -ptest123456 < $x;
done

rm -rf /tmp/falcon-plus/


# 2. Start redis in container

docker run --name falcon-redis -p6379:6379 -d redis:4-alpine3.8


# 3. Start falcon-plus modules in one container

mkdir -p /opt/openfalcon/falcon-plus/data
mkdir -p /opt/openfalcon/falcon-plus/logs

## pull images from hub.docker.com/openfalcon
# docker pull openfalcon/falcon-plus:v0.3



# # # 修改源码重新build
cd /tmp && \
git clone http://git.fnetlink.com/jaydenl/falcon-plus.git && \
cd /tmp/falcon-plus/ && \
docker build -t falcon-plus:v0.3 .




## run falcon-plus container
docker run -itd --name falcon-plus \
        --link=falcon-mysql:db.falcon \
        --link=falcon-redis:redis.falcon \
        -p 8433:8433 \
        -p 8080:8080 \
        -e MYSQL_PORT=root:test123456@tcp\(db.falcon:3306\) \
        -e REDIS_PORT=redis.falcon:6379  \
        -v /opt/openfalcon/falcon-plus/data:/open-falcon/data \
        -v /opt/openfalcon/falcon-plus/logs:/open-falcon/logs \
        falcon-plus:v0.3

sleep 10s

## start falcon backend modules, such as graph,api,etc.
docker exec falcon-plus sh ctrl.sh start graph hbs judge transfer nodata aggregator agent gateway api alarm

## check status of backend modules
docker exec falcon-plus ./open-falcon check


# 4. Start falcon-dashboard in container

docker run -itd --name falcon-dashboard \
    -p 8081:8081 \
    --link=falcon-mysql:db.falcon \
    --link=falcon-plus:api.falcon \
    -e API_ADDR=http://api.falcon:8080/api/v1 \
    -e PORTAL_DB_HOST=db.falcon \
    -e PORTAL_DB_PORT=3306 \
    -e PORTAL_DB_USER=root \
    -e PORTAL_DB_PASS=test123456 \
    -e PORTAL_DB_NAME=falcon_portal \
    -e ALARM_DB_HOST=db.falcon \
    -e ALARM_DB_PORT=3306 \
    -e ALARM_DB_USER=root \
    -e ALARM_DB_PASS=test123456 \
    -e ALARM_DB_NAME=alarms \
    -w /open-falcon/dashboard openfalcon/falcon-dashboard:v0.2.1  \
    './control startfg'



