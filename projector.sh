#!/bin/bash

# Use echo -e "$(~/control/projector.sh status)\n\n" to print all output at once, rather than as it comes
# (for some reason we lose the final two blank lines from the output, hence the \n\n !)
# (could add an '&' at the end to run command in the background, in case it locks up for some reason..?)

usage () {
	echo "Usage: $(basename $0) command [parameter] [ip-address [port]]"
}

help () {
	usage
	echo
	echo "Command  Parameter"
	echo "Status                      Get current status of projector"
	echo "Power    On|Off|Status      Turn projector on or off, or get power status"
	echo "Shutter  Open|Close|Status  Open or close the shutter, or get status"
}

if [ $# = 0 ]; then
	help
	exit
fi

# Default IP address and port:
IP_ADDRESS=192.168.1.120
PJLINK_PORT=4352

# Close shutter
#COMMAND="%1AVMT 31"
# Open shutter
#COMMAND="%1AVMT 30"
# Shutter status
#COMMAND="%1AVMT ?"

# usage: pjlink command
pjlink () {
	echo -en "${1}\r" | nc -n4 ${IP_ADDRESS} ${PJLINK_PORT} | tr '\r' '\n'
}

# usage: header human-friendly-command
header () {
	printf "\n\n%s\t\t*** %s ***\n\n" "$(date)" "${1}"
}

# usage: footer
footer () {
	printf "\n\n"
}

status () {
	header "Projector: Status"
	
	echo "Projector Status:"

	# Power status
	RES=$(pjlink "%1POWR ?")
	case ${RES:16} in
		0) STATUS="Stand-by";;
		1) STATUS="Power on";;
		2) STATUS="Cooling down";;
		3) STATUS="Warming up";;
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*)  STATUS="Unrecognised status!";;
	esac
	echo "Power:                  ${STATUS}"
	
	# Input status
	RES=$(pjlink "%1INPT ?")
	case ${RES:16} in
		11) STATUS="11: RGB 1 (Component)";;
		12) STATUS="12: RGB 2 (VGA)";;
		21) STATUS="21: Video 1 (Composite Video)";;
		22) STATUS="22: Video 2 (S-Video)";;
		31) STATUS="31: Digital 1 (DVI-D)";;
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*)  STATUS="Unrecognised status! (${RES:16})";;
	esac
	echo "Input:                  ${STATUS}"
	
	# Shutter status
	RES=$(pjlink "%1AVMT ?")
	case ${RES:16} in
		11)   STATUS="Video Mute On (Shutter closed?)";;
		21)   STATUS="Audio Mute On";;
		31)   STATUS="Audio and Video Mute On - Shutter closed";;
		30)   STATUS="Audio and Video Mute Off - Shutter open";;
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*)  STATUS="Unrecognised status! (${RES:16})";;
	esac
	echo "AV Mute / Shutter:      ${STATUS}"
	
	# Error status
	RES=$(pjlink "%1ERST ?")
	case ${RES:16} in
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*) case ${RES:16:1} in
			0) STATUS="Okay";;
			1) STATUS="Warning";;
			2) STATUS="Error";;
			*) STATUS="Unrecognised status! (${RES:16:1})";;
		   esac
		   echo "Error Status:           Fan:         ${STATUS}"
		   case ${RES:17:1} in
			0) STATUS="Okay";;
			1) STATUS="Warning";;
			2) STATUS="Error";;
			*) STATUS="Unrecognised status! (${RES:17:1})";;
		   esac
		   echo "                        Lamp:        ${STATUS}"
		   case ${RES:18:1} in
			0) STATUS="Okay";;
			1) STATUS="Warning";;
			2) STATUS="Error";;
			*) STATUS="Unrecognised status! (${RES:18:1})";;
		   esac
		   echo "                        Temperature: ${STATUS}"
		   case ${RES:19:1} in
			0) STATUS="Okay";;
			1) STATUS="Warning";;
			2) STATUS="Error";;
			*) STATUS="Unrecognised status! (${RES:19:1})";;
		   esac
		   echo "                        Cover open:  ${STATUS}"
		   case ${RES:20:1} in
			0) STATUS="Okay";;
			1) STATUS="Warning";;
			2) STATUS="Error";;
			*) STATUS="Unrecognised status! (${RES:20:1})";;
		   esac
		   echo "                        Filter:      ${STATUS}"
		   case ${RES:21:1} in
			0) STATUS="Okay";;
			1) STATUS="Warning";;
			2) STATUS="Error";;
			*) STATUS="Unrecognised status! (${RES:21:1})";;
		   esac
		   echo "                        Other:       ${STATUS}"
		   ;;
	esac

	# Lamp status
	RES=$(pjlink "%1LAMP ?")
	case ${RES:16} in
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*)  STATUS=""
		    LAMP=0
		    COUNT=$(echo ${RES:16} | wc -w | tr -d " ")
		    for VAL in ${RES:16}; do
			if [ "$STATUS" = "" ]; then
			 STATUS="Usage: $VAL hours"
			 let LAMP+=1
			else
			 if [ $LAMP = 1 ]; then
			  echo -n "Lamp Status:            "
			 else
			  echo -n "                        "
			 fi
			 if [ $COUNT -ge 3 ]; then echo -n "Lamp $LAMP: "; fi
			 case $VAL in
				0) echo -n "Off";;
				1) echo -n "On";;
				*) echo -n "Unknown state ($VAL)";;
			 esac
			 echo "; $STATUS"
			 STATUS=""
			fi
		    done
		    if [ "$STATUS" ]; then
			if [ $LAMP = 1 ]; then
			 echo -n "Lamp Status:            "
			else
			 echo -n "                        "
			fi
			if [ $COUNT -ge 3 ]; then echo -n "Lamp $LAMP: "; fi
			echo "$STATUS"
		    fi
		    if [ $LAMP = 0 ]; then
			echo "Lamp Status:            No information returned"
		    fi;;
	esac
	
	# Input List
	RES=$(pjlink "%1INST ?")
	case ${RES:16} in
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*)  STATUS="${RES:16}";;
	esac
	echo "Input List:             ${STATUS}"
	
	# Projector Name
	RES=$(pjlink "%1NAME ?")
	case ${RES:16} in
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*)  STATUS="${RES:16}";;
	esac
	echo "Projector Name:         ${STATUS}"
	
	# Projector Manufacturer
	RES=$(pjlink "%1INF1 ?")
	case ${RES:16} in
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*)  STATUS="${RES:16}";;
	esac
	echo "Projector Manufacturer: ${STATUS}"
	
	# Projector Model
	RES=$(pjlink "%1INF2 ?")
	case ${RES:16} in
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*)  STATUS="${RES:16}";;
	esac
	echo "Projector Model:        ${STATUS}"
	
	# Other Projector Info
	RES=$(pjlink "%1INFO ?")
	case ${RES:16} in
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*)  STATUS="${RES:16}";;
	esac
	echo "Other Projector Info:   ${STATUS}"
	
	# PJLink Class
	RES=$(pjlink "%1CLSS ?")
	case ${RES:16} in
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*)  STATUS="${RES:16}";;
	esac
	echo "PJLink Class:           ${STATUS}"
	
	footer
}

