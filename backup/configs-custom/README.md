# Custom Configs

This directory provides a simple way to customize your config backups without modifying the shell script. Using this approach, you can pull the latest code without having to merge your custom file/directory lists. Additionally, you can have different config lists based on the type of system or the specific host being backed up.

Create a `host-all.txt` file to provide a list of files/directories that should be backed up on all hosts. An example `hosts-all.txt` file might contain this:

```
/root/bin/
/usr/home/*/bin/
/usr/local/ossec-hids/etc/
/usr/local/ossec-hids/rules/
```

To provide a list of files/directories to back up for a specific host, create a file named `host-<hostname>.txt`.  For example, the custom list for a system named **Beastie** would be named `host-Beastie.txt` (case sensitive, so execute `hostname` to check the proper case).

To include a list of files/directories across a type or class of system, create a file named `type-<type>.txt` and provide the type on the command line when backing up. You can create any types that you want. For example, to back up a consistent set of config files on all desktop systems, create the list in `type-desktop.txt` and use `sudo backup/configs -t desktop` to perform the backup.

The lists that are included in a given backup are:

* The default config files defined in the [backup/configs](../configs) script.
* If `-t <mytype>` is specified, the files listed in `type-<mytype>.txt`.
* The files listed in `host-all.txt`.
* The files listed in `host-<hostname>.txt`.

The `configs-custom/*.txt` files are excluded from git to prevent conflicts, but they are included in all backups to preserve your custom lists.
