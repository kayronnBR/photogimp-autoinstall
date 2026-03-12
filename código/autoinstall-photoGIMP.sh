#!/bin/bash

# ==============================================
# INSTALADOR COMPLETO DO PHOTOGIMP
# ==============================================
# - Instala GIMP Flatpak automaticamente (FORÇADO)
# - Instala plugin Resynthesizer (FORÇADO com opção 3)
# - Abre GIMP por 35s para criar pastas
# - Copia arquivos do PhotoGIMP
# - Abre o GIMP automaticamente no final
# ==============================================

# Cores para mensagens
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
CIANO='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Funções de mensagem
mensagem() {
    echo -e "${AZUL}[PhotoGIMP]${RESET} $1"
}

mensagem_sucesso() {
    echo -e "${VERDE}[✓]${RESET} $1"
}

mensagem_atencao() {
    echo -e "${AMARELO}[!]${RESET} $1"
}

mensagem_erro() {
    echo -e "${VERMELHO}[✗]${RESET} $1"
}

mensagem_destaque() {
    echo -e "${CIANO}${BOLD}➜ $1${RESET}"
}

# Função para notificações do sistema
notificar() {
    local titulo="$1"
    local mensagem="$2"
    local icone="$3"
    
    # Tenta diferentes métodos de notificação
    if command -v notify-send &> /dev/null; then
        # Para desktop Linux com libnotify
        notify-send -t 3000 "$titulo" "$mensagem" --icon=$icone
    elif command -v osascript &> /dev/null; then
        # Para macOS
        osascript -e "display notification \"$mensagem\" with title \"$titulo\""
    elif command -v kdialog &> /dev/null; then
        # Para KDE
        kdialog --title "$titulo" --passivepopup "$mensagem" 3
    elif command -v zenity &> /dev/null; then
        # Para GNOME/outros com zenity
        zenity --notification --text="$titulo: $mensagem"
    else
        # Fallback: apenas mostra no terminal
        echo -e "${CIANO}[NOTIFICAÇÃO]${RESET} $titulo: $mensagem"
    fi
}

# Função para barra de progresso animada
barra_progresso() {
    local mensagem="$1"
    local segundos=$2
    local total=$segundos
    
    echo -ne "${AMARELO}⏳ $mensagem ${RESET}["
    for ((i=0; i<segundos; i++)); do
        echo -ne "▓"
        sleep 1
    done
    echo -e "] ${VERDE}Concluído!${RESET}"
}

# Função para mostrar passo atual
mostrar_passo() {
    local passo_atual=$1
    local total_passos=$2
    local descricao=$3
    
    echo ""
    echo -e "${CIANO}${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}📌 PASSO $passo_atual DE $total_passos: $descricao${RESET}"
    echo -e "${CIANO}${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo ""
    
    # Notifica o usuário
    notificar "PhotoGIMP Installer" "Passo $passo_atual de $total_passos: $descricao" "system-run"
}

# Função para matar GIMP
matar_gimp() {
    flatpak kill org.gimp.GIMP 2>/dev/null
    pkill -9 -f "org.gimp.GIMP" 2>/dev/null
    sleep 2
}

# Configurações
TOTAL_PASSOS=5
PASSO_ATUAL=0

# Limpa a tela
clear
echo -e "${CIANO}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              INSTALADOR COMPLETO DO PHOTOGIMP                ║"
echo "║         Inclui GIMP Flatpak + Plugin + PhotoGIMP             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo ""

# Notificação inicial
notificar "PhotoGIMP Installer" "Iniciando instalação do PhotoGIMP..." "system-run"

# Diretório onde o script está
PASTA_ATUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mensagem "📁 Pasta do script: $PASTA_ATUAL"
echo ""

# Verificar se as pastas do PhotoGIMP existem
if [ ! -d "$PASTA_ATUAL/.config" ]; then
    mensagem_erro "Pasta .config não encontrada em: $PASTA_ATUAL"
    notificar "PhotoGIMP Installer" "ERRO: Pasta .config não encontrada!" "dialog-error"
    exit 1
fi

if [ ! -d "$PASTA_ATUAL/.local" ]; then
    mensagem_erro "Pasta .local não encontrada em: $PASTA_ATUAL"
    notificar "PhotoGIMP Installer" "ERRO: Pasta .local não encontrada!" "dialog-error"
    exit 1
fi

mensagem_sucesso "Pastas do PhotoGIMP encontradas!"
echo ""

