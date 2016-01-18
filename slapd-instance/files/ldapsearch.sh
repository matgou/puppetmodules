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

ldapsearch -Y EXTERNAL -H "ldapi://%2Fmnt%2F$ENV%2Frun%2Fldapi" $*
exit $?
