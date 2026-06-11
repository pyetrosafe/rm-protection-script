## Disable automatic mounting of Windows drives for security reasons
# sudo tee /etc/wsl.conf > /dev/null << 'EOF'
# [boot]
# systemd=true

# [automount]
# enabled = false
# options = "metadata"
# mountFsTab = false

# [interop]
# enabled = false
# appendWindowsPath = false
# EOF

## If using WSL 2 with Arch linux, consider creating a non-root user for daily use to avoid accidental damage to the system.
## You can do this by running the following commands in the terminal:
## Create the wheel group for admin permissions and then the user
# echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
# useradd -m -G wheel -s /bin/bash {username}
# passwd {username}
# exit
#
# In Powershell Change the default user for the distro and open the terminal again...
# > wsl --manage Archlinux --set-default-user {username}
#

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
    echo -e "\e[1;31m[BLOCKED] High-risk operation blocked!\e[0m"
    echo -e "\e[1;31mAttempt to delete the root or exclusive system directories.\e[0m"
    exit 1
else
    # Since we've blocked /usr/bin/rm in sudo, root will use the native command directly from the internal PATH
    command rm --preserve-root "$@"
fi
EOF

sudo chmod +x /usr/local/bin/rm_safe_check

sudo tee -a /etc/bash.bashrc > /dev/null << 'EOF'

# Força o sudo a reconhecer os aliases importados
alias sudo='sudo '

# Redireciona o comando rm para o nosso validador seguro
alias rm='/usr/local/bin/rm_safe_check'
EOF

sudo tee /etc/sudoers.d/wheel > /dev/null << 'EOF'
# Permite comandos gerais, mas proíbe o binário do rm com flags recursivas combinadas
%wheel ALL=(ALL) ALL
%wheel ALL=(ALL) !/usr/bin/rm *
EOF

exit