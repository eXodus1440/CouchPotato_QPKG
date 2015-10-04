#!/bin/sh
CONF=/etc/config/qpkg.conf
CMD_GETCFG="/sbin/getcfg"
CMD_SETCFG="/sbin/setcfg"
CMD_MKDIR="/bin/mkdir"

PUBLIC_SHARE=$($CMD_GETCFG SHARE_DEF defPublic -d Public -f /etc/config/def_share.info)
MULTIMEDIA=$($CMD_GETCFG SHARE_DEF defMultimedia -d Multimedia -f /etc/config/def_share.info)
QPKG_NAME="CouchPotato"
QPKG_ROOT=$(${CMD_GETCFG} ${QPKG_NAME} Install_Path -f ${CONF})
QPKG_DATA=${QPKG_ROOT}/.couchpotato
QPKG_CONF=${QPKG_DATA}/settings.conf
SAB_INSTALLED=$($CMD_GETCFG SABnzbdPlus Status -f ${CONF})
SAB_LINKED=$($CMD_GETCFG core linked_to_sabnzbd -f ${QPKG_CONF})

# Exit if CouchPotato is already linked with SABnzbdPlus
if [ -n ${SAB_LINKED} ] && [ "${SAB_LINKED}" = "1" ] ; then 
  #echo "CouchPotato is already linked to SABnzbdPlus"
  exit 1
fi

# Determine BASE installation location according to smb.conf
BASE=
publicdir=`/sbin/getcfg $PUBLIC_SHARE path -f /etc/config/smb.conf`
if [ ! -z $publicdir ] && [ -d $publicdir ];then
  publicdirp1=`/bin/echo $publicdir | /bin/cut -d "/" -f 2`
  publicdirp2=`/bin/echo $publicdir | /bin/cut -d "/" -f 3`
  publicdirp3=`/bin/echo $publicdir | /bin/cut -d "/" -f 4`
  if [ ! -z $publicdirp1 ] && [ ! -z $publicdirp2 ] && [ ! -z $publicdirp3 ]; then
    [ -d "/${publicdirp1}/${publicdirp2}/${PUBLIC_SHARE}" ] && BASE="/${publicdirp1}/${publicdirp2}"
  fi
fi
####

# Determine BASE installation location by checking where the Public folder is.
if [ -z $BASE ]; then
  for datadirtest in /share/HDA_DATA /share/HDB_DATA /share/HDC_DATA /share/HDD_DATA /share/MD0_DATA; do
    [ -d $datadirtest/$PUBLIC_SHARE ] && BASE="/${publicdirp1}/${publicdirp2}"
  done
fi
if [ -z $BASE ] ; then
  echo "The Public share not found."
  /sbin/write_log "[$QPKG_NAME] The Public share not found." 1
  exit 1
fi
####

[ -d ${SYS_QPKG_DIR}/.couchpotato ] || mkdir -p ${SYS_QPKG_DIR}/.couchpotato
[ -f ${QPKG_CONF}] || touch ${QPKG_CONF}

if [ "$SAB_INSTALLED" == "complete" ] ; then 
  # Get values from SABnzbdPlus Configs
  SABnzbdPlus_Path=$($CMD_GETCFG SABnzbdPlus Install_Path -f ${CONF})
  SABnzbdPlus_CONF=${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini
  if [ -f ${SABnzbdPlus_CONF} ] ; then
    SABnzbdPlus_WEBUI_HTTPS=$($CMD_GETCFG misc enable_https -f ${SABnzbdPlus_CONF})
    SABnzbdPlus_WEBUI_IP=$($CMD_GETCFG misc host -f ${SABnzbdPlus_CONF})
    if [ "$SABnzbdPlus_WEBUI_HTTPS" = "0" ]; then
      SABnzbdPlus_WEBUI_PORT=$($CMD_GETCFG misc port -f ${SABnzbdPlus_CONF})
      $CMD_SETCFG sabnzbd host ${SABnzbdPlus_WEBUI_IP}:${SABnzbdPlus_WEBUI_PORT} -f ${QPKG_CONF}
    else
      SABnzbdPlus_WEBUI_PORT=$($CMD_GETCFG misc https_port -f ${SABnzbdPlus_CONF})
      $CMD_SETCFG sabnzbd ssl 1 -f ${QPKG_CONF}
      $CMD_SETCFG sabnzbd host ${SABnzbdPlus_WEBUI_IP}:${SABnzbdPlus_WEBUI_PORT} -f ${QPKG_CONF}
    fi
    SABnzbdPlus_USER=$($CMD_GETCFG misc username -f ${SABnzbdPlus_CONF})
    SABnzbdPlus_PASS=$($CMD_GETCFG misc password -f ${SABnzbdPlus_CONF})
    SABnzbdPlus_APIKEY=$($CMD_GETCFG misc api_key -f ${SABnzbdPlus_CONF})

    # Set SABnzbdPlus values in CouchPotato 
    $CMD_SETCFG sabnzbd enabled 1 -f ${QPKG_CONF}
    #$CMD_SETCFG sabnzbd username ${SABnzbdPlus_USER} -f ${QPKG_CONF}
    #$CMD_SETCFG sabnzbd password ${SABnzbdPlus_PASS} -f ${QPKG_CONF}
    $CMD_SETCFG sabnzbd api_key ${SABnzbdPlus_APIKEY} -f ${QPKG_CONF}
    $CMD_SETCFG sabnzbd category Movies -f ${QPKG_CONF}

    # Set Renamer values based on SABnzbdPlus values
    [ -d ${BASE}/${MULTIMEDIA}/Movies ] || $CMD_MKDIR -p ${BASE}/${MULTIMEDIA}/Movies
    $CMD_SETCFG renamer enabled 1 -f ${QPKG_CONF}
    $CMD_SETCFG renamer from ${BASE}/${PUBLIC_SHARE}/Downloads/complete/Movies -f ${QPKG_CONF}
    $CMD_SETCFG renamer to ${BASE}/${MULTIMEDIA}/Movies -f ${QPKG_CONF}
    $CMD_SETCFG renamer cleanup 1 -f ${QPKG_CONF}

    # Set a few defaults, assuming connecting into SABnzbdPlus and not Torrent
    $CMD_SETCFG core launch_browser 0 -f ${QPKG_CONF}
    $CMD_SETCFG blackhole enabled 0 -f ${QPKG_CONF}
    $CMD_SETCFG kickasstorrents enabled 0 -f ${QPKG_CONF}
    $CMD_SETCFG torrentz enabled 0 -f ${QPKG_CONF}
    $CMD_SETCFG searcher preferred_method nzb -f ${QPKG_CONF}

    # Disable the CouchPotato Updater and setup Wizard
    $CMD_SETCFG updater enabled 0 -f ${QPKG_CONF}
    $CMD_SETCFG updater automatic 0 -f ${QPKG_CONF}
    $CMD_SETCFG core show_wizard 0 -f ${QPKG_CONF}

    # Set CouchPotato as linked to SABnzbdPlus
    $CMD_SETCFG core linked_to_sabnzbd 1 -f ${QPKG_CONF}
  fi
fi

exit 0
