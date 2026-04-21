#!/bin/bash

# ==============================================
# INSTALADOR PHOTOGIMP - VERSÃO REDUZIDA
# ==============================================
# - Removeu: Verificação de Flatpak/Flathub
# - Removeu: Instalação de Plugins (Resynthesizer)
# - Foco: Instalação do GIMP e cópia dos arquivos de configuração
# ==============================================

# Cores para mensagens
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
CIANO='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ID único para notificações
NOTIFY_ID=9999

# Funções de mensagem
mensagem() { echo -e "${AZUL}[PhotoGIMP]${RESET} $1"; }
mensagem_sucesso() { echo -e "${VERDE}[✓]${RESET} $1"; }
mensagem_atencao() { echo -e "${AMARELO}[!]${RESET} $1"; }
mensagem_erro() { echo -e "${VERMELHO}[✗]${RESET} $1"; }
mensagem_destaque() { echo -e "${CIANO}${BOLD}➜ $1${RESET}"; }

# Função para notificações
notificar() {
    if command -v notify-send &> /dev/null; then
        notify-send -t 3000 -r $NOTIFY_ID "$1" "$2" --icon=$3
    fi
}

# Função para barra de progresso
barra_progresso() {
    local mensagem="$1"
    local segundos=$2
    
    echo -ne "${AMARELO}⏳ $mensagem ${RESET}["
    for ((i=0; i<segundos; i++)); do
        echo -ne "▓"
        sleep 1
    done
    echo -e "] ${VERDE}Concluído!${RESET}"
}

# Função para mostrar passo atual
mostrar_passo() {
    echo ""
    echo -e "${CIANO}${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}📌 PASSO $1 DE $2: $3${RESET}"
    echo -e "${CIANO}${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo ""
    notificar "PhotoGIMP" "$3" "system-run"
}

# Função para matar GIMP
matar_gimp() {
    flatpak kill org.gimp.GIMP 2>/dev/null
    pkill -9 -f "org.gimp.GIMP" 2>/dev/null
    sleep 2
}

# FUNÇÃO: Instalar GIMP
instalar_gimp() {
    mensagem_destaque "VERIFICANDO GIMP..."
    
    if flatpak list | grep -q "org.gimp.GIMP"; then
        mensagem_sucesso "GIMP já está instalado."
    else
        mensagem "Instalando GIMP via Flathub..."
        barra_progresso "Instalando GIMP" 3
        
        if flatpak install --user flathub org.gimp.GIMP -y; then
            mensagem_sucesso "✅ GIMP instalado com sucesso!"
        else
            mensagem_erro "❌ Falha na instalação do GIMP."
            exit 1
        fi
    fi
}

# Configurações
TOTAL_PASSOS=2
PASSO_ATUAL=0

# Início
clear
echo -e "${CIANO}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         INSTALADOR PHOTOGIMP - VERSÃO OTIMIZADA              ║"
echo "║             Instalação do App + Configurações                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

notificar "PhotoGIMP" "🚀 Iniciando instalação..." "system-run"

# Diretório do script
PASTA_ATUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mensagem "📁 Pasta do script: $PASTA_ATUAL"

# Verificar pastas do PhotoGIMP
if [ ! -d "$PASTA_ATUAL/.config" ] || [ ! -d "$PASTA_ATUAL/.local" ]; then
    mensagem_erro "Arquivos de configuração (.config/.local) não encontrados na pasta atual!"
    exit 1
fi

# PASSO 1: Instalar GIMP
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "GIMP Flatpak"
instalar_gimp

# PASSO 2: Preparar e Copiar PhotoGIMP
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "Aplicando Configurações PhotoGIMP"

matar_gimp

mensagem "🚀 Abrindo GIMP brevemente para inicializar diretórios..."
flatpak run org.gimp.GIMP &
barra_progresso "Aguardando pastas do sistema" 15
matar_gimp

# Backup
if [ -d "$HOME/.config/GIMP" ]; then
    mensagem "Criando backup das configurações atuais em /tmp/photogimp-backup"
    mkdir -p /tmp/photogimp-backup
    cp -r "$HOME/.config/GIMP" /tmp/photogimp-backup/ 2>/dev/null
fi

# Limpeza e Cópia
mensagem "Removendo configurações antigas e aplicando PhotoGIMP..."
rm -rf "$HOME/.config/GIMP" 2>/dev/null
rm -rf "$HOME/.local/share/gimp" 2>/dev/null

cp -rf "$PASTA_ATUAL/.config"/* "$HOME/.config/" 2>/dev/null
cp -rf "$PASTA_ATUAL/.local"/* "$HOME/.local/" 2>/dev/null

chmod -R 755 "$HOME/.config/GIMP" 2>/dev/null
chmod -R 755 "$HOME/.local/share/gimp" 2>/dev/null

# FINALIZAR
clear
echo -e "${VERDE}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         🎉 INSTALAÇÃO COMPLETADA COM SUCESSO! 🎉            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${CIANO}${BOLD}📌 RESUMO:${RESET}"
echo -e "   ${VERDE}✅${RESET} GIMP Flatpak verificado"
echo -e "   ${VERDE}✅${RESET} Interface PhotoGIMP aplicada"
echo ""

notificar "PhotoGIMP" "🎉 Instalação concluída! Abrindo GIMP..." "gimp"
sleep 2

mensagem "🚀 Iniciando GIMP..."
flatpak run org.gimp.GIMP
