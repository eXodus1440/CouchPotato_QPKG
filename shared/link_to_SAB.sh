#!/bin/sh

CMD_GETCFG="/sbin/getcfg"
CMD_SETCFG="/sbin/setcfg"
CMD_MKDIR="/bin/mkdir"
PUBLIC_SHARE=$($CMD_GETCFG SHARE_DEF defPublic -d Public -f /etc/config/def_share.info)
MULTIMEDIA=$($CMD_GETCFG SHARE_DEF defMultimedia -d Multimedia -f /etc/config/def_share.info)

SYS_QPKG_DIR=$($CMD_GETCFG CouchPotato Install_Path -f /etc/config/qpkg.conf)
SAB_INSTALLED=$($CMD_GETCFG SABnzbdPlus Status -f /etc/config/qpkg.conf)
SAB_LINKED=$($CMD_GETCFG core linked_to_sabnzbd -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf)

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

if [ "$SAB_INSTALLED" == "complete" ] ; then 
  # Get values from SABnzbdPlus Configs
  SABnzbdPlus_Path=$($CMD_GETCFG SABnzbdPlus Install_Path -f /etc/config/qpkg.conf)
  if [ -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini ] ; then
    SABnzbdPlus_WEBUI_HTTPS=$($CMD_GETCFG misc enable_https -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)
    SABnzbdPlus_WEBUI_IP=$($CMD_GETCFG misc host -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)
    if [ "$SABnzbdPlus_WEBUI_HTTPS" = "0" ]; then
      SABnzbdPlus_WEBUI_PORT=$($CMD_GETCFG misc port -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)
      $CMD_SETCFG sabnzbd host ${SABnzbdPlus_WEBUI_IP}:${SABnzbdPlus_WEBUI_PORT} -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    else
      SABnzbdPlus_WEBUI_PORT=$($CMD_GETCFG misc https_port -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)
      $CMD_SETCFG sabnzbd ssl 1 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
      $CMD_SETCFG sabnzbd host ${SABnzbdPlus_WEBUI_IP}:${SABnzbdPlus_WEBUI_PORT} -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    fi
    SABnzbdPlus_APIKEY=$($CMD_GETCFG misc api_key -f ${SABnzbdPlus_Path}/.sabnzbd/sabnzbd.ini)

    # Set SABnzbdPlus values in CouchPotato 
    $CMD_SETCFG sabnzbd enabled 1 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG sabnzbd api_key ${SABnzbdPlus_APIKEY} -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG sabnzbd category Movies -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf

    # Set Renamer values based on SABnzbdPlus values
    [ -d ${BASE}/${MULTIMEDIA}/Movies ] || $CMD_MKDIR -p ${BASE}/${MULTIMEDIA}/Movies
    $CMD_SETCFG renamer enabled 1 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG renamer from ${BASE}/${PUBLIC_SHARE}/Downloads/complete -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG renamer to ${BASE}/${MULTIMEDIA}/Movies -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG renamer cleanup 1 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf

    # Set a few defaults, assuming connecting into SABnzbdPlus and not Torrent
    $CMD_SETCFG core launch_browser 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG blackhole enabled 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG kickasstorrents enabled 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG torrentz enabled 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG searcher preferred_method nzb -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf

    # Disable the CouchPotato Updater and setup Wizard
    $CMD_SETCFG updater enabled 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG updater automatic 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG core show_wizard 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf

    # Set CouchPotato as linked to SABnzbdPlus
    $CMD_SETCFG core linked_to_sabnzbd 1 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
  fi
fi

exit 0
