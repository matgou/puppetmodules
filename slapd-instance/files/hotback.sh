#!/bin/bash
#@****************************************************************************
#@ Author : Mathieu GOULIN (mathieu.goulin@gadz.org)
#@ Organization : Gadz.org (www.gadz.org) 
#@ Licence : GNU/GPL
#@ 
#@ Description : 
#@               
#@ Prerequisites :
#@ Arguments : 
#@
#@****************************************************************************
#@ History :
#@  - Mathieu GOULIN - 2015/12/26 : Initialisation du script
#@****************************************************************************
 
# Static configuration
cd `dirname $0`
script=`basename "$0" | cut -f1 -d"."`
log_file=`pwd`/$script.log
 
# Usage function
function usage () {
    # TODO - Write the good stuff here...
    echo "$0 [start|stop|restart]"
}
# Help function
function help () {
    usage
    echo
    grep -e "^#@" $script.sh | sed "s/^#@//"
}
 
# Log function
write_log () {
    log_state=$1
    shift;
    log_txt=$*
    log_date=`date +'%Y/%m/%d %H:%M:%S'`
    case ${log_state} in
        BEG)    chrtra="[START]"      ;;
        CFG)    chrtra="[CONF ERR]"   ;;
        ERR)    chrtra="[ERROR]"      ;;
        END)    chrtra="[END]"        ;;
        INF)    chrtra="[INFO]"       ;;
        *)      chrtra="[ - ]"        ;;
    esac
    echo "$log_date $chrtra : ${log_txt}" | tee -a ${log_file} 2>&1
}

test_rc () {
  if [ "x$1" != "x0" ]
  then
    write_log ERR "Erreur RC=$1"
    exit $1
  fi
}

. `dirname $0`/../config/config.sh

# On netoi les archives logs
write_log INF "Netoyage des archives logs devenu inutile"
$ROOT/shell/clean.sh
test_rc $?

# creation du repertoire de backup
TH=`date +%Y%m%d_%H%M%S`
mkdir -p $ROOT/ldap-backup/$TH
mkdir -p $ROOT/ldap-backup/$TH/ldap-datafile

# Make hotbackup
write_log INF "Sauvegarde a chaud des datafiles"
db5.3_hotbackup -v -b $ROOT/ldap-backup/$TH/ldap-datafile/ -h $ROOT/ldap-datafile 2>&1 | tee -a ${log_file}
test_rc $?

cd $ROOT/ldap-backup/$TH/ldap-datafile
# export config
write_log INF "Export config"
slapcat -n 0 -F $ROOT/config/slapd.d > config.ldif

# Make archive
write_log INF "Archivages et compression : $ROOT/ldap-backup/ldap-datafile_$TH.tar.gz"
tar -czvf $ROOT/ldap-backup/ldap-datafile_$TH.tar.gz *
test_rc $?

cd ~
rm -rf $ROOT/ldap-backup/$TH
write_log INF "Fin de la sauvegarde a chaud"
exit $?
