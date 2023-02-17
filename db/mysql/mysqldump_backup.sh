#!/bin/bash
################################
# 用于全量备份 InnoDB 数据库数据   #
################################

mysql_user="root"       #MySQL备份用户
mysql_password="123456" #MySQL备份用户的密码
mysql_host="127.0.0.1"
mysql_port="3306"
mysql_database=("backuptest") #要备份的数据库名称，多个用空格分开隔开 如("db1" "db2" "db3")
backup_dir="/tmp/backup/db"
mysql_charset="utf8"      #MySQL编码
expire_backup_delete="ON" #是否开启过期备份删除 ON为开启 OFF为关闭
backup_file_expire_day=7  #过期时间天数 默认为三天，此项只有在expire_backup_delete开启时有效

for dbname in "${mysql_database[@]}"; do
  echo "start backup database $dbname"
  mkdir -p "$backup_dir"

  backup_file_path="$backup_dir"/"$dbname-$(date +%Y%m%d%H%M%S)".sql
  if [ -f "$backup_file_path" ]; then
    echo "ERROR: $backup_file_path already exists, data may be lost if overwritten"
    break
  fi
  #--skip-opt 关闭一些不必要的选项
  #--single-transaction 保证 InnoDB 备份一致性
  #--source-data=2 以注释形式保存备份时的 binlog 位置信息，MySQL 8.0之前应使用 master-data
  #--no-autocommit 避免一个语句一次提交，减少提交次数
  #--quick 快速导出，不需要等加载完数据才导出，还可以节约内存
  #--databases 指定数据库
  #--default-character-set=utf8mb4 指定默认字符集
  mysqldump -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password --skip-opt --default-character-set=$mysql_charset --single-transaction --source-data=2 --flush-logs --no-autocommit --quick --databases "$dbname" >"$backup_file_path"
  flag=$?
  if [ ! "$flag" = "0" ]; then
    echo "Database $dbname backup failed"
    break
  fi

  echo "Database $dbname successfully backed up to $backup_file_path"

  # 如果开启了删除过期备份，则进行删除操作
  if [ "$expire_backup_delete" == "ON" ]; then
    find "$backup_dir" -name "*.sql" -mtime +"$backup_file_expire_day" -exec rm -rf {} \;
    echo "Outdated files removed for database $dbname"
  fi
done

echo "done."
