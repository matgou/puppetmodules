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
 
. `dirname $0`/../config/config.sh

db5.3_archive -a -h $ROOT/ldap-datafile | while read fic
do
    rm $fic
done
exit 0
