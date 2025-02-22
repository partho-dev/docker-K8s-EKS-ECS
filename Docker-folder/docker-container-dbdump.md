docker ps
find the mysql container name or id

- DUmp the DB
- docker exec -it db-container-name mysqldump -u user_name --password=password db_name > any_backup_name

- docker exec -it blog-site-db mysqldump -u partho --password=secret wordpress > wordpress_backup.sql


- Copy from your local to the application container
- kubectl cp wordpress_backup.sql wordpress-pod:/tmp/wordpress_backup.sql -n lia-ns-wordpress                                        

- now restore the db to the rds
- mysql --binary-mode=1 -h blog-aurora-clu.cluster-cdkacpt.us-east-1.rds.amazonaws.com -u rds_user -p rds_db_name < /tmp/wordpress_backup.sql