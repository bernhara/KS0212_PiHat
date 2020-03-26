#! /bin/bash

# $Id: ks0212.sh,v 1.12 2018/07/01 06:04:25 bibi Exp $

COMMAND=$( basename "$0" )

declare -A KS_unit_to_WiringPi_pin_mapping
KS_unit_to_WiringPi_pin_mapping[U1]=7
KS_unit_to_WiringPi_pin_mapping[U2]=3
KS_unit_to_WiringPi_pin_mapping[U3]=22
KS_unit_to_WiringPi_pin_mapping[U4]=25

DEFAULT_SET_DELAY=500

: ${GPIO:=/usr/local/bin/gpio}
: ${no_test:=false}

if [ -z "${no_test}" -o "${no_test}" == "true" ]
then
    KS_command_prefix=""
else
    KS_command_prefix="echo"
fi

Usage () {
   msg="$1"
   echo "ERROR. $msg
Usage: ${COMMAND} set U1|U2|U3|U4 <delay> | probe set U1|U2|U3|U4
"
   exit 1
}

U_action="$1"
shift

case "${U_action}" in
    "set")
	;;
    "probe")
	;;
    *)
	Usage "bad action"
	exit 1
esac

U_arg="$1"
shift

case "${U_arg}" in
    U1|U2|U3|U4)
	U_unit="${U_arg}"
	wiringPi_pin=${KS_unit_to_WiringPi_pin_mapping[${U_unit}]}
	;;
    *)
	Usage "Bad unit arg: ${U_arg}"
	exit 1
	;;
esac

if [ "${U_action}" == "set" ]
then
    delay_arg="$1"
    if [ -z "${delay_arg}" ]
    then
	U_set_delay_ms="${DEFAULT_SET_DELAY}"
    else
	# check if provided delay is OK
	int_delay=$( expr ${delay_arg} + 0 2>/dev/null )
	if [ -z "${int_delay}" ]
	then
	    Usage "Bad delay: ${delay_arg}"
	    exit 1
	fi
	if [ 0 -gt ${int_delay} -o 10000 -lt ${int_delay} ]
	then
	    Usage "Delay out of range: ${delay_arg}"
	    exit 1
	fi
	U_set_delay_ms=${int_delay}

    fi
    toggle_sleep_delay_int_part=$(( ${U_set_delay_ms} / 1000 ))
    toggle_sleep_delay_decimal_part=$(( ${U_set_delay_ms} - ( ${toggle_sleep_delay_int_part} * 1000 ) ))
    toggle_sleep_delay="${toggle_sleep_delay_int_part}.${toggle_sleep_delay_decimal_part}"


    # set to LOW in case of program crash or normal exit
    trap "${KS_command_prefix} ${GPIO} write \"${wiringPi_pin}\" 0" EXIT

    ${KS_command_prefix} ${GPIO} mode "${wiringPi_pin}" output
    ${KS_command_prefix} ${GPIO} write "${wiringPi_pin}" 1
    sleep ${toggle_sleep_delay}
    ${KS_command_prefix} ${GPIO} write "${wiringPi_pin}" 0

    # end of "set"
    exit 0

fi

if [ "${U_action}" == "probe" ]
then
    current_value=$( ${GPIO} read "${wiringPi_pin}" )
    echo "${current_value}"
    exit 0
fi

