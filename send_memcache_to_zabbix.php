<?php

$zabbix_sender = "/usr/bin/zabbix_sender";
//$zabbix_server = $_SERVER["argv"][1];
$zabbix_server = "172.16.35.92";
$zabbix_port = 10051;
$tmp_file = "/tmp/send_memcache.log";

function get_local_ip() {
    $preg = "/(172\.|10\.)((([0-9]?[0-9])|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))\.){2}(([0-9]?[0-9])|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))/";
    exec("ifconfig", $out, $stats);
    if (!empty($out)) {
        foreach($out as $value) {
            if (isset($value) && strstr($value, 'addr:')) {
                $tmpArray = explode(":", $value);
                $tmpIp = explode(" ", $tmpArray[1]);
                if (preg_match($preg, trim($tmpIp[0]))) {
                    return trim($tmpIp[0]);
                }
            }
        }
    }
}

function get_memcache($memcache_server,$memcache_port,$tmp_file){
    $file = fopen($tmp_file,"a");
    $m=new Memcache;
    $m->connect($memcache_server,$memcache_port);
    $s=$m->getstats();
    foreach($s as $key=>$value){
    fwrite($file,$memcache_server." ".$key.".".$memcache_port." ".$value."\n");
    };
    fclose($file);
}

$memcache_server = get_local_ip();
$filename = "/etc/rc.local";
$content = file_get_contents($filename);
preg_match_all("/(-p)(\d\d\d\d)/i",$content,$matches);
print_r($matches[2]);
foreach($matches[2] as $memcache_port){
    get_memcache($memcache_server,$memcache_port,$tmp_file); 
}

system("$zabbix_sender -z $zabbix_server -p $zabbix_port -i $tmp_file");

if(file_exists($tmp_file)){
    unlink($tmp_file);
}
?>
