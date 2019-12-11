# Update Redis Server database with TOSS DHCP IP Blocks
# Run every minute
* * * * * ${install.dir}/toss-iu.sh > /dev/null 2>&1

## 
# Delete '${service_file.title}' log files after 30 day
# Run every day at 12:00 AM
0 0 * * * find ${log.dir}/ -mtime +30 -exec rm -f {} ';'

