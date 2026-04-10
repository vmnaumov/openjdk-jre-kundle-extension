#!/bin/sh

##
#
#  Get from NiLuJe BatteruStatus extension
#
##

# We need to get the proper constants for our model...
kmfc="$(cut -c1 /proc/usid)"

if [ "${kmfc}" == "B" ] || [ "${kmfc}" == "9" ] ; then
	# Older device ID scheme
	kmodel="$(cut -c3-4 /proc/usid)"
	case "${kmodel}" in
		"13" | "54" | "2A" | "4F" | "52" | "53" )
			# Voyage...
			SCREEN_X_RES=1088	# NOTE: Yes, 1088, not 1072 or 1080...
			SCREEN_Y_RES=1448
			EIPS_X_RES=16
			EIPS_Y_RES=24		# Manually measured, should be accurate.
		;;
		"24" | "1B" | "1D" | "1F" | "1C" | "20" | "D4" | "5A" | "D5" | "D6" | "D7" | "D8" | "F2" | "17" | "60" | "F4" | "F9" | "62" | "61" | "5F" )
			# PaperWhite...
			SCREEN_X_RES=768	# NOTE: Yes, 768, not 758...
			SCREEN_Y_RES=1024
			EIPS_X_RES=16
			EIPS_Y_RES=24		# Manually measured, should be accurate.
		;;
		"C6" | "DD" )
			# KT2...
			SCREEN_X_RES=608
			SCREEN_Y_RES=800
			EIPS_X_RES=16
			EIPS_Y_RES=24
		;;
		"0F" | "11" | "10" | "12" )
			# Touch
			SCREEN_X_RES=600	# _v_width @ upstart/functions
			SCREEN_Y_RES=800	# _v_height @ upstart/functions
			EIPS_X_RES=12		# from f_puts @ upstart/functions
			EIPS_Y_RES=20		# from f_puts @ upstart/functions
		;;
		* )
			# Handle legacy devices...
			if [ -f "/etc/rc.d/functions" ] && grep -q "EIPS" "/etc/rc.d/functions" ; then
				. /etc/rc.d/functions
			else
				# Fallback... We shouldn't ever hit that.
				SCREEN_X_RES=600
				SCREEN_Y_RES=800
				EIPS_X_RES=12
				EIPS_Y_RES=20
			fi
		;;
	esac
else
	# Try the new device ID scheme...
	kmodel="$(cut -c4-6 /proc/usid)"
	case "${kmodel}" in
		"0G1" | "0G2" | "0G4" | "0G5" | "0G6" | "0G7" | "0KB" | "0KC" | "0KD" | "0KE" | "0KF" | "0KG" | "0LK" | "0LL" )
			# PW3...
			SCREEN_X_RES=1088
			SCREEN_Y_RES=1448
			EIPS_X_RES=16
			EIPS_Y_RES=24
		;;
		"0GC" | "0GD" | "0GR" | "0GS" | "0GT" | "0GU" )
			# Oasis...
			SCREEN_X_RES=1088
			SCREEN_Y_RES=1448
			EIPS_X_RES=16
			EIPS_Y_RES=24
		;;
		"0DU" | "0K9" | "0KA" )
			# KT3...
			SCREEN_X_RES=608
			SCREEN_Y_RES=800
			EIPS_X_RES=16
			EIPS_Y_RES=24
		;;
		"0LM" | "0LN" | "0LP" | "0LQ" | "0P1" | "0P2" | "0P6" | "0P7" | "0P8" | "0S1" | "0S2" | "0S3" | "0S4" | "0S7" | "0SA" )
			# Oasis 2...
			SCREEN_X_RES=1280
			SCREEN_Y_RES=1680
			EIPS_X_RES=16
			EIPS_Y_RES=24
		;;
		"0PP" | "0T1" | "0T2" | "0T3" | "0T4" | "0T5" | "0T6" | "0T7" | "0TJ" | "0TK" | "0TL" | "0TM" | "0TN" | "102" | "103" | "16Q" | "16R" | "16S" | "16T" | "16U" | "16V" )
			# PW4...
			SCREEN_X_RES=1088
			SCREEN_Y_RES=1448
			EIPS_X_RES=16
			EIPS_Y_RES=24
		;;
		"10L" | "0WF" | "0WG" | "0WH" | "0WJ" | "0VB" )
			# KT4...
			SCREEN_X_RES=608
			SCREEN_Y_RES=800
			EIPS_X_RES=16
			EIPS_Y_RES=24
		;;
		"11L" | "0WQ" | "0WP" | "0WN" | "0WM" | "0WL" )
			# Oasis 3...
			SCREEN_X_RES=1280
			SCREEN_Y_RES=1680
			EIPS_X_RES=16
			EIPS_Y_RES=24
		;;
		"1LG" | "1Q0" | "1PX" | "1VD" | "219" | "21A" | "2BH" | "2BJ" | "2DK" )
			# PaperWhite 5...
			SCREEN_X_RES=1236
			SCREEN_Y_RES=1648
			EIPS_X_RES=16
			EIPS_Y_RES=24
		;;
		"22D" | "25T" | "23A" | "2AQ" | "2AP" | "1XH" | "22C" )
			# Kindle Scribe (FIXME: Resolution TBD)...
			SCREEN_X_RES=1848
			SCREEN_Y_RES=2464
			EIPS_X_RES=16
			EIPS_Y_RES=24
		;;
		* )
			# Fallback... We shouldn't ever hit that.
			SCREEN_X_RES=600
			SCREEN_Y_RES=800
			EIPS_X_RES=12
			EIPS_Y_RES=20
		;;
	esac
