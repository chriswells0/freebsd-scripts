# freebsd-scripts

A collection of shell scripts to perform common actions (mostly related to system administration) on FreeBSD.

Feedback and contributions are welcome!

## Scripts

[backup-apache](backup-apache) backs up Let's Encrypt certs (if present), Apache includes, and the www directory. If Apache is installed in a jail, you can provide the path to the jail to back up from there.

---

[backup-configs](backup-configs) backs up common config files that may have been modified on the system. Includes /etc and /usr/local/etc from the host as well as from inside all jails. Also backs up configs for OSSEC and DKIM, if present.

---

[portsfetch](portsfetch) can be used to switch to the current quarterly branch for FreeBSD ports and to update your local ports tree after switching. See [Using Quarterly Ports on FreeBSD](https://chriswells.io/blog/using-quarterly-ports-on-freebsd) for background information and usage instructions.

---

[update-host](update-host) performs a basic update sequence including `freebsd-update` on the host plus a vulnerability audit and upgrade of packages on the host and inside each jail.

## Libraries

Currently, the bulk of this project consists of the scripts in the [lib](lib) directory that provide functions for other scripts to use. I've made changes to make those libraries more flexible before sharing them, and I'll release additional scripts over time as I update them to incorporate those changes.

---

### shell.common

[lib/shell.common](lib/shell.common) defines functions frequently used in shell scripts.

#### General

* getScriptPath: Returns full path to the current script.
* importScript: Imports another script.
* pressEnterTo: Asks the user to press enter to perform an action.
* requireRootOrExit: Exits the script with an error message if the user is not root or using sudo.

#### Hashes (Associative Arrays / Dictionaries)

It includes functions for managing hashes (associative arrays / dictionaries), which are used by other functions in the file:

* hashContainsKey: Returns result code indicating whether the specified key exists in the hash.
* hashContainsValue: Returns result code indicating whether the specified value exists in the hash.
* hashGet: Returns value found for the specified key.
* hashPut: Adds an item to the hash.

#### Script Options

There are limited functions for reading script options such as `-p` and `-param value`, but not `-abc` where all 3 are different options:

* getOption: Returns the value provided for the specified option.
* optionIsEnabled: Returns result code indicating whether the specified option was passed to the script.
* parseScriptOptions: Parses the command line options for the other option functions.
* setOption: Sets an option. Used by parseScriptOptions, but available to scripts as well.

#### Note Management

Finally, a couple of functions that allow scripts to accumulate a list of notes to be shown to the user after the script completes:

* addNote: Adds a note such as a status message to a file.
* showNotes: Displays the contents of the notes file and its location to the user.

---

### shell.io

[lib/shell.io](lib/shell.io) defines functions commonly used for file input/output.

#### Utility Functions

* generateHexString: Returns a random hex string of the requested length (default 8).
* getTempFileName: Provides a string that can be used as the name of a temp file.
* runAsScriptInJail: Executes commands as a shell script inside the specified jail.

#### Text Manipulation

* escapeAwkSearchText: Returns input string with special characters escaped for awk.
* escapeForSed: Returns input string with special characters escaped for sed.
* escapeNewlines: Returns input string with newlines escaped.

#### File Manipulation

* appendToFile: Appends text to the end of the specified file.
* createOrReplaceFile: Creates or replaces the specified file with the provided contents.
* deleteLine: Deletes the provided line of text from the specified file.
* insertAfterLine: Inserts the provided text after the specified text.
* insertBeforeLine: Inserts the provided text before the specified text.
* replaceLine: Replaces the specified line of text with the provided text.
* replacePattern: Replaces the specified regular expression with the provided text.
* replaceText: Replaces the specified text with the provided text.
* commentLine: Comments a line by prefixing with # or a provided value.
* uncommentLine: Uncomments a line by removing # or a provided value.
