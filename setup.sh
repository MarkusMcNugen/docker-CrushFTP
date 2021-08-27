#!/usr/bin/env bash

CRUSH_FTP_BASE_DIR="/var/opt/CrushFTP10"

cd $CRUSH_FTP_BASE_DIR

echo "$(date '+%d/%m/%Y %H:%M:%S') Starting setup.sh ..."

if [[ -f /tmp/CrushFTP10.zip ]] ; then
    echo "Unzipping CrushFTP..."
    unzip -o -q /tmp/CrushFTP10.zip -d /var/opt/
    rm -f /tmp/CrushFTP10.zip
fi

if [ -z ${CRUSH_ADMIN_USER} ]; then
    CRUSH_ADMIN_USER=crushadmin
fi

if [ -z ${CRUSH_ADMIN_PASSWORD} ] && [ -f admin_user_set ]; then
    CRUSH_ADMIN_PASSWORD="NOT DISPLAYED!"
elif [ -z ${CRUSH_ADMIN_PASSWORD} ] && [ ! -f admin_user_set ]; then
    CRUSH_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi

if [ -z ${CRUSH_ADMIN_PROTOCOL} ]; then
    CRUSH_ADMIN_PROTOCOL=http
fi

if [ -z ${CRUSH_ADMIN_PORT} ]; then
    CRUSH_ADMIN_PORT=8080
fi

if [[ ! -d users/MainUsers/${CRUSH_ADMIN_USER} ]] || [[ ! -f admin_user_set ]] ; then
    echo "Creating default admin..."
    java -jar CrushFTP.jar -a "${CRUSH_ADMIN_USER}" "${CRUSH_ADMIN_PASSWORD}"
    touch admin_user_set
fi

echo "$(date '+%d/%m/%Y %H:%M:%S') Starting..."

chmod +x crushftp_init.sh
./crushftp_init.sh start

echo "$(date '+%d/%m/%Y %H:%M:%S') Waiting..."

until [ -f prefs.XML ]
do
     sleep 1
done

echo "########################################"
echo "# Started:    $(date '+%d/%m/%Y %H:%M:%S')"
echo "# User:       ${CRUSH_ADMIN_USER}"
echo "# Password:   ${CRUSH_ADMIN_PASSWORD}"
echo "########################################"

# SIGTERM-handler
term_handler() {
    echo "# Stopping:   $(date '+%d/%m/%Y %H:%M:%S')"
    PS="ps"
    AWK="awk"
    GREP="grep"
    CRUSH_PID="`$PS -a | $GREP java | $GREP $CRUSH_FTP_BASE_DIR | $AWK '{print $1}'`"
    #echo "# CRUSH_PID:  ${CRUSH_PID}"

    echo -n "Shutting down CrushFTP... "
    kill $CRUSH_PID
    ret_val=$?
    if [ ${ret_val} -ne 0 ]; then
        echo FAIL
        echo could not kill PID
        exit 1
    fi 
    
    echo OK
    echo "# Stopped:    $(date '+%d/%m/%Y %H:%M:%S')"
    exit 0
}

trap 'term_handler' SIGTERM

while true
do
    sleep 60m &
    wait $!
done
