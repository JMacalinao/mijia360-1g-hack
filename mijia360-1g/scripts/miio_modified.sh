echo "### Modified startup (miio_modified.sh)"

echo "----- Disable timer"
systemctl stop imi.timer
systemctl disable imi.timer

echo "----- Initializing LED"
sh "${MCH_HOME}/scripts/led.sh" red init
sh "${MCH_HOME}/scripts/led.sh" green init
sh "${MCH_HOME}/scripts/led.sh" blue init

echo "----- Configuring network (LED green flash)"
sh "${MCH_HOME}/scripts/led.sh" red off
sh "${MCH_HOME}/scripts/led.sh" green flash
sh "${MCH_HOME}/scripts/led.sh" blue off

echo "----- Setting MAC address to Xiaomi"
DEVICE_CONFIG_FILE=/usr/imi/usrinfo/manufacture.info

if [ -f $DEVICE_CONFIG_FILE ]; then
    MAC=$(cat $DEVICE_CONFIG_FILE | grep '<mac>' | sed 's/\(<mac>\|<\/mac>\)//g')

    ip link set dev mlan0 down
    sleep 2
    ip link set dev mlan0 address "$MAC"
    sleep 2
    ip link set dev mlan0 up

    echo "MAC address now set to $MAC"
else
    echo "Error: Set MAC address failed"
fi

export LD_LIBRARY_PATH=/usr/imi/lib:$LD_LIBRARY_PATH

echo "----- WMM"
/usr/imi/config/mlanutl mlan0 psmode 0
/usr/imi/config/mlanutl mlan0 macctrl 0x13
/usr/imi/config/mlanutl mlan0 wmmparamcfg 0 2 3 2 150  1 2 3 2 150  2 2 3 2 150  3 2 3 2 150

# generate a default resolv.conf to set default dns server
echo "----- Default DNS server"
if [ ! -f "/tmp/resolv.conf" ]; then
    touch /tmp/resolv.conf
    echo "nameserver 8.8.8.8" >> /tmp/resolv.conf
    echo "nameserver 8.8.4.4" >> /tmp/resolv.conf
fi

echo "----- Connecting to Wi-Fi"
# Need to dump the output, TMI lol
/etc/miio/wifi_start.sh > /dev/null 2>&1

# Red LED, Wi-Fi connection failed
if [ "$?" != 0 ]; then
    sh "${MCH_HOME}/scripts/led.sh" green off
    sh "${MCH_HOME}/scripts/led.sh" red on
    echo "Error: Wi-Fi connection failed"
    exit 1
fi

# LED blue flash, wifi is OK
echo "----- Connection successful (LED blue flash)"
sh "${MCH_HOME}/scripts/led.sh" red off
sh "${MCH_HOME}/scripts/led.sh" green off
sh "${MCH_HOME}/scripts/led.sh" blue flash

if [ -n "${MCH_TIMEZONE}" ]; then
    echo "----- Synchronize time"
    /usr/sbin/ntpd -q -p "${MCH_NTP_SERVER}"
fi

if [ "$MCH_ENABLE_RTSP" = "true" ]; then
    echo "----- Starting RTSP"
    /usr/local/bin/test_encode -A -s
    /usr/local/bin/test_encode -B -s
    killall test_encode
    killall rtsp_server
    killall test_tuning
    sleep 5
    /usr/local/bin/test_tuning -a 0 &
    /usr/local/bin/test_encode -A -i 2560x1440 --bitrate 2000000 -f 30 --enc-mode 4 --lens-warp 1 --hdr-expo 1 --hdr-mode 0 -J --btype off -K --btype off -X --bmaxsize 1920x1080 --bsize 1920x1080 --smaxsize 1920x1080 -Y --bmaxsize 640x360 --bsize 640x360 -B -m 640x360 --smaxsize 640x360 --debug-enable 0
    sleep 5
    /usr/local/bin/rtsp_server &
    /usr/local/bin/test_encode -A -h 1080p --bitrate 2000000 --qp-limit-i "28~51" --profile 2 -N30 -e
    /usr/local/bin/test_encode -B -e
fi

if [ "$MCH_ENABLE_NIGHT_VISION" = "true" ]; then
    echo "----- Enabling night vision mode"
    sh -c '(sleep 3; printf "%s\n" h d 1; sleep 1; printf "%s\n" q q;) | /usr/local/bin/test_image -i 1'
    sh "${MCH_HOME}/scripts/ircut.sh" init
    sh "${MCH_HOME}/scripts/ircut.sh" on
fi

# All good now
if [ "$MCH_ENABLE_LED" = "true" ]; then
    sh "${MCH_HOME}/scripts/led.sh" blue on
else
    sh "${MCH_HOME}/scripts/led.sh" blue off
fi
