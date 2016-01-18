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
cd dirname $0
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

TMPDIR=$ROOT/tmp

# Coupure de l'instance
write_log INF "Coupure de l'instance LDAP $ENV"
$ROOT/shell/exploit.sh stop
test_rc $?
sleep 15

if [ ! -f $ROOT/config/slapd.d.tar.gz ]
then
  write_log ERR "Fichier slapd.d.tar.gz non present"
  exit 1
fi

if [ ! -d $ROOT/config/slapd.d ]
then
  cd $ROOT/config
  tar xvf slapd.d.tar.gz
fi

CONFIG=$ROOT/data/config.ldif

# Export de la config
slapcat -n 0 -F $ROOT/config/slapd.d > $CONFIG
test_rc $?

# Update pid an args
sed -i "s@olcArgsFile:.*@olcArgsFile: $ROOT/run/slapd.args@" $CONFIG
sed -i "s@olcPidFile:.*@olcPidFile: $ROOT/run/slapd.pid@" $CONFIG

# Suppression des datafile
write_log INF "suppression de la config"
rm -rf $ROOT/config/slapd.d/*

write_log INF "Import de la config"
slapadd -n 0 -F $ROOT/config/slapd.d < $CONFIG
test_rc $?

write_log INF "mise en place des droits"
chown -R $USER:$GROUP $ROOT

# Coupure de l'instance
write_log INF "Lancement de l'instance LDAP $ENV"
$ROOT/shell/exploit.sh start
test_rc $?

exit 0