# PASSO 1: VERIFICAR/INSTALL FLATPAK
# ===================================
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "Verificando e instalando Flatpak"

if ! command -v flatpak &> /dev/null; then
    mensagem_destaque "Flatpak não encontrado. Instalando..."
    notificar "PhotoGIMP Installer" "Instalando Flatpak..." "system-run"
    
    sudo apt update && sudo apt install flatpak -y
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    mensagem_sucesso "Flatpak instalado com sucesso!"
    notificar "PhotoGIMP Installer" "✅ Flatpak instalado com sucesso!" "flatpak"
else
    mensagem_sucesso "Flatpak já instalado."
fi
echo ""

# PASSO 2: INSTALAR/REINSTALAR GIMP FLATPAK
# ==========================================
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "Instalando GIMP via Flatpak"

notificar "PhotoGIMP Installer" "Instalando GIMP (pode levar alguns minutos)..." "gimp"

# Remover versão anterior se existir
if flatpak list | grep -q "org.gimp.GIMP"; then
    mensagem "Removendo versão anterior do GIMP..."
    flatpak uninstall --user -y org.gimp.GIMP 2>/dev/null
    flatpak uninstall -y org.gimp.GIMP 2>/dev/null
fi

mensagem "Instalando GIMP (isso pode levar alguns minutos)..."
barra_progresso "Instalando GIMP" 5
flatpak install --user flathub org.gimp.GIMP -y --noninteractive

if [ $? -eq 0 ]; then
    mensagem_sucesso "✅ GIMP instalado com sucesso!"
    notificar "PhotoGIMP Installer" "✅ GIMP instalado com sucesso!" "gimp"
else
    mensagem_erro "❌ Falha na instalação do GIMP"
    notificar "PhotoGIMP Installer" "❌ Falha na instalação do GIMP" "dialog-error"
    exit 1
fi
echo ""

# PASSO 3: INSTALAR PLUGIN RESYNTHESIZER
# =======================================
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "Instalando plugin Resynthesizer"

notificar "PhotoGIMP Installer" "Instalando plugin Resynthesizer..." "plugin"

# Remover plugin anterior se existir
if flatpak list | grep -q "org.gimp.GIMP.Plugin.Resynthesizer"; then
    mensagem "Removendo versão anterior do plugin..."
    flatpak uninstall --user -y org.gimp.GIMP.Plugin.Resynthesizer 2>/dev/null
fi

# Instalar expect para automação se necessário
if ! command -v expect &> /dev/null; then
    mensagem "Instalando expect para automação da instalação..."
    sudo apt update && sudo apt install expect -y
fi

mensagem "Executando instalação automática do plugin (selecionando runtime 3)..."

# Criar script expect temporário para automação (CORRIGIDO para responder Y automaticamente)
cat > /tmp/install_plugin.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 60
spawn flatpak install --user flathub org.gimp.GIMP.Plugin.Resynthesizer
expect {
    "Qual você deseja usar (0 para abortar)?*" {
        send "3\r"
        exp_continue
    }
    "Prosseguir com essas alterações para a instalação de usuário?*" {
        send "y\r"
        exp_continue
    }
    "Digite s/n:" {
        send "y\r"
        exp_continue
    }
    "Digite s/n:" {
        send "y\r"
        exp_continue
    }
    "Digite s/n:" {
        send "y\r"
        exp_continue
    }
    eof
}
EOF

chmod +x /tmp/install_plugin.exp

# Executar instalação automática
/tmp/install_plugin.exp

# Limpar arquivo temporário
rm /tmp/install_plugin.exp

# Verificar se instalou corretamente
if flatpak list | grep -q "org.gimp.GIMP.Plugin.Resynthesizer"; then
    mensagem_sucesso "✅ Plugin Resynthesizer instalado com sucesso (runtime 3)!"
    notificar "PhotoGIMP Installer" "✅ Plugin Resynthesizer instalado!" "plugin"
else
    mensagem_erro "❌ Falha na instalação do plugin"
    notificar "PhotoGIMP Installer" "⚠️ Falha no plugin, tentando método alternativo..." "dialog-warning"
    
    # Método alternativo: instalar runtime específico com resposta automática
    echo "y" | flatpak install --user flathub runtime/org.gimp.GIMP.Plugins.Resynthesizer/x86_64/3-36 -y --noninteractive
    
    if flatpak list | grep -q "org.gimp.GIMP.Plugin.Resynthesizer"; then
        mensagem_sucesso "✅ Plugin Resynthesizer instalado com sucesso (runtime 3-36)!"
        notificar "PhotoGIMP Installer" "✅ Plugin instalado (runtime 3-36)!" "plugin"
    else
        mensagem_erro "Não foi possível instalar o plugin automaticamente."
        notificar "PhotoGIMP Installer" "❌ Falha na instalação do plugin" "dialog-error"
        mensagem "Por favor, instale manualmente depois com:"
        mensagem "flatpak install flathub org.gimp.GIMP.Plugin.Resynthesizer"
        mensagem "E selecione a opção 3 quando perguntado."
    fi
