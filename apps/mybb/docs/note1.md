```ts
// todo:
        forward IP from Traefik, to Nginx, php-fpm will use IP from Nginx
        traefik.yml, nginx.conf // all in nginx.conf
write doc to manually migrate backup from varalicar.rs to rpi.varalicar.rs
-----------
// set user and group in data/mybb-data
// from ~/traefik-proxy/apps/mybb
sudo chown -R $MY_UID:$MY_GID ./data/mybb-data
-----------
// configure registration email
// mora 2fa auth sa aegis otp code in google
// app password url
https://myaccount.google.com/apppasswords
// smtp app password
radi i sa space i bez, bolje sa
abcd efgh ijkl mnop // exmaple
-------
dns fails -> mora mybb na external network
-------
// smtp settings, confirmation email on register
Mail Handler	SMTP
SMTP Host	smtp.gmail.com
SMTP Port	587 // for TLS
SMTP Username	varalaicar.rs@gmail.com
SMTP Password	app password with spaces
SMTP Encryption	TLS
------------
// redis
// https://docs.mybb.com/1.8/administration/cache-handlers/
// https://docs.mybb.com/1.8/administration/configuration-file/
// inc/config.php
$config['cache_store'] = 'redis';

$config['redis']['host'] = 'redis';
$config['redis']['port'] = 6379;
---------
// clean db cache table
// ! NE OVO, ovo ga je slomilo, registracija novih usera, corrupt db state
TRUNCATE TABLE mybb_datacache; // empty...
// logs out all users
TRUNCATE TABLE mybb_sessions;

// limit ram redis, verify
redis-cli CONFIG GET maxmemory
redis-cli CONFIG GET maxmemory-policy
------------
// Traefik IP, all in nginx.conf
// fails with Rathole and double Traefik, rpi
// check client IP forward from Treafik works in Mybb
// create php file, from ~/traefik-proxy/apps/mybb
echo '<?php var_dump($_SERVER["REMOTE_ADDR"]);' > data/mybb-data/ip.php
// open
https://varalicar.rs/ip.php
// in Mybb admin panel
Admin CP -> Users & Groups > Some user (Options), last IP address
----------
// change logo
Templates & Style -> Themes -> Default -> Edit Theme Properties -> Board Logo
----------
rpi.varalicar.rs shares cookie with varalicar.rs, login fails
MUST use private tab for rpi.varalicar.rs
---------
redis-data/dump.rdb se kreira kad ugasis container
delete ni ne izloguje usere
```

Cron local

```bash
#!/bin/bash
# Wrapper script to run backup and keep log < 2 MB

LOG_FILE="~/Desktop/mybb-backup/scripts/backup.log"
BACKUP_SCRIPT="~/Desktop/mybb-backup/scripts/run-backup-rsync-local.sh"

# Truncate log if bigger than 2 MB
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -ge $((2*1024*1024)) ]; then
    > "$LOG_FILE"
fi

# Run backup and append stdout+stderr to log
/bin/bash "$BACKUP_SCRIPT" >> "$LOG_FILE" 2>&1

# Todo:
# add this to bottom of existing script
# truncate from 2mb to 1mb
# make it function
```

Cron line

```bash
crontab -e

# Laptop

# Sync backup every day at 19:45 Belgrade time
TZ=Europe/Belgrade
45 19 * * * /home/username/mybb-backup/scripts/run-backup-rsync-local.sh

# OrangePi

# Set Belgrade time zone for all crons
TZ=Europe/Belgrade

# Sync backup every day at 23:45 Belgrade time
45 23 * * * /home/orangepi/mybb-backup/scripts/run-backup-rsync-local.sh

```

Copy to rpi home folder:

```bash
scp -r ~/mybb-backup username@rpi:~/

scp -r ~/mybb-backup orangepi@opi:~/
```

Forward client IP with Rathole

https://www.perplexity.ai/search/phpbb-client-ip-iza-tunela-i-2-xug9TYlfS7OSNYwRJIhDxA#0
https://chatgpt.com/s/t_6974f53533948191addc93725444deeb
https://chat.deepseek.com/share/ti87qepbplf1giu7uy

```bash
# debug cron
grep CRON /var/log/syslog | tail -50

```

Clean MyBB cache

Admin CP → Tools & Maintenance → Cache Manager → Empty All Caches
