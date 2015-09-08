#!/bin/sh

CMD_GETCFG="/sbin/getcfg"
CMD_SETCFG="/sbin/setcfg"
SYS_QPKG_DIR=$($CMD_SETCFG CouchPotato Install_Path -f /etc/config/qpkg.conf)
SABnzbdPlus_Installed=$($CMD_SETCFG SABnzbdPlus Status -f /etc/config/qpkg.conf)

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

if [ "$SABnzbdPlus_Installed" == "complete" ] ; then 
  # Set a few defaults, assuming connecting into SABnzbdPlus and not Torrent
  $CMD_SETCFG core launch_browser 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
  $CMD_SETCFG blackhole enabled 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
  $CMD_SETCFG kickasstorrents enabled 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
  $CMD_SETCFG torrentz enabled 0 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
  $CMD_SETCFG searcher preferred_method nzb -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf

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
    $CMD_SETCFG renamer enabled 1 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG renamer from ${BASE}/${PUBLIC_SHARE}/Downloads/complete -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
    $CMD_SETCFG renamer cleanup 1 -f ${SYS_QPKG_DIR}/.couchpotato/settings.conf
  fi
fi    