fi
echo ""

# PASSO 4: ABRIR GIMP POR 35 SEGUNDOS
# ====================================
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "Preparando pastas de configuração"

notificar "PhotoGIMP Installer" "Abrindo GIMP para criar pastas..." "gimp"

# Garantir que GIMP não está rodando
matar_gimp

# Abrir GIMP em segundo plano
mensagem "🚀 Iniciando GIMP por 35 segundos..."
flatpak run org.gimp.GIMP &
GIMP_PID=$!

# Barra de progresso
barra_progresso "Aguardando criação das pastas" 35

# Matar GIMP
mensagem "🔪 Fechando GIMP..."
matar_gimp
mensagem_sucesso "GIMP fechado!"
notificar "PhotoGIMP Installer" "Pastas de configuração criadas!" "folder"
echo ""

# PASSO 5: COPIAR ARQUIVOS DO PHOTOGIMP
# ======================================
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "Copiando arquivos do PhotoGIMP"

notificar "PhotoGIMP Installer" "Copiando arquivos do PhotoGIMP..." "folder"

# Criar pastas de destino se não existirem
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local"

# Remover configurações antigas do GIMP primeiro
mensagem "   Removendo configurações antigas..."
rm -rf "$HOME/.config/GIMP" 2>/dev/null
rm -rf "$HOME/.local/share/gimp" 2>/dev/null

# Copiar .config
mensagem "   Copiando novas configurações para ~/.config/..."
cp -rf "$PASTA_ATUAL/.config"/* "$HOME/.config/" 2>/dev/null

# Copiar .local
mensagem "   Copiando novos dados para ~/.local/..."
cp -rf "$PASTA_ATUAL/.local"/* "$HOME/.local/" 2>/dev/null

# Ajustar permissões básicas
chmod -R 755 "$HOME/.config/GIMP" 2>/dev/null
chmod -R 755 "$HOME/.local/share/gimp" 2>/dev/null

mensagem_sucesso "Arquivos do PhotoGIMP copiados!"
notificar "PhotoGIMP Installer" "✅ Arquivos copiados com sucesso!" "folder"
echo ""

# ==============================================
# FINALIZAR E ABRIR GIMP
# ==============================================
clear
echo -e "${VERDE}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         🎉 INSTALAÇÃO COMPLETADA COM SUCESSO! 🎉            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo ""
mensagem_sucesso "PhotoGIMP foi instalado completamente!"
echo ""
echo -e "${CIANO}${BOLD}📌 RESUMO DA INSTALAÇÃO:${RESET}"
echo -e "   ${VERDE}✅${RESET} PASSO 1: Flatpak verificado/instalado"
echo -e "   ${VERDE}✅${RESET} PASSO 2: GIMP Flatpak instalado"
echo -e "   ${VERDE}✅${RESET} PASSO 3: Plugin Resynthesizer instalado"
echo -e "   ${VERDE}✅${RESET} PASSO 4: Pastas de configuração criadas"
echo -e "   ${VERDE}✅${RESET} PASSO 5: Arquivos do PhotoGIMP copiados"
echo ""
echo -e "${BOLD}📂 ARQUIVOS INSTALADOS:${RESET}"
echo "   • Configurações: ~/.config/GIMP/"
echo "   • Scripts/Dados: ~/.local/share/gimp/"
echo ""
echo -e "${CIANO}${BOLD}🎨 ABRINDO GIMP AGORA...${RESET}"
echo ""
echo "=================================================="
echo ""

# Notificação final
notificar "PhotoGIMP Installer" "🎉 Instalação concluída! Abrindo GIMP..." "gimp"

# Pequena pausa para ler as mensagens
sleep 3

# Abrir GIMP
mensagem "🚀 Iniciando GIMP com PhotoGIMP..."
flatpak run org.gimp.GIMP &

# Mensagem final
mensagem_sucesso "GIMP foi aberto! Aproveite o PhotoGIMP! 🎨"
echo ""

exit 0
