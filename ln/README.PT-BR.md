# Blast Shield Linux (Safe RM Core) 🛡️

> **Um Subsistema de Blindagem Anti-Destruição para Ambientes Linux e WSL**

O Blast Shield Linux é um utilitário de endurecimento (*hardening*) de ambiente projetado para interceptar, analisar e encerrar sequências de exclusão catastróficas (`rm -rf`) direcionadas às estruturas centrais do sistema operacional. Ao combinar a validação determinística no nível do shell com listas de controle de acesso (ACLs) rígidas por meio do motor do `sudoers`, ele cria uma sandbox incontornável contra a liquidação acidental do sistema.

---

## 📋 Visão Geral Arquitetônica

Na administração moderna do Linux e em pipelines de DevOps, uma única variável não citada, um espaço em branco mal colocado ou um toque de tecla fadigado à meia-noite podem desencadear a destruição de todo o sistema. Embora o utilitário nativo GNU `rm` inclua uma trava de segurança básica `--preserve-root`, ele é fundamentalmente cego para a expansão de shell (como `/*`), symlinks de diretório e execuções absolutas do binário (`/usr/bin/rm`).

Este projeto aborda a segurança do sistema não como uma simples mudança cosmética do shell, mas como uma **restrição de privilégios em múltiplas camadas**. Ele garante que, mesmo se um administrador ordenar explicitamente que o sistema se destrua, o ambiente operacional derruba o token de execução antes que uma chamada de sistema (syscall) destrutiva do kernel possa ocorrer.

---

## 🔒 O Que Ele Protege (O Sistema Imune)

A lógica central do guardião converte os caminhos em strings absolutas canônicas usando `realpath -m` e inspeciona o payload de execução. Se um comando recursivo corresponder a qualquer um dos seguintes blocos críticos de namespace, a execução será abortada à força:

*   **` / ` (O Sistema de Arquivos Raiz)**: Previne a limpeza total da máquina.
*   **`/bin`, `/sbin`, `/usr/bin`**: Protege os binários do sistema e utilitários centrais.
*   **`/boot`**: Protege as imagens do kernel Linux e as configurações do bootloader.
*   **`/etc`**: Guarda as configurações locais do host, hashes de senha e montagens do sistema.
*   **`/home`, `/root`**: Protege os espaços persistentes dos usuários e chaves criptográficas administrativas.
*   **`/lib`, `/lib64`, `/usr/lib`**: Isola as bibliotecas compartilhadas do sistema necessárias para a execução em runtime.
*   **`/var`**: Protege os logs do sistema, bancos de dados e estados operacionais contínuos.
*   **Sistemas Virtuais (`/proc`, `/sys`, `/dev`, `/run`)**: Evita alterações corruptivas de estado dentro das interfaces de memória virtual do kernel.

---

## ✅ Vantagens do Sistema

*   **Avaliação Determinística de Realpath**: Resolve barras duplas (`///`), pontos (`.`) e caminhos relativos antes de tomar uma decisão de segurança.
*   **Cascateamento no Ambiente Sudo**: Utilizando o padrão de design `alias sudo='sudo '`, o sistema força comandos com privilégios elevados a carregar os aliases de proteção do usuário.
*   **Fronteira Estrutural Endurecida**: Move o script de validação de configurações instáveis do usuário (`~/.bashrc`) para espaços de binários físicos do sistema (`/usr/local/bin/`), tornando-o imutável para contas não-root.
*   **Overhead Zero na Infraestrutura**: Escrito em sintaxe Bash POSIX enxuta e de baixo nível. A validação leva `<1ms`, introduzindo zero atraso operacional nos fluxos de trabalho diários.

---

## ⚠️ Fronteiras de Segurança e Limitações Conhecidas

Garantir a segurança de um sistema exige total transparência sobre as fronteiras do seu modelo de defesa. Os desenvolvedores que implantam este script devem estar cientes dos seguintes comportamentos:

### 1. A Fronteira do Usuário Local (Contexto Sem Sudo)
Se um usuário sem privilégios usar um mecanismo de escape como `\rm -rf /` ou mirar explicitamente no caminho do binário `/usr/bin/rm -rf /`, o alias do script será contornado.
*   *Realidade de Segurança:* Esta é uma limitação de design dos aliases do Bash. No entanto, como o usuário não possui direitos de `sudo`, a segurança nativa do sistema de arquivos Linux (DAC) abortará o comando com erro de `Permissão Negada` para 99% dos arquivos do sistema.

### 2. Nós de Rede e Montagens Não Listados
Caminhos de armazenamento montados fora da hierarquia padrão FHS do Linux (como compartilhamentos de rede personalizados em `/mnt`, aplicativos autônomos em `/opt` ou diretórios de entrega contínua em `/srv`) não estão incluídos na matriz blindada nativa. Os administradores do sistema devem anexar manualmente esses pontos de montagem personalizados à lógica do script `/usr/local/bin/rm_safe_check`.

### 3. Scripts de Automação Não-Interativos
Aliases são projetados para shells interativos humanos. Scripts de automação em segundo plano, cronjobs ou aplicações legadas que executam códigos de binários brutos ignorarão o wrapper do alias. Para uma cobertura absoluta em nível corporativo, esta ferramenta deve ser combinada com snapshots proativos do sistema.

