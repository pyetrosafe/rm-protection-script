# Tests

## Successfully blocked
```bash
[common_user@DESKTOP-PC ~]$ rm -rf /
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.
```

```bash
[common_user@DESKTOP-PC ~]$ rm -rf /home
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.
```

```bash
[common_user@DESKTOP-PC ~]$ rm -rf /etc
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.
```

```bash
[common_user@DESKTOP-PC ~]$ /usr/bin/rm -rf /
rm: it is dangerous to operate recursively on '/'
rm: use --no-preserve-root to override this failsafe
```

## Not blocked, but the user cannot remove it due to lack of permission.
```bash
[common_user@DESKTOP-PC ~]$ /usr/bin/rm -rf /*
rm: cannot remove '/bin': Permission denied
rm: cannot remove '/boot': Permission denied
rm: cannot remove '/dev/vcsa5': Permission denied
rm: cannot remove '/dev/vcsu5': Permission denied
rm: cannot remove '/dev/vcs5': Permission denied
...
^C
# Execution cancelled by user, but the system is still at risk if the command was allowed to run.
```

## Successfully blocked with sudo
```bash
[common_user@DESKTOP-PC ~]$ sudo rm -rf /var
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.
```

```bash
[common_user@DESKTOP-PC ~]$ sudo /usr/bin/rm -rf /var
Sorry, user custom_user is not allowed to execute '/usr/bin/rm -rf /var' as root on DESKTOP-PC.
```

```bash
[common_user@DESKTOP-PC ~]$ sudo /usr/bin/rm -rf /*
Sorry, user custom_user is not allowed to execute '/usr/bin/rm -rf /bin /boot /dev /etc /home /init /lib /lib64 /lost+found /mnt /opt /proc /root /run /sbin /srv /sys /tmp /usr /var' as root on DESKTOP-PC.
```

```bash
[root@DESKTOP-PC common_user]# rm -rf /var
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.
```

## WARNING: Running as root with `\rm -rf`or `/usr/bin/rm -rf`

### will execute the command and remove files without any checks, so be extremely cautious when using these commands as root.
```bash
[root@DESKTOP-PC common_user]# \rm -rf /
Removed by root, but the system is still at risk if the command was allowed to run.

[root@DESKTOP-PC common_user]# /usr/bin/rm -rf /
Removed by root, but the system is still at risk if the command was allowed to run.
```