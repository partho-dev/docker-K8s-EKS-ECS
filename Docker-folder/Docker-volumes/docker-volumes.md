docker named volumme 
bind mounts

1. Docker volume is created, managed by the docker engine and we as a human would not have any access to that volume

2. bind mounts, is created and managed by the human and it is used by the docker to store the persistant data



Example: 
1. Create a mysql db using `named docker volume `

- Without any named volume. So, the data for this container is not persistant
- docker container run -d --name mydb -e "MYSQL_ROOT_PASSWORD=secret" mysql:latest 

- with named volume
- docker container run -d --name mydb -e "MYSQL_ROOT_PASSWORD=secret" --mount source="dbData", target=/var/lib/mysql  mysql:latest 


- Login to the mysql from local (mysql has to be installed)
- mysql -u root -p <above-pass> -h host_ip -P 3306


2. `Bind Mount volume` `type=bind`

- docker container run 0d -p 80:80 --mount type=bind, source="$(pwd)",target=/var/www/html nginx