---

## 🧪 Métricas de Teste em Produção

A matriz de proteção multicamadas foi validada através de vetores de teste estritos:

### Cenários Bloqueados via Interceptação de Shell Interativo
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

### Bloqueado como usuário Root
```bash
[root@desktop common_user]# rm -rf /var
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.

[root@desktop common_user]# rm -rf /
[BLOCKED] High-risk operation blocked!
Attempt to delete the root or exclusive system directories.
```

### Cenários Bloqueados via Endurecimento de Políticas do Sudoers
```bash
[common_user@desktop ~]$ sudo /usr/bin/rm -rf /var
Sorry, user pyetro is not allowed to execute '/usr/bin/rm -rf /var' as root on Hostname.

[common_user@desktop ~]$ sudo /usr/bin/rm -rf /*
Sorry, user pyetro is not allowed to execute '/usr/bin/rm -rf /bin /boot ...' as root on Hostname.
```

### Operações Permitidas Não-Destrutivas
```bash
[common_user@desktop ~]$ rm -f application.log           # Permitido (Não-recursivo)
[common_user@desktop ~]$ rm -rf ~/Workspace/git_repo/*   # Permitido (Workspace Seguro do Usuário)
```

### ⚠️ Cenários Não Cobertos como Usuário Root (`\rm -rf` && `/usr/bin/rm -rf`)
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

## 🚀 Instruções de Implantação

### Injetar o Subsistema de Segurança
*Execute o bloco de payload:*

```bash
# 1. Escreve o Validador Binário de Proteção no Disco
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
    # Como bloqueamos o /usr/bin/rm no sudo, o root usará o comando nativo diretamente do PATH interno
    command rm --preserve-root "$@"
fi
EOF

# 2. Força Privilégios de Execução
sudo chmod +x /usr/local/bin/rm_safe_check

# 3. Aplica os Ganchos Globais de Alias no Shell
sudo tee -a /etc/bash.bashrc > /dev/null << 'EOF'
alias sudo='sudo '
alias rm='/usr/local/bin/rm_safe_check'
EOF

# 4. Vincula a Restrição de Acesso ao Binário do Sistema
sudo tee /etc/sudoers.d/wheel > /dev/null << 'EOF'
%wheel ALL=(ALL) ALL
%wheel ALL=(ALL) !/usr/bin/rm *
EOF

# 5. Reinicie o Terminal para Aplicar as Configurações
exit
```

---

### 💻 Ambiente de Teste e Provisionamento Base

Toda a estrutura foi rigorosamente validada em uma instância do WSL (Subsistema Windows para Linux) executando **Arch Linux**, compilado através do projeto de código aberto [ArchWSL Project (Release v26.4.2.0)](https://github.com/yuk7/ArchWSL/releases/tag/26.4.2.0).

Para reproduzir a matriz de testes exata, a distribuição foi inicializada seguindo as seguintes sequências básicas:

**1. Desative a montagem automática de unidades do Windows por motivos de segurança.**
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

**2. Configuração de Root (Inicialização da Distribuição)**
```bash
# Provisionar a estrutura de acesso administrativo e criar a conta de operador segura básica
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
useradd -m -G wheel -s /bin/bash common_user
passwd common_user
exit
```

**3. Roteamento de Destino do Host Windows WSL**
```powershell
# Configure os limites de usuário de tempo de execução padrão a partir do seu terminal Windows PowerShell/CMD
PS C:\Users\CommonUser> wsl --manage Arch --set-default-user common_user
```

**4. Execução de Reforço de Segurança**
Assim que o terminal inicializar novamente na instância do espaço de trabalho `common_user`, execute o bloco de script de injeção do escudo principal.

---

## 🤝 Contribuindo para Outros Sistemas

Este projeto foi inicialmente desenvolvido para **Arch Linux**, mas sua lógica pode ser facilmente adaptada para outras distribuições!

### Implementação em Outras Distros

Para adicionar suporte a Ubuntu, Debian, Fedora, Alpine ou outras distribuições, necessitamos:

- **Testar compatibilidade** do script na distro alvo
- **Adaptar caminhos** se necessário:
   - Alguns sistemas podem usar `/etc/profile.d/` em vez de `/etc/bash.bashrc`
   - Caminhos de sudoers podem variar
- **Criar branches específicos** ou flags de configuração
- **Documentar** peculiaridades e diferenças

### Como Contribuir

- **Teste em sua distro**: Execute o script e reporte sucessos/falhas
- **Envie PRs**: Com adaptações para novos sistemas
- **Abra issues**: Documentando problemas de compatibilidade
- **Melhore a segurança**: Sugira novas camadas de proteção
- **Traduções**: Localize mensagens e documentação

**Sua contribuição ajuda a proteger milhares de administradores de sistemas!**

---

## 📝 Licença
Distribuído sob propósitos educacionais e de defesa de infraestrutura. Use com responsabilidade.

## 🌎 Outros idiomas
- 🇺🇸 [English](../README.md)