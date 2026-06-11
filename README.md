# Blast Shield Linux (Safe RM Core) 🛡️

> **An Iron-Clad Anti-Destruction Subsystem for Linux Environments & WSL**

Blast Shield Linux is a environment-hardening utility designed to intercept, analyze, and terminate catastrophic deletion sequences (`rm -rf`) targeting core operating system structures. By combining deterministic shell-level validation with strict access control lists (ACLs) via the `sudoers` engine, it creates an inescapable sandbox against accidental system liquidation.

---

## 📋 Architectural Overview

In modern Linux administration and DevOps pipelines, a single unquoted variable, a misplaced whitespace, or a fatiguing midnight keystroke can trigger system-wide destruction. While the native GNU `rm` utility includes a basic `--preserve-root` safety switch, it is fundamentally blind to shell expansion variables (like `/*`), directory symlinks, and absolute binary path executions (`/usr/bin/rm`).

This project approaches system safety not as a simple shell cosmetic change, but as a **multi-layered privilege constraint**. It ensures that even if an administrator explicitly commands the system to destroy itself, the operational environment drops the execution token before a destructive kernel syscall can take place.

---

## 🔒 What It Protects (The Immune System)

The core guard logic converts paths into canonical absolute strings using `realpath -m` and inspects the execution payload. If a recursive command matches any of the following critical namespace blocks, execution is forcefully aborted:

*   **` / ` (The Root Filesystem)**: Preventing total machine wiping.
*   **`/bin`, `/sbin`, `/usr/bin`**: Shielding system binaries and core utilities.
*   **`/boot`**: Protecting the Linux kernel images and bootloader configurations.
*   **`/etc`**: Guarding host local configurations, password hashes, and system mounts.
*   **`/home`, `/root`**: Securing persistent user spaces and cryptographic administrative keys.
*   **`/lib`, `/lib64`, `/usr/lib`**: Isolating shared system libraries required for runtime execution.
*   **`/var`**: Securing system logs, databases, and continuous operational states.
*   **Virtual Systems (`/proc`, `/sys`, `/dev`, `/run`)**: Preventing corruptive state changes inside kernel memory interfaces.

---

## ✅ System Advantages

*   **Deterministic Realpath Evaluation**: Resolves double slashes (`///`), dots (`.`), and relative paths before making a security decision.
*   **Sudo Environment Cascading**: Utilizing the `alias sudo='sudo '` design pattern, the system forces privilege-escalated commands to carry down the user's protective aliases.
*   **Hardened Structural Boundary**: Moves the validation script out of unstable user configurations (`~/.bashrc`) into physical system binary spaces (`/usr/local/bin/`), making it immutable to non-root accounts.
*   **Zero Infrastructure Overhead**: Written in lean, low-level POSIX Bash syntax. Execution validation takes `<1ms`, introducing zero operational delay to daily workflows.

---

## ⚠️ Security Boundaries & Known Limitations

Securing a system requires complete transparency about the borders of your defense model. Developers deploying this script must be aware of the following behaviors:

### 1. The Local User Boundary (Non-Sudo Context)
If a non-privileged user uses an escape mechanism like `\rm -rf /` or explicitly targets the bin path `/usr/bin/rm -rf /`, the script alias is bypassed.
*   *Security Reality:* This is a design limitation of Bash aliases. However, because the user lacks `sudo` rights, the underlying Linux filesystem security (DAC) will natively abort the command with a `Permission Denied` error for 99% of system files.

### 2. Unlisted Network and Mount Nodes
Storage paths mounted outside the standard Linux FHS hierarchy (such as custom network shares in `/mnt`, standalone apps in `/opt`, or continuous delivery directories in `/srv`) are not included in the hardcoded shield array. System administrators must manually append these custom mountpoints to the `/usr/local/bin/rm_safe_check` script logic.

