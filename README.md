# 🛡️ Simulação de Ataques de Força Bruta e Password Spraying com Medusa no Kali Linux

> **Projeto Prático do Bootcamp de Cibersegurança - DIO**  
> **Autor:** Alexandre  
> **Ferramentas:** Kali Linux, Medusa, Nmap, Smbclient, Metasploitable 2, DVWA, VirtualBox  

---

## 📌 Sumário Executivo

Este projeto documenta a implementação de um laboratório de testes de intrusão controlado para auditar a resiliência de autenticação em diferentes serviços corporativos (**FTP, Web HTTP e SMB**).

A simulação utilizou o **Kali Linux** como estação de auditoria e a máquina virtual deliberadamente vulnerável **Metasploitable 2** como alvo em um ambiente de rede isolado (*Host-Only*). O objetivo principal foi demonstrar a eficácia de técnicas de **Força Bruta (*Brute Force*)** e **Pulverização de Senhas (*Password Spraying*)** utilizando o **Medusa**, validar o acesso pós-exploração via `smbclient` e propor contra-medidas técnicas para mitigação e defesa em profundidade.

---

## 🏗️ Arquitetura do Laboratório

O ambiente foi virtualizado no Oracle VM VirtualBox utilizando o adaptador **Placa de rede exclusiva de hospedeiro (Host-Only)**, garantindo isolamento total da rede externa e evitando qualquer impacto em ativos reais:

```mermaid
flowchart LR
    subgraph HostOnly["Rede Host-Only (192.168.56.0/24)"]
        direction LR
        Kali["Atacante / Auditor<br><b>Kali Linux</b><br>IP: 192.168.56.101"]
        Metasploitable["Alvo Vulnerável<br><b>Metasploitable 2</b><br>IP: 192.168.56.102"]
        
        Kali -->|TCP 21 (FTP Brute Force)| Metasploitable
        Kali -->|TCP 80 (Web DVWA Brute Force)| Metasploitable
        Kali -->|TCP 445 (SMB Password Spraying)| Metasploitable
        Kali -->|smbclient Validação| Metasploitable
    end
```

---

## 🧰 Comparativo de Ferramentas de Auditoria de Senhas

Conforme abordado no treinamento, o ecossistema do Kali Linux oferece ferramentas especializadas para diferentes cenários:

| Ferramenta | Foco de Aplicação | Características Principais |
| :--- | :--- | :--- |
| **Medusa** | Auditoria rápida e paralela de protocolos de rede | Altamente modular, suporte a múltiplos threads, eficiente para varredura em massa de serviços como FTP, SSH, SMB e HTTP. |
| **THC-Hydra** | Quebra rápida de autenticação de rede | Muito popular, flexível, excelente suporte a formulários web complexos (POST/GET) e dezenas de protocolos. |
| **Ncrack** | Varredura de autenticação em alta velocidade | Desenvolvido pela equipe do Nmap; focado em escalabilidade para redes corporativas inteiras. |
| **John the Ripper** | Quebra offline de hashes de senhas | Especialista em decifrar hashes extraídos de bancos de dados, arquivos `/etc/shadow` e arquivos protegidos. |
| **Patator** | Multi-propósito modular em Python | Permite testes granulares com controle estrito de concorrência e tratamento de exceções. |
| **WPScan** | CMS WordPress | Especializado na enumeração de usuários, plugins e temas vulneráveis do WordPress, além de brute force na rota `wp-login.php`. |

---

## 🔬 Metodologia e Execução dos Ataques

### 1. Descoberta e Reconhecimento de Portas
No terminal do Kali Linux, foi confirmada a conectividade e identificadas as portas abertas no Metasploitable 2:

```bash
# Identificação das portas dos serviços alvos:
sudo nmap -sS -p 21,80,139,445 192.168.56.102
```

*Saída resumida do Nmap:*
```text
PORT    STATE SERVICE
21/tcp  open  ftp
80/tcp  open  http
139/tcp open  netbios-ssn
445/tcp open  netbios-ssn
MAC Address: 08:00:27:XX:XX:XX (Oracle VirtualBox)
```

---

### 2. Preparação de Listas de Dicionário (Wordlists)
Foram organizados os arquivos de teste na pasta `wordlists/`:
- `wordlists/users_common.txt`: Nomes de usuários padrão e administrativos (`admin`, `msfadmin`, `root`, `service`, `user`).
- `wordlists/passwords_common.txt`: Senhas fracas comuns (`password`, `123456`, `msfadmin`, `admin`, `letmein`).
- `wordlists/smb_users.txt`: Usuários corporativos enumerados na rede.

---

### 3. Cenário 1: Ataque de Força Bruta em Serviço FTP (Porta 21)
O Medusa foi executado utilizando o módulo `ftp` para testar as combinações de credenciais:

```bash
medusa -h 192.168.56.102 -U wordlists/users_common.txt -P wordlists/passwords_common.txt -M ftp -f -v 4
```

**Parâmetros explicados:**
- `-h 192.168.56.102`: Endereço IP do alvo vulnerável.
- `-U wordlists/users_common.txt`: Arquivo com a lista de usuários alvos.
- `-P wordlists/passwords_common.txt`: Arquivo com o dicionário de senhas.
- `-M ftp`: Módulo de autenticação para o protocolo FTP.
- `-f`: *(Fast Exit)* Interrompe o ataque assim que uma credencial válida for encontrada para um usuário.
- `-v 4`: Exibe o log detalhado de cada tentativa em tempo real.

