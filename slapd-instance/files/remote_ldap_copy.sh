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

echo $1 | grep -q "@"
if [ $? -eq 0 ];then
    ssh_string=`echo $1 | cut -f1 -d":"`
    file=`echo $1 | cut -f2 -d":"`
    ssh=1
else
    ssh=0
    file=$1
fi

if [ -z "$file" ] 
then
    write_log ERR "usage $0 backup.tar.gz"
    exit 355
fi

rm -rf $ROOT/tmp/backup_extract
mkdir $ROOT/tmp/backup_extract
cd $ROOT/tmp/backup_extract

if [ "x$ssh" == "x0" ]
then
  if [ ! -f $file ]
  then
    write_log ERR "le premiere parametres du shell doit etre le fichier"
    exit 1
  fi
  tar xvf $file
  test_rc $?
else
  scp $1 $ROOT/tmp/
  test_rc $?
  tar xvf $ROOT/tmp/`basename $file`
  test_rc $?
  rm $ROOT/tmp/`basename $file`
fi

TMPDIR=$ROOT/tmp

# Coupure de l'instance
write_log INF "Coupure de l'instance LDAP $ENV"
$ROOT/shell/exploit.sh stop
test_rc $?

# Suppression des datafile
write_log INF "Suppression des datafile"
rm -r $ROOT/ldap-datafile/*

write_log INF "suppression des schema"
rm -rf $ROOT/config/slapd.d/cn\=config/cn\=schema/*

write_log INF "suppression des bases"
rm $ROOT/config/slapd.d/cn\=config/olcDatabase* 

write_log INF "suppression des backend"
rm $ROOT/config/slapd.d/cn=\config/olcBackend*

write_log INF "suppression des modules"
rm $ROOT/config/slapd.d/cn\=config/cn\=module*

# Recupeartion de la configuration distante
CONFIG=$ROOT/tmp/backup_extract/config.ldif
write_log INF "Dump de la config dans $CONFIG"
test_rc $?

cd $TMPDIR
csplit $CONFIG '/^$/' '{*}' 2>/dev/null >/dev/null
for file in `ls xx*`
do
  newname=`head $file | sed -e "2q" -e "1d" | sed "s/^dn: //"`
  echo $newname | grep -q "="
  RC=$?
  if [ "x$RC" == "x0" ]
  then
    mv $file $newname
  fi
done 
rm $CONFIG

write_log INF "Insersion des modules"
for file in `ls cn\=module*,cn\=config`
do
  write_log INF "  -> chargement du fichier $file"
  slapadd -n 0 -F $ROOT/config/slapd.d < $file
  test_rc $?
done

write_log INF "Insersion des Backend"
for file in `ls olcBackend*,cn\=config`
do
  write_log INF "  -> chargement du fichier $file"
  slapadd -n 0 -F $ROOT/config/slapd.d < $file
  test_rc $?
done

write_log INF "Insersion des schemas"
for file in `ls *,cn\=schema\,cn\=config`
do
  write_log INF "  -> chargement du fichier $file"
  slapadd -n 0 -F $ROOT/config/slapd.d < $file
  test_rc $?
done

write_log INF "Insersion des bases techniques"
# on ignore la base frontend
rm olcDatabase\=\{-1\}frontend\,cn\=config
write_log INF "  -> chargement du fichier olcDatabase\=\{0\}config\,cn\=config"
slapadd -n 0 -F $ROOT/config/slapd.d < olcDatabase\=\{0\}config\,cn\=config
rm olcDatabase\=\{0\}config\,cn\=config

# Retablissement des droits 
write_log INF "Retablissement des droits"
chown -R $USER:$GROUP $ROOT/config
test_rc $?

# Lancement de l'instance
write_log INF "Lancement de l'instance LDAP $ENV"
$ROOT/shell/exploit.sh start
test_rc $?

# on change le root dans la base
sed -i "s@olcDbDirectory:.*@olcDbDirectory: $ROOT/ldap-datafile@" olcDatabase\=\{1\}hdb\,cn\=config
# on change le root dans la base accesslog
sed -i "s@olcDbDirectory:.*@olcDbDirectory: $ROOT/ldap-accesslog@" olcDatabase\=\{3\}hdb\,cn\=config
for file in `ls olcDatabase*,cn\=config`
do
  write_log INF "  -> chargement du fichier $file"
  sed -i "/entryCSN/d" $file
  sed -i "/modifiersName/d" $file
  sed -i "/modifyTimestamp/d" $file
  sed -i "/entryUUID/d" $file
  sed -i "/structuralObjectClass/d" $file
  sed -i "/creatorsName/d" $file
  sed -i "/createTimestamp/d" $file
  ldapadd -Y EXTERNAL -H "ldapi://%2Fmnt%2F$ENV%2Frun%2Fldapi" -f $file
  test_rc $?
done

write_log INF "Coupure de l'instance LDAP $ENV"
$ROOT/shell/exploit.sh stop
test_rc $?
sleep 20

write_log INF "Initialisation de la base"
cp $ROOT/tmp/backup_extract/* $ROOT/ldap-datafile/
RC=$?
write_log INF "RC=$RC"

# Construction des index
#write_log INF "Construction des index"
#slapindex -F $ROOT/config/slapd.d
#RC=$?
#write_log INF "RC=$RC"

# Retablissement des droits 
write_log INF "Retablissement des droits"
chown -R $USER:$GROUP $ROOT/config
test_rc $?
chown -R $USER:$GROUP $ROOT/ldap-datafile
test_rc $?
chown -R $USER:$GROUP $ROOT/ldap-accesslog
test_rc $?

# Lancement de l'instance
write_log INF "Lancement de l'instance LDAP $ENV"
$ROOT/shell/exploit.sh start
test_rc $?

rm -rf $TMPDIR/*
exit 0