fi
# And now we can do the maths ;)
EIPS_MAXCHARS="$((${SCREEN_X_RES} / ${EIPS_X_RES}))"
EIPS_MAXLINES="$((${SCREEN_Y_RES} / ${EIPS_Y_RES}))"

# From libotautils[5], adapted from libkh[5]
# Default to something that won't horribly blow up...
FBINK_BIN="true"
for my_hackdir in linkss linkfonts libkh usbnet ; do
	my_fbink="/mnt/us/${my_hackdir}/bin/fbink"
	if [ -x "${my_fbink}" ] ; then
		FBINK_BIN="${my_fbink}"
		# Got it!
		break
	fi
done

has_fbink()
{
	# Because the fallback is the "true" binary/shell built-in ;).
	if [ "${FBINK_BIN}" != "true" ] ; then
		# Got it!
		return 0
	fi

	# If we got this far, we don't have fbink installed
	return 1
}

do_fbink_print()
{
	# We need at least two args
	if [ $# -lt 2 ] ; then
		echo "not enough arguments passed to do_fbink_print ($# while we need at least 2)"
		return
	fi

	kh_eips_string="${1}"
	kh_eips_y_shift_up="${2}"

	# Unlike eips, we need at least a single space to even try to print something ;).
	if [ "${kh_eips_string}" == "" ] ; then
		kh_eips_string=" "
	fi

	# Check if we asked for a highlighted message...
	if [ "${3}" == "h" ] ; then
		fbink_extra_args="h"
	else
		fbink_extra_args=""
	fi

	# NOTE: FBInk will handle the padding. FBInk's default font is square, not tall like eips,
	#       so we compensate by tweaking the baseline ;).
	${FBINK_BIN} -qpm${fbink_extra_args} -y $(( -4 - ${kh_eips_y_shift_up} )) "${kh_eips_string}"
}

do_eips_print()
{
	# We need at least two args
	if [ $# -lt 2 ] ; then
		echo "not enough arguments passed to do_eips_print ($# while we need at least 2)"
		return
	fi

	kh_eips_string="${1}"
	kh_eips_y_shift_up="${2}"

	# Get the real string length now
	kh_eips_strlen="${#kh_eips_string}"

	# Add the right amount of left & right padding, since we're centered, and eips doesn't trigger a full refresh,
	# so we'll have to padd our string with blank spaces to make sure two consecutive messages don't run into each other
	kh_padlen="$(((${EIPS_MAXCHARS} - ${kh_eips_strlen}) / 2))"

	# Left padding...
	while [ ${#kh_eips_string} -lt $((${kh_eips_strlen} + ${kh_padlen})) ] ; do
		kh_eips_string=" ${kh_eips_string}"
	done

	# Right padding (crop to the edge of the screen)
	while [ ${#kh_eips_string} -lt ${EIPS_MAXCHARS} ] ; do
		kh_eips_string="${kh_eips_string} "
	done

	# And finally, show our formatted message centered on the bottom of the screen (NOTE: Redirect to /dev/null to kill unavailable character & pixel not in range warning messages)
	eips 0 $((${EIPS_MAXLINES} - 2 - ${kh_eips_y_shift_up})) "${kh_eips_string}" >/dev/null
}

eips_print_bottom_centered()
{
	# We need at least two args
	if [ $# -lt 2 ] ; then
		echo "not enough arguments passed to eips_print_bottom_centered ($# while we need at least 2)"
		return
	fi

	kh_eips_string="${1}"
	kh_eips_y_shift_up="${2}"

	# Sleep a tiny bit to workaround the logic in the 'new' (K4+) eInk controllers that tries to bundle updates
	if [ "${EIPS_SLEEP}" == "true" ] ; then
		usleep 150000	# 150ms
	fi

	# Can we use FBInk?
	if has_fbink ; then
		do_fbink_print "${kh_eips_string}" ${kh_eips_y_shift_up}
	else
		do_eips_print "${kh_eips_string}" ${kh_eips_y_shift_up}
	fi
}

# Print detailed infos on the screen
print_detailed_status()
{
	# Sleep for a bit, FBInk is likely to go faster than KUAL ;).
	sleep 1
	# Do eeeet!

	JAVA_VERSION_FULL=$(/mnt/us/extensions/openjdk-6-jre/jre/bin/java -version 2>&1)
	eips_print_bottom_centered "$JAVA_VERSION_FULL" 5

	#JAVA_VERSION=$(/mnt/us/extensions/openjdk-6-jre/jre/bin/java -version 2>&1 | head -1)
	#eips_print_bottom_centered "$JAVA_VERSION" 1
}

# Main
case "${1}" in
	"print_detailed_status" )
		${1}
	;;
	* )
		eips_print_bottom_centered "invalid action (${1})" 1
	;;
esac

return 0


