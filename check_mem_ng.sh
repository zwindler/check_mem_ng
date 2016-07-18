#!/bin/bash
################################################################################
#This plugin is loosely inspired by check_mem v1.1 from Lukasz Gogolin
#https://exchange.nagios.org/directory/Plugins/System-Metrics/Memory/check_mem-2Esh/details
#I did a code cleanup and added a check of "free" version, because since
#procps-ng 3.3.0 (RHEL 7+) check_mem.sh doesn't work anymore (buff/cache column)
################################################################################
# 1.1 - Added -l flag and LEGACY_PERFATA var to put legacy perfdata mode
################################################################################
#Nagios Constants
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
SCRIPTPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
if [[ -f ${SCRIPTPATH}/utils.sh ]]; then
        . ${SCRIPTPATH}/utils.sh # use nagios utils to set real STATE_* return values
fi

#Useful functions
printversion(){
        echo "$0 $VERSION"
        echo
}

printusage() {
        printversion
        echo "Usage:"
        echo "  check_mem_ng.sh [-w <warnlevel>] [-c <critlevel>] [-v] [-l]"
        echo "    checks local host available memory"
        echo "    warnlevel and critlevel is percentage value without %"
        echo "    defaults being respectively 80 et 90"
        echo "    add -v for verbose (debuging purpose)"
        echo "    add -l for legacy perfdata mode (or change LEGACY_PERFDATA variable in script)"
        echo "  check_mem_ng.sh -V"
        echo "    prints version"
        echo "  check_mem_ng.sh -h"
        echo "    prints help (this message)"
}


printvariables() {
        echo "Variables:"
        #Add all your variables at the en of the "for" line to display them in verbose
        for i in WARNING_THRESHOLD CRITICAL_THRESHOLD FINAL_STATE FINAL_COMMENT LEGACY_PERFDATA FREE_OUTPUT TOTAL_MEM FREE_MEM BUFFCACHE_MEM BUFF_MEM CACHE_MEM USED_MEM TOTAL_MEM_MB USED_MEM_MB WARNING_THRESHOLD_B CRITICAL_THRESHOLD_B USED_MEM_PRC ENABLE_PERFDATA VERSION
        do
                echo -n "$i : "
                eval echo \$${i}
        done
        echo
}

#Set to unknown in case of unplaned exit
FINAL_STATE=$STATE_UNKNOWN
FINAL_COMMENT="UNKNOWN: Unplaned exit. You should check that everything is alright"

#Default values
WARNING_THRESHOLD=80
CRITICAL_THRESHOLD=90
ENABLE_PERFDATA=1
VERSION="1.1"
VERBOSE=0

#####FORCE LEGACY MODE#####
#put 1 to force legacy perfdata mode without using "-l" flag (no configuration change in nrpe.cfg)
LEGACY_PERFDATA=0
#####FORCE LEGACY MODE#####

#Process arguments
while getopts ":c:hlvVw:" opt; do
        case $opt in
                c)
                        CRITICAL_THRESHOLD=$OPTARG
                        ;;
                h)
                        printusage
                        exit $STATE_OK
                        ;;
                l)
                        LEGACY_PERFDATA=1
                        ;;
                v)
                        echo "Verbose mode ON"
                        echo
                        VERBOSE=1
                        ;;
                V)
                        printversion
                        exit $STATE_UNKNOWN
                        ;;
                w)
                        WARNING_THRESHOLD=$OPTARG
                        ;;
                \?)
                        echo "UNKNOWN: Invalid option: -$OPTARG"
                        exit $STATE_UNKNOWN
                        ;;
                :)
                        echo "UNKNOWN: Option -$OPTARG requires an argument."
                        exit $STATE_UNKNOWN
                        ;;
        esac
done

#Real check begins here
FREE_OUTPUT=`free -b | grep Mem:`
TOTAL_MEM=`echo $FREE_OUTPUT |awk '{print $2}'`
FREE_MEM=`echo $FREE_OUTPUT |awk '{print $4}'`
if [ `free -V | grep procps-ng | wc -l` -eq 1  ]; then
        #procps-ng, free will display buff/cache as one column
        BUFFCACHE_MEM=`echo $FREE_OUTPUT |awk '{print $6}'`
        if [ $LEGACY_PERFDATA -eq 1 ] ; then
                #Get BUFFER and CACHE separatly for legacy output
                FREE_OUTPUT2=`free -b | grep Mem:`
                BUFF_MEM=`echo $FREE_OUTPUT2 |awk '{print $6}'`
                CACHE_MEM=`echo $FREE_OUTPUT2 |awk '{print $7}'`
        fi
else
        #procps, free will display buff/cache as two separate columns
        BUFF_MEM=`echo $FREE_OUTPUT |awk '{print $6}'`
        CACHE_MEM=`echo $FREE_OUTPUT |awk '{print $7}'`
        BUFFCACHE_MEM=$(($BUFF_MEM+$CACHE_MEM))
fi

#Deduce used memory from total/free/buffer+cache
USED_MEM=$(($TOTAL_MEM-$FREE_MEM-$BUFFCACHE_MEM))

#Convert in MB for pseudo "human readable" plugin output. Todo, real human readable?
TOTAL_MEM_MB=`echo "$TOTAL_MEM / 1048576" | bc`
USED_MEM_MB=`echo "$USED_MEM / 1048576" | bc`
WARNING_THRESHOLD_B=`echo "$WARNING_THRESHOLD * $TOTAL_MEM / 100" | bc`
CRITICAL_THRESHOLD_B=`echo "$CRITICAL_THRESHOLD * $TOTAL_MEM / 100" | bc`

#Convert in percents used memory
USED_MEM_PRC=$((($USED_MEM*100)/$TOTAL_MEM))

#Check if available memory is below thresholds
if [ "$USED_MEM_PRC" -ge "$CRITICAL_THRESHOLD" ]; then
        FINAL_STATE=$STATE_CRITICAL
        FINAL_COMMENT="CRITICAL: Memory above critical threshold. Total: ${TOTAL_MEM_MB} MB - Used: ${USED_MEM_MB} MB - ${USED_MEM_PRC}% used!"
elif [ "$USED_MEM_PRC" -ge "$WARNING_THRESHOLD" ]; then
        FINAL_STATE=$STATE_WARNING
        FINAL_COMMENT="WARNING: Memory above warning threshold. Total: ${TOTAL_MEM_MB} MB - Used: ${USED_MEM_MB} MB - ${USED_MEM_PRC}% used!"
else
        FINAL_STATE=$STATE_OK
        FINAL_COMMENT="OK: Memory below thresholds. Total: ${TOTAL_MEM_MB} MB - Used: ${USED_MEM_MB} MB - ${USED_MEM_PRC}% used."
fi

#Perfdata processing
if [ $ENABLE_PERFDATA -eq 1 ] ; then
        #Added check_mem.sh legacy perfdata mode, to ease migration
        if [ $LEGACY_PERFDATA -eq 1 ] ; then
                PERFDATA=" | TOTAL=$TOTAL_MEM;;;; USED=$USED_MEM;;;; CACHE=$CACHE_MEM;;;; BUFFER=$BUFF_MEM;;;;"
        else
                PERFDATA=" | Memory_Used=${USED_MEM}B;$WARNING_THRESHOLD_B;$CRITICAL_THRESHOLD_B;0;$TOTAL_MEM;"
        fi
fi

#Script end, display verbose information
if [[ $VERBOSE -eq 1 ]] ; then
        printvariables
fi

echo ${FINAL_COMMENT}${PERFDATA}
exit $FINAL_STATE
