```ts
// todo:
forward IP from Traefik, to Nginx, php-fpm will use IP from Nginx
traefik.yml, nginx.conf

-----------
// configure registration email
// mora 2fa auth sa aegis otp code in google
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
TRUNCATE TABLE mybb_datacache; // empty...
// logs out all users
TRUNCATE TABLE mybb_sessions;

// limit ram redis, verify
redis-cli CONFIG GET maxmemory
redis-cli CONFIG GET maxmemory-policy
------------
// check client IP forward from Treafik works in Mybb
// open forum and refresh page, or see in admin panel
docker exec -it mybb php -r 'var_dump($_SERVER["REMOTE_ADDR"]);'

```
