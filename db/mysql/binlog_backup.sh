#!/bin/bash
################################
# 用于增量备份本地的 binlog       #
################################
mysql_user="root"       #MySQL备份用户
mysql_password="123456" #MySQL备份用户的密码
mysql_host="127.0.0.1"
mysql_port="3306"

backup_base_dir="/tmp/backup/db/binlog" # 构造备份文件存储根目录，会按照日期归类
expire_backup_delete="ON"               #是否开启过期备份删除 ON为开启 OFF为关闭
backup_file_expire_day=7                #过期时间天数 默认为三天，此项只有在expire_backup_delete开启时有效

################################
#      尽量不要修改后面的内容      #
################################

# 检查是否启用了 binlog
binlog_enabled=$(mysql -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password -N -e "SHOW VARIABLES LIKE 'log_bin';" | awk '{print $2}')
if [ "$binlog_enabled" = "ON" ]; then
  # 获取当前 binlog 索引文件
  binlog_index_file=$(mysql -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password -e "show variables like 'log_bin_index';" | grep log_bin_index | awk '{print $2}')
  # 如果 binlog_index 文件不存在，退出脚本
  if [ ! -f "${binlog_index_file}" ]; then
    echo "Binlog is enabled, but ${binlog_index_file} not exists."
    exit
  fi
else
  echo "Binlog is not enabled."
  exit
fi

# 获取当前 binlog 存储目录
binlog_dir=$(mysql -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password -e "show variables like 'log_bin_basename';" | grep log_bin_basename | awk '{print $2}' | xargs -n1 dirname)

# 刷新日志，并获取最新的 binlog 文件名
last_binlog_file_name=$(mysql -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password -e "FLUSH LOGS;SHOW MASTER STATUS\G" | grep "File" | awk '{print $2}')

# 先备份到临时目录，所以的备份成功才移动到备份目录
tmpDir=$(mktemp -d)
start_timestamp=$(date +%s)
# 遍历备份 binlog_index 文件中的所有 binlog 文件
while read -r line; do
  current_bin_log_file_name=$(basename "$line")
  current_binlog_file="${binlog_dir}/${current_bin_log_file_name}"
  # binlog 存在
  if [ -f "${current_binlog_file}" ]; then
    # 不备份最新的
    if [ ! "$current_bin_log_file_name" = "${last_binlog_file_name}" ]; then
      backup_binlog_file="$tmpDir/${start_timestamp}.${current_bin_log_file_name}"
      echo "backup binlog $current_binlog_file to $backup_binlog_file"
      mysqlbinlog "$current_binlog_file" >"$backup_binlog_file"
    fi
  else
    echo "ERROR: ${current_binlog_file} not exists."
    exit
  fi
done <"${binlog_index_file}"

# 所有的 binlog 都备份成功了

current_backup_dir=$backup_base_dir/$(date +%Y%m%d)
mkdir -p "$current_backup_dir"

echo "mv $tmpDir to $current_backup_dir"
mv "$tmpDir"/* "$current_backup_dir"

# 清理已备份日志
mysql -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password -e "PURGE BINARY LOGS TO '${last_binlog_file_name}';"

# 如果开启了删除过期备份，则进行删除操作
if [ "$expire_backup_delete" == "ON" ]; then
  find "$(dirname "$current_backup_dir")" -mtime +"$backup_file_expire_day" -exec rm -rf {} \;
  echo "Outdated files removed for database binlog"
fi

echo "done."
