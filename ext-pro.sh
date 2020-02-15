#!/bin/sh

# When script is started without any arguments, we assume it is the official startup
# We restart it with useless param and redirect output to log file on sdcard

if [ $# -eq 0 ]; then
    export MCH_DEVICE_NAME=mijia360-1g
    export MCH_SD=/sdcard
    export MCH_HOME=${MCH_SD}/${MCH_DEVICE_NAME}
    export MCH_LOGS=${MCH_SD}/log
    export MCH_TMP=/tmp/mch
    mkdir -p "${MCH_LOGS}"
    rm -R "${MCH_TMP}" 
    mkdir -p "${MCH_TMP}"
    $0 nop > "${MCH_LOGS}/${MCH_DEVICE_NAME}.log" 2>&1
    exit $?
fi

echo "### Mijia 360 Camera (1st-gen) Hack"
echo

# Export all available variables from ${MCH_SD}/config.ini
if [ -f ${MCH_SD}/config.ini ]; then
    echo "----- Export variables from ${MCH_SD}/config.ini"
    while read env_var; do
        if [ "${env_var:0:4}" = "MCH_" ]; then
            if [ "${env_var:0:9}" != "MCH_WIFI_" -a "${env_var:0:9}" != "MCH_ROOT_" ]; then
                echo -e "export ${env_var}"
            fi
            export "${env_var}"
        fi
    done < ${MCH_SD}/config.ini
    echo
    # Create MCH_ environment file
    export | grep MCH_ > "${MCH_TMP}/env.sh"

    echo "if [ \$# -eq 0 ]; then
        \$0 nop >> \"\${MCH_LOGS}/\${MCH_DEVICE_NAME}.log\" 2>&1
        exit \$?
    fi" >> "${MCH_TMP}/env.sh"
else
    echo "Error: ${MCH_SD}/config.ini not found"
fi

# In first versions of this hack, default root password was unknown.
# That's why we changed it to be able to connect using telnet.
# Now that default root password is known, we can revert back to it.
# We check if revert is needed only for the two first available firmwares:
#    3.3.2_2016071217
#    3.3.2_2016081814
# For future firmware, previous hack shouldn't be used anymore

FIRMWARE_VERSION=$(cat /etc/os-release)
MCH_SHADOW_BACKUP=${MCH_HOME}/etc/shadow.backup
if [ "${FIRMWARE_VERSION}" = "CHUANGMI_VERSION=3.3.2_2016071217" -o "${FIRMWARE_VERSION}" = "CHUANGMI_VERSION=3.3.2_2016081814" ]; then
    echo "----- Revert to known password (for first two firmwares)"
    if [ -f "${MCH_SHADOW_BACKUP}" ]; then
        diff /etc/shadow "${MCH_SHADOW_BACKUP}" > /dev/null
        if [ $? -eq 1 ]; then
            cp "${MCH_SHADOW_BACKUP}" /etc/shadow
        fi
    else
        echo "Error: ${MCH_SHADOW_BACKUP} not found"
    fi
fi

if [ -n "${MCH_TIMEZONE}" ]; then
    echo "----- Configure timezone"
    rm /etc/TZ
    echo "${MCH_TIMEZONE}" > /etc/TZ
    export TZ="${MCH_TIMEZONE}"
fi

if [ -n "${MCH_ROOT_PASSWORD}" ]; then
    echo "----- Setting root password"
    (echo "${MCH_ROOT_PASSWORD}"; echo "${MCH_ROOT_PASSWORD}") | passwd
fi

if [ -n "${MCH_WIFI_SSID}" ]; then
    echo "----- Creating Wi-Fi config for setup"
    echo "# Wifi config file, user & passwd
    ssid=${MCH_WIFI_SSID}
    psk=${MCH_WIFI_PASSWORD}" > "${MCH_TMP}/wifi.conf"
    mount --bind ${MCH_TMP}/wifi.conf /etc/miio/wifi.conf
fi

if [ "${MCH_ENABLE_TELNET}" = false ]; then
    echo "----- Telnet enabled by default, stopping service"
    systemctl stop telnet.socket
fi

if [ "${MCH_ENABLE_FTP}" = true ]; then
    echo "----- Starting FTP server"
    if [ -f ${MCH_HOME}/bin/tcpsvd ]; then
        ${MCH_HOME}/bin/tcpsvd -vE 0.0.0.0 21 ftpd -w / &
        sleep 1
    else
        echo "Error: FTP server start failed, ${MCH_HOME}/bin/tcpsvd not found"
    fi
fi

if [ "${MCH_ENABLE_SSH}" = true ]; then
    echo "----- Starting SSH server"
    if [ -f ${MCH_HOME}/bin/dropbear ]; then
        ## Security Purpose: recover previous RSA keys from SDCARD
        if [ -s "${MCH_HOME}/etc/dropbear_ecdsa_host_key" ]; then 
            echo "Recovering previous host keys"
            cp "${MCH_HOME}/etc/dropbear_ecdsa_host_key" /etc/dropbear
        fi

        ${MCH_HOME}/bin/dropbear -R -p 22

        ## Security Purpose: Save the keys in the SDCARD
        while [ ! -s /etc/dropbear/dropbear_ecdsa_host_key ]
        do
            sleep 2
        done

        if [ ! -s "${MCH_HOME}/etc/dropbear_ecdsa_host_key" ] &&
            [ -s /etc/dropbear/dropbear_ecdsa_host_key ]; then
            echo "Saving host keys"
            cp /etc/dropbear/dropbear_ecdsa_host_key "${MCH_HOME}//etc/"
        fi
    else
        echo "Error: FTP server start failed, ${MCH_HOME}/bin/tcpsvd not found"
    fi
fi

echo "----- Creating modified run script (to make stuff work)"
# Startup sequence is:
# /usr/local/bin/run.sh
#    /usr/imi/start.sh
#       /usr/local/bin/init.sh
#          /sdcard/ext-pro.sh
#       /usr/imi/miio.sh
#          /usr/imi/imiApp

# We virtually modify /usr/imi/miio.sh
# We create a modified version of /usr/imi/miio.sh in /tmp
# We mount the modified version in place of the official one, this modification is not persistent

# Create xiaomi_hack_env.sh / miio_pre.sh / miio.sh / miio_post.sh sequence
cat "${MCH_TMP}/env.sh" "${MCH_HOME}/scripts/miio_pre.sh" > "${MCH_TMP}/miio.sh"
if [ "${MCH_ENABLE_CLOUD}" = true ]; then
    export XIAOMI_HACK_DEVICE_NAME=${MCH_DEVICE_NAME}
    export XIAOMI_HACK_DEVICE_HOME=${MCH_HOME}
    export XIAOMI_LOGS=${MCH_LOGS}
    cat /usr/imi/miio.sh >> "${MCH_TMP}/miio.sh"
else
    cat "${MCH_HOME}/scripts/miio_modified.sh" >> "${MCH_TMP}/miio.sh"
fi
cat "${MCH_HOME}/scripts/miio_post.sh" >> "${MCH_TMP}/miio.sh"

# Make the modified version executable
chmod +x ${MCH_TMP}/miio.sh
# Mount the modified version in place of the official one, this modification is not persistent
mount --bind ${MCH_TMP}/miio.sh /usr/imi/miio.sh
echo
