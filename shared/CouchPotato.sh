#!/bin/sh
CONF=/etc/config/qpkg.conf
QPKG_NAME="CouchPotato"
QPKG_ROOT=`/sbin/getcfg $QPKG_NAME Install_Path -f ${CONF}`
WEBUI_PORT=5050

case "$1" in
  start)
    ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
    if [ "$ENABLED" != "TRUE" ]; then
        echo "$QPKG_NAME is disabled."
        exit 1
    fi
    
    /opt/bin/python2.6 ${QPKG_ROOT}/CouchPotato.py --daemon --pid_file=${QPKG_ROOT}/couchpotato-${WEBUI_PORT}.pid --data_dir=${QPKG_ROOT}/.couchpotato
    ;;

  stop)
    PID=$(cat ${QPKG_ROOT}/couchpotato-${WEBUI_PORT}.pid)
    kill -9 ${PID}

    # Clean up PIDFile
    if [ -f ${QPKG_ROOT}/couchpotato-${WEBUI_PORT}.pid ] ; then /bin/rm -f ${QPKG_ROOT}/couchpotato-${WEBUI_PORT}.pid ; fi
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0
