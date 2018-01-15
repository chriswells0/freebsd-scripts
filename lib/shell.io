#!/bin/sh

:<<DOCUMENTATION

	Description:	Defines functions commonly used for file input/output.
	Author:			Chris Wells (https://chriswells.io)

DOCUMENTATION


################################################################################
# Utility Functions
################################################################################

# Parameters:
#	$1 (optional) = number of hex characters to return
#		Default is 8 when not provided.
# Returns:
#	random hex string of the requested length
# shellcheck disable=SC2120
generateHexString() {
	if [ $# -eq 0 ]; then
		LENGTH=4
	else
		LENGTH=$(($1 / 2))
	fi
	hexdump -n $LENGTH -v -e '/1 "%02X"' /dev/urandom
}

# Parameters:
#	$1 (optional) = file for which a temp file needs to be created
# Returns:
#	string that can be used as the name of a temp file
# shellcheck disable=SC2119
getTempFileName() {
	echo "$1.$(generateHexString).tmp"
}

# Parameters:
#	$1 = the name of the jail to run the script inside
#	$2 = the code to execute inside the jail
runAsScriptInJail() {
	TEMP_SCRIPT="$(getTempFileName 'temp').sh"
	createOrReplaceFile "/usr/jails/$1/tmp/$TEMP_SCRIPT" "#!/bin/sh
$2
exit 0
"
	chmod +x "/usr/jails/$1/tmp/$TEMP_SCRIPT"
	jexec "$1" "/tmp/$TEMP_SCRIPT"
	# Delete the script since it's no longer needed. Done here instead of
	# inside the script because the script could exit early. -- cwells
	rm "/usr/jails/$1/tmp/$TEMP_SCRIPT"
}

################################################################################
# Text Manipulation
################################################################################

# Parameters:
#	$1 = text containing special characters
# Returns:
#	input string with special characters escaped
escapeAwkSearchText() {
	echo "$1" | sed -e 's/[()]/\\\\&/g'
}

# Parameters:
#	$1 = sed expression
# Returns:
#	input string with special characters escaped
escapeForSed() {
	echo "$1" | sed -e 's/[\/&]/\\&/g'
}

# Parameters:
#	$1 = text containing newline characters
# Returns:
#	input string with newlines escaped
escapeNewlines() {
	echo "$1" | awk 1 ORS='\\n'
}

################################################################################
# File Manipulation
################################################################################

# Parameters:
#	$1 = file path
#	$2 = text to append to file
appendToFile() {
	echo "$2" >> "$1"
}

# Parameters:
#	$1 = file path
#	$2 = text to save as file
createOrReplaceFile() {
	echo "$2" > "$1"
}

# Parameters:
#	$1 = file path
#	$2 = line to delete
deleteLine() {
	TEMP_FILE=$(getTempFileName "$1")
	if awk -v line="$2" '$0 != line' "$1" > "$TEMP_FILE"; then
		cat "$TEMP_FILE" > "$1"
	fi
	if [ -f "$TEMP_FILE" ]; then
		rm "$TEMP_FILE"
	fi
}

# Parameters:
#	$1 = file path
#	$2 = line to insert after
#	$3 = text to insert into file
insertAfterLine() {
	TEMP_FILE=$(getTempFileName "$1")
	if awk -v line="$2" -v insert="$(escapeNewlines "$3")" '
		BEGIN {
			gsub(/\n$/, "", insert);
		}
		$0 == line {
			$0 = sprintf("%s\n%s", $0, insert);
		}
		1
	' "$1" > "$TEMP_FILE"; then
		cat "$TEMP_FILE" > "$1"
	fi
	if [ -f "$TEMP_FILE" ]; then
		rm "$TEMP_FILE"
	fi
}

# Parameters:
#	$1 = file path
#	$2 = line to insert before
#	$3 = text to insert into file
insertBeforeLine() {
	TEMP_FILE=$(getTempFileName "$1")
	if awk -v line="$2" -v insert="$(escapeNewlines "$3")" '
		BEGIN {
			gsub(/\n$/, "", insert);
		}
		$0 == line {
			$0 = sprintf("%s\n%s", insert, $0);
		}
		1
	' "$1" > "$TEMP_FILE"; then
		cat "$TEMP_FILE" > "$1"
	fi
	if [ -f "$TEMP_FILE" ]; then
		rm "$TEMP_FILE"
	fi
}

# Parameters:
#	$1 = file path
#	$2 = old line
#	$3 = new line
replaceLine() {
	TEMP_FILE=$(getTempFileName "$1")
	if awk -v line="$2" -v replace="$(escapeNewlines "$3")" '
		BEGIN {
			gsub(/\n$/, "", replace);
		}
		$0 == line {
			$0 = replace;
		}
		1
	' "$1" > "$TEMP_FILE"; then
		cat "$TEMP_FILE" > "$1"
	fi
	if [ -f "$TEMP_FILE" ]; then
		rm "$TEMP_FILE"
	fi
}

# Parameters:
#	$1 = file path
#	$2 = pattern to match
#	$3 = replacement text
replacePattern() {
	TEMP_FILE=$(getTempFileName "$1")
	if awk -v search="$2" -v replace="$(escapeNewlines "$3")" '
		BEGIN {
			gsub(/\n$/, "", replace);
		}
		1 {
			gsub(search, replace);
			print $0;
		}
	' "$1" > "$TEMP_FILE"; then
		cat "$TEMP_FILE" > "$1"
	fi
	if [ -f "$TEMP_FILE" ]; then
		rm "$TEMP_FILE"
	fi
}

# Parameters:
#	$1 = file path
#	$2 = old text
#	$3 = new text
replaceText() {
	TEMP_FILE=$(getTempFileName "$1")
	if awk -v search="$(escapeAwkSearchText "$2")" -v replace="$(escapeNewlines "$3")" '
		BEGIN {
			gsub(/\n$/, "", replace);
		}
		1 {
			gsub(search, replace);
			print $0;
		}
	' "$1" > "$TEMP_FILE"; then
		cat "$TEMP_FILE" > "$1"
	fi
	if [ -f "$TEMP_FILE" ]; then
		rm "$TEMP_FILE"
	fi
}

# Parameters:
#	$1 = file path
#	$2 = line to comment
#	$3 (optional) = string used to comment lines
commentLine() {
	if echo "$2" | grep -Eq '^\s*<.+>$'; then # This line is markup. -- cwells
		COMMENT=$(echo "$2" | sed -e 's/^\( *\)<\(.*\)>$/\1<!-- \2 -->/')
		replaceText "$1" "$2" "$COMMENT"
	else
		if [ -n "$3" ]; then
			COMMENT_MARKER="$3"
		else
			COMMENT_MARKER="#"
		fi
		replaceLine "$1" "$2" "$COMMENT_MARKER$2"
	fi
}

# Parameters:
#	$1 = file path
#	$2 = line to uncomment
#	$3 (optional) = string used to comment lines
uncommentLine() {
	if echo "$2" | grep -Eq '^\s*<.+>$'; then # This line is markup. -- cwells
		MARKUP=$(echo "$2" | sed -e 's/^\( *\)<!-- *\(.*\) -->$/\1<\2>/')
		replaceText "$1" "$2" "$MARKUP"
	else
		if [ -n "$3" ]; then
			COMMENT_MARKER="$3"
		else
			COMMENT_MARKER="#"
		fi
		SEARCH="$(echo "$2" | sed -e 's/[().*^$?&[]/\\\\&/g')"
		REPLACE="$(echo "$2" | sed -e 's/&/\\\\&/g')"
		replacePattern "$1" "^$COMMENT_MARKER+ *$SEARCH$" "$REPLACE"
	fi
}