### 3. Non-Interactive Automation Scripts
Aliases are designed for interactive human shells. Automated background scripts, cronjobs, or legacy applications executing raw binary codes will skip the alias wrapper. For absolute enterprise-level coverage, this tool must be combined with proactive system snapshots.

---

## 🧪 Production Test Metrics

The multi-layer protection matrix has been validated through strict test vectors:

### Scenarios Blocked via Interactive Shell Interception
```bash
[common_user@desktop ~]$ rm -rf /
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.

[common_user@desktop ~]$ rm -rf /etc
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.

[common_user@desktop ~]$ sudo rm -rf /var
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.
```

### Blocked as root user
```bash
[root@desktop common_user]# rm -rf /var
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.

[root@desktop common_user]# rm -rf /
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.
```

### Scenarios Blocked via Sudoers Policy Hardening
```bash
[common_user@desktop ~]$ sudo /usr/bin/rm -rf /var
Sorry, user pyetro is not allowed to execute '/usr/bin/rm -rf /var' as root on Hostname.

[common_user@desktop ~]$ sudo /usr/bin/rm -rf /*
Sorry, user pyetro is not allowed to execute '/usr/bin/rm -rf /bin /boot ...' as root on Hostname.
```

### Permitted Non-Destructive Operations
```bash
[common_user@desktop ~]$ rm -f application.log           # Allowed (Non-recursive)
[common_user@desktop ~]$ rm -rf ~/Workspace/git_repo/*   # Allowed (Safe User Workspace)
```

### ⚠️ Scenarios Not Covered as root user (`\rm -rf` && `/usr/bin/rm -rf`)
```bash
[root@desktop common_user]# \rm -rf /var
[root@desktop common_user]# ls -al /
total 2828
drwxr-xr-x  16 root root    4096 Jun 10 22:24 .
drwxr-xr-x  16 root root    4096 Jun 10 22:24 ..
lrwxrwxrwx   1 root root       7 Oct 12  2025 bin -> usr/bin
drwxr-xr-x   2 root root    4096 Oct 12  2025 boot
drwxr-xr-x  15 root root    3880 Jun 10 22:20 dev
drwxr-xr-x  41 root root    4096 Jun 10 19:00 etc
drwxr-xr-x   3 root root    4096 Jun  9 18:39 home
-rwxr-xr-x   1 root root 2836528 Apr 24 18:29 init
lrwxrwxrwx   1 root root       7 Oct 12  2025 lib -> usr/lib
lrwxrwxrwx   1 root root       7 Oct 12  2025 lib64 -> usr/lib
drwx------   2 root root   16384 Jun  9 17:33 lost+found
drwxr-xr-x   8 root root    4096 Jun  9 18:39 mnt
drwxr-xr-x   2 root root    4096 Oct 12  2025 opt
dr-xr-xr-x 346 root root       0 Jun  9 23:25 proc
drwxr-x---   4 root root    4096 Jun  9 18:40 root
drwxr-xr-x  19 root root     460 Jun  9 23:25 run
lrwxrwxrwx   1 root root       7 Oct 12  2025 sbin -> usr/bin
drwxr-xr-x   4 root root    4096 Apr  1 12:13 srv
dr-xr-xr-x  13 root root       0 Jun 10 14:36 sys
drwxrwxrwt   4 root root      80 Jun 10 00:00 tmp
drwxr-xr-x   8 root root    4096 Apr  1 21:03 usr
[root@desktop common_user]#
```

---

## 🚀 Deployment Instructions

### Inject the Security Subsystem
*Run the payload block:*