**Resultado Obtido:**
```text
ACCOUNT FOUND: [ftp] Host: 192.168.56.102 User: msfadmin Password: msfadmin [SUCCESS]
```

---

### 4. Cenário 2: Ataque de Força Bruta em Formulário Web (DVWA)
O ambiente do DVWA (*Damn Vulnerable Web Application*), hospedado na porta 80 do Metasploitable 2, disponibiliza um módulo de teste de força bruta de autenticação web.

Utilizando o módulo `http` do Medusa contra a rota vulnerável:
```bash
medusa -h 192.168.56.102 -u admin -P wordlists/passwords_common.txt -M http -m DIR:/dvwa/vulnerabilities/brute/ -f
```
*Observação:* Para formulários web complexos que exigem cookies de sessão autenticados, o **THC-Hydra** ou o **Burp Suite Intruder** são ferramentas complementares ideais para parametrizar requisições POST com tratamento de CSRF tokens.

---

### 5. Cenário 3: Ataque em Cadeia - Enumeração SMB e Password Spraying

#### A. O Que é Password Spraying?
Diferente da força bruta convencional (que testa 1.000 senhas para 1 usuário, bloqueando a conta na política do Active Directory), o **Password Spraying** testa **1 senha fraca comum** contra **dezenas ou centenas de contas de usuários**.

```
[Força Bruta Tradicional]        [Password Spraying]
   1 Usuário (admin)               Muitos Usuários (user1, user2, user3...)
   ├── Senha 1                     ├── Senha: "Password123" -> user1 (Erro 1)
   ├── Senha 2                     ├── Senha: "Password123" -> user2 (Erro 1)
   ├── Senha 3                     └── Senha: "Password123" -> user3 (Sucesso!)
   └── [CONTA BLOQUEADA!]          (Evasão de Políticas de Lockout)
```

#### B. Execução do Password Spraying no SMB com Medusa:
```bash
# Testando a senha comum "password" contra a lista de contas enumeradas:
medusa -h 192.168.56.102 -U wordlists/smb_users.txt -p "password" -M smbnt -f -v 4
```

#### C. Validação e Acesso com `smbclient`:
Após o Medusa confirmar a existência da credencial válida (`msfadmin:msfadmin`), o acesso ao compartilhamento Samba foi validado:

```bash
# Listar compartilhamentos disponíveis usando a credencial descoberta:
smbclient -L //192.168.56.102/ -U msfadmin

# Conexão interativa no compartilhamento compartilhado:
smbclient //192.168.56.102/tmp -U msfadmin
```

---

## 🛡️ Medidas de Defesa e Prevenção Recomendadas

Para mitigar os riscos demonstrados neste projeto, recomendam-se as seguintes práticas de segurança corporativa:

1. **Adoção Obrigatória de MFA (Autenticação Multifator):**  
   Implementar MFA (TOTP, tokens de segurança FIDO2) em todos os acessos remotos e portais web. Mesmo que a senha seja descoberta via spray, o acesso permanece bloqueado.
2. **Políticas de Bloqueio Inteligentes e Atraso Progressivo (*Backoff*):**  
   Em vez de bloqueios rígidos imediatos (que podem causar negação de serviço), adotar atraso incremental no tempo de resposta a cada falha de autenticação.
3. **Mecanismos Anti-Automação (CAPTCHA / Rate Limiting):**  
   Aplicar limitação de requisições por IP na camada do servidor web (Nginx/Apache) ou WAF (ex: Cloudflare), ativando desafios CAPTCHA após tentativas recorrentes.
4. **Monitoramento e Detecção de Password Spraying no SIEM:**  
   Configurar alertas no SIEM para múltiplos eventos de falha de login (Event ID 4625 no Windows) vindos de um mesmo endereço IP direcionados a contas de usuários distintas em um intervalo curto de tempo.
5. **Hardening de Protocolos:**  
   Desativar serviços legados como SMBv1 e FTP em texto claro, migrando para SFTP/SSH e desabilitando sessões anônimas (*Null Sessions*).

---

## 📁 Estrutura do Repositório

```text
├── README.md                  # Documentação completa do projeto
├── wordlists/                 # Listas de palavras para testes controlados
│   ├── users_common.txt       # Dicionário de usuários comuns
│   ├── passwords_common.txt   # Dicionário de senhas fracas comuns
│   └── smb_users.txt          # Usuários corporativos para simulação de spray
├── scripts/                   # Automação das rotinas de auditoria
│   ├── run_ftp_audit.sh       # Script de teste em FTP
│   └── run_smb_spray.sh       # Script de password spraying em SMB
├── docs/                      # Análises e relatórios complementares
│   └── relatorio-mitigacao.md # Recomendações técnicas detalhadas de defesa
└── images/                    # Capturas de tela e evidências do laboratório
    └── README.md              # Relação de capturas de tela sugeridas
```

---

## 📚 Referências

- [Documentação Oficial do Medusa](http://www.foofus.net/jmk/medusa/medusa.html)
- [Kali Linux Documentation](https://www.kali.org/docs/)
- [NIST SP 800-63B - Digital Identity Guidelines: Authentication and Lifecycle Management](https://pages.nist.gov/800-63-3/sp800-63b.html)
- [Damn Vulnerable Web Application (DVWA)](http://www.dvwa.co.uk/)
- [OWASP Password Spraying Prevention](https://owasp.org/)