power () {
	
	case $1 in
		on|1)	
			COMMAND="Power On"
			PJ_COMMAND="%1POWR 1"
			;;
		off|of|0)
			COMMAND="Power Off"
			PJ_COMMAND="%1POWR 0"
			;;
		status|-s|?)
			COMMAND="Power Status"
			PJ_COMMAND="%1POWR ?"
			;;
	esac

	header "Projector: ${COMMAND}"
	
	# Power status
	RES=$(pjlink "${PJ_COMMAND}")
	case ${RES:16} in
		0)    STATUS="Stand-by";;
		1)    STATUS="Power on";;
		2)    STATUS="Cooling down";;
		3)    STATUS="Warming up";;
		OK)   STATUS="Done!";;
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR2) STATUS="Projector didn't recognise parameter!";;
		ERR3) STATUS="Unable to get status at this time";;
		ERR4) STATUS="Projector Failure";;
		*)    STATUS="Unrecognised status!";;
	esac
	echo "${COMMAND}: ${STATUS}"
	
	footer
}


shutter () {
	
	case $1 in
		on|close|-c|1)	
			COMMAND="Shutter Close"
			PJ_COMMAND="%1AVMT 31"
			;;
		off|of|open|-o|0)
			COMMAND="Shutter Open"
			PJ_COMMAND="%1AVMT 30"
			;;
		status|-s|?)
			COMMAND="Shutter Status"
			PJ_COMMAND="%1AVMT ?"
			;;
	esac

	header "Projector: ${COMMAND}"
	
	# Power status
	RES=$(pjlink "${PJ_COMMAND}")
	case ${RES:16} in
		11)   STATUS="Video Mute On (Shutter closed?)";;
		21)   STATUS="Audio Mute On";;
		31)   STATUS="Audio and Video Mute On - Shutter closed";;
		30)   STATUS="Audio and Video Mute Off - Shutter open";;
		OK)   STATUS="Done!";;
		ERR1) STATUS="Projector didn't recognise command!";;
		ERR2) STATUS="Projector didn't recognise parameter!";;
		ERR3) if [ ${PJ_COMMAND:7} = "?" ]; then
			STATUS="Unable to get status at this time"
		      else
			STATUS="Unable to set status at this time"
		      fi;;
		ERR4) STATUS="Projector Failure";;
		*)    STATUS="Unrecognised status!";;
	esac
	echo "${COMMAND}: ${STATUS}"
	
	footer
}
	

COMMAND=$(echo "$1" | tr "A-Z" "a-z")
PARAMETER=$(echo "$2" | tr "A-Z" "a-z")
case $COMMAND in
	status)	if [ $# -ge 2 ]; then IP_ADDRESS=$2; fi
		if [ $# -ge 3 ]; then PJLINK_PORT=$3; fi
		if [ $# -gt 3 ]; then echo "Error: Too many parameters!"; usage; exit; fi
		status
		;;
	power)	case $PARAMETER in
			on|off|of|-s|status|1|0|?)
				if [ $# -ge 3 ]; then IP_ADDRESS=$2; fi
				if [ $# -ge 4 ]; then PJLINK_PORT=$3; fi
				if [ $# -gt 4 ]; then echo "Error: Too many parameters!"; usage; exit; fi
				power "$PARAMETER"
				;;
			"")	echo "Error: No Parameter supplied for Power command"
				usage
				;;
			*)	echo "Error: Unknown Parameter for Power command: '$2'"
				usage
				;;
		esac
		;;
	shutter) case $PARAMETER in
			on|off|open|close|-o|-c|-s|status|1|0|?)
				if [ $# -ge 3 ]; then IP_ADDRESS=$2; fi
				if [ $# -ge 4 ]; then PJLINK_PORT=$3; fi
				if [ $# -gt 4 ]; then echo "Error: Too many parameters!"; usage; exit; fi
				shutter "$PARAMETER"
				;;
			"")	echo "Error: No Parameter supplied for Power command"
				usage
				;;
			*)	echo "Error: Unknown Parameter for Power command: '$2'"
				usage
				;;
		esac
		;;
	help)	help
		;;
	*)	echo "Error: Unknown Command: '$1'"
		usage
		;;
esac