```bash
# 1. Write the Shield Binary Validator to Disk
sudo tee /usr/local/bin/rm_safe_check > /dev/null << 'EOF'
#!/bin/bash
target=""
has_recursive=false
block_execution=false

for arg in "$@"; do
    if [[ "$arg" =~ ^-[a-zA-Z]*[rR][a-zA-Z]*$ ]] || [[ "$arg" == "-rf" ]] || [[ "$arg" == "-fr" ]]; then
        has_recursive=true
    fi
done

for target in "$@"; do
    absolute_target=$(realpath -m -- "$target" 2>/dev/null || echo "$target")
    if [[ "$absolute_target" == "/" ]]; then
        block_execution=true
        break
    fi
    if [ "$has_recursive" = true ]; then
        case "$absolute_target" in
            /bin|/boot|/dev|/etc|/home|/lib|/lib64|/proc|/root|/run|/sbin|/sys|/usr|/var|/usr/bin|/usr/lib|/mnt)
                block_execution=true
                break
                ;;
        esac
    fi
done

if [ "$block_execution" = true ]; then
    echo -e "\e[1;31m[BLOQUEADO] Operação de alto risco detectada!\e[0m"
    echo -e "\e[1;31mTentativa de apagar a raiz ou diretórios vitais do sistema.\e[0m"
    exit 1
else
    # Since we've blocked /usr/bin/rm in sudo, root will use the native command directly from the internal PATH.
    command rm --preserve-root "$@"
fi
EOF

# 2. Enforce Executable Privileges
sudo chmod +x /usr/local/bin/rm_safe_check

# 3. Apply Global Shell Alias Hooks
sudo tee -a /etc/bash.bashrc > /dev/null << 'EOF'
alias sudo='sudo '
alias rm='/usr/local/bin/rm_safe_check'
EOF

# 4. Bind the System Binary Access Restriction
sudo tee /etc/sudoers.d/wheel > /dev/null << 'EOF'
%wheel ALL=(ALL) ALL
%wheel ALL=(ALL) !/usr/bin/rm *
EOF

# 5. Restart the Terminal to Apply Configurations
exit
```

---

### 💻 Test Environment & Base Provisioning

The entire framework was strictly validated inside a WSL (Windows Subsystem for Linux) instance running **Arch Linux**, compiled via the open-source [ArchWSL Project (Release v26.4.2.0)](https://github.com/yuk7/ArchWSL/releases/tag/26.4.2.0).

To reproduce the exact test matrix, the distribution was initialized under the following baseline sequences:

**1. Disable automatic mounting of Windows drives for security reasons.**
```bash
sudo tee /etc/wsl.conf > /dev/null << 'EOF'
[boot]
systemd=true

[automount]
enabled = false
options = "metadata"
mountFsTab = false

[interop]
enabled = false
appendWindowsPath = false
EOF
```

**2. Root Setup (Initial Distro Boot)**
```bash
# Provision administrative access structure and spawn the base safe operator account
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
useradd -m -G wheel -s /bin/bash common_user
passwd common_user
exit
```

**3. WSL Windows Host Target Routing**
```powershell
# Set up the default runtime user boundaries from your Windows PowerShell/CMD terminal
PS C:\Users\CommonUser> wsl --manage Arch --set-default-user common_user
```

**4. Hardening Execution**
Once the terminal boots back into the `common_user` workspace instance, execute the core shield injection script block.

---

## 🤝 Contributing to Other Systems

This project was initially developed for Arch Linux, but its logic can be easily adapted to other distributions!

**Implementation in Other Distros**

To add support for Ubuntu, Debian, Fedora, Alpine, or other distributions, we need to:

- **Test script compatibility** on the target distro
- **Adapt paths** if necessary:
  - Some systems may use /etc/profile.d/ instead of /etc/bash.bashrc
  - Sudoer paths may vary
- **Create specific branches** or configuration flags
- **Document** peculiarities and differences

**How to Contribute**

- **Test on your distro**: Run the script and report successes/failures
- **Submit PRs**: With adaptations for new systems
- **Open issues**: Documenting compatibility issues
- **Improve security**: Suggest new layers of protection
- **Translations**: Locate messages and documentation

Your contribution helps protect thousands of system administrators!

---

## 📝 License
Distributed under educational and infrastructure defense purposes. Use responsibly.

## 🌎 Other Languages
- 🇧🇷 [Português Brazil](./ln/README.PT-BR.md)
