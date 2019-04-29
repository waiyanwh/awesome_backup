#!/bin/bash
# Variables for scripts
backup_dir=$(date +'%d-%m-%y')
cur_time=$(date +'%H-%M')
backup_db_dir=$backup_dir/backup_dbs
backup_json_dir=$backup_dir/backup_jsons
db_files=your/dir/where/sql_files/exist/*.sql
json_files=your/dir/where/json_files/exist*.json
gzfile=backup_$cur_time.tar.gz
day_count=7

# Check backup folder exist or not
function chkBackupDir() {
	if [[ ! -d $backup_dir ]] && [[ ! -d $backup_db_dir ]] && [[ ! -d $backup_json_dir ]]; then
		mkdir $backup_dir
		mkdir -p $backup_db_dir
		mkdir -p $backup_json_dir
	else
		echo "Folders already exist"
	fi
}

# Backup databases
function backup_db(){
	host='YOUR_DB_HOSTNAME'
	user='YOUR_DB_USERNAME'
	password='YOUR_DB_PASSWORD'
	database=( $(mysql -h $host -u $user -p$password -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|mysql|performance_schema|tmp|sys)") )
	for db in "${database[@]}"
	do
	        mysqldump -h $host -u $user -p$password $db > $db.sql
	        echo "Successfully backed-up database $db"
	done

}

# Backup json files
function backup_json(){
	cp -r your/json/path/*.json .
}

# Move files t backup and upload to google drive
function gdrive_upload(){	
	echo "Moving backup_dbs to backup folder"
	echo -e "******************************\n"
	mv $db_files $backup_db_dir 
	echo "Moving backup jsons to backup folder"
	echo -e "******************************\n"
	mv $json_files $backup_json_dir 
	echo "Compressing backups files to backup_$cur_dt.tar.gz"
	echo -e "********************************************\n"
	tar czf $gzfile $backup_dir
	echo "Creating $backup_dir in drive"
	echo -e "************************\n"
	rclone mkdir backup:YOUR_DIR_TO_STORE_BACKUP_IN_GDRIVE/$backup_dir
	echo "Upload files to google drive"
	echo -e "*************************\n"
	rclone copy $gzfile backup:YOUR_DIR_TO_STORE_BACKUP_IN_GDRIVE/$backup_dir
}

# Delete 1 week old file
function delete(){
	day_count=$(( $day_count+1 ))
	filename=( $(rclone lsd backup:YOUR_DIR_TO_STORE_BACKUP_IN_GDRIVE/ | awk '{print $5}') )
	del_file=$(date --date="$day_count days ago" +'%d-%m-%y')
	second=$(date -d $del_file +%s)
	for (( i=0; i < ${#filename[@]}; i++))
	do
		if (date --date ${filename[$i]} > /dev/null 2>&1); then 
			i_sec=$(date -d ${filename[$i]} +%s)
			if [ $i_sec -le $second ]; then
				rclone rmdir backup:YOUR_DIR_TO_STORE_BACKUP_IN_GDRIVE/$i
			fi
		fi	
	done
}


chkBackupDir
backup_db
backup_json
gdrive_upload
delete
