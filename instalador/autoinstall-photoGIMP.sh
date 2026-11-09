#!/bin/bash

# ==============================================
# PHOTOGIMP + G'MIC - INSTALAÇÃO AUTOMATIZADA
# ==============================================

PASTA_ATUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXIBIR_LOGS=false

# Função para enviar notificações no desktop
enviar_notificacao_desktop() {
    local titulo="$1"
    local mensagem="$2"
    
    if command -v notify-send &> /dev/null; then
        notify-send "$titulo" "$mensagem" --icon=gimp 2>/dev/null
    elif command -v gdbus &> /dev/null; then
        gdbus call --session \
            --dest org.freedesktop.Notifications \
            --object-path /org/freedesktop/Notifications \
            --method org.freedesktop.Notifications.Notify \
            "$titulo" 0 "gimp" "$titulo" "$mensagem" [] {} 5000 &>/dev/null
    elif command -v kdialog &> /dev/null; then
        kdialog --passivepopup "$mensagem" 5 --title "$titulo" 2>/dev/null
    fi
}

# Função de spinner para o modo silencioso
executar_com_spinner() {
    local mensagem="$1"
    local pid="$2"
    local spin='-\|/'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r    [%c] %s..." "${spin:$i:1}" "$mensagem"
        sleep 0.1
    done
    printf "\r    [✔] %s... Concluído!          \n" "$mensagem"
}

# Função de notificação e cabeçalho
enviar_notificacao() {
    local passo="$1"
    local mensagem="$2"
    
    if [ "$EXIBIR_LOGS" = false ]; then
        clear
        echo "--------------------------------------------------"
        echo "  🚀 PHOTOGIMP AUTOMATED INSTALLER"
        echo "--------------------------------------------------"
        echo "📌 [$passo] $mensagem"
        echo "--------------------------------------------------"
        echo ""
    else
        echo ""
        echo "=================================================="
        echo "📌 [$passo] $mensagem"
        echo "=================================================="
    fi
    
    enviar_notificacao_desktop "$passo" "$mensagem"
}

# ==============================================
# PERGUNTA DE MODO COM TIMEOUT DE 10 SEGUNDOS
# ==============================================
clear
echo "--------------------------------------------------"
echo "  🚀 PHOTOGIMP AUTOMATED INSTALLER"
echo "--------------------------------------------------"
echo "Escolha o modo de exibição:"
echo " 1) Instalação limpa (Silenciosa com animação) [Padrão]"
echo " 2) Mostrar logs detalhados dos comandos"
echo "--------------------------------------------------"
echo "Modo 1 selecionado automaticamente em 10 segundos..."
echo ""

read -t 10 -p "Opção [1-2] (Padrão: 1): " OPCAO

case "$OPCAO" in
    2)
        EXIBIR_LOGS=true
        echo -e "\n📋 Modo com logs detalhados ativado.\n"
        sleep 1
        ;;
    *)
        EXIBIR_LOGS=false
        echo -e "\n✨ Modo silencioso ativado.\n"
        sleep 1
        ;;
esac

# ==============================================
# INÍCIO DA INSTALAÇÃO
# ==============================================
enviar_notificacao "Passo 0/6" "Preparando o sistema e atualizando Flatpak..."

if [ "$EXIBIR_LOGS" = true ]; then
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y flatpak
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y flatpak
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm flatpak
    fi
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
else
    {
        if command -v apt &> /dev/null; then
            sudo apt update > /dev/null 2>&1
            sudo apt install -y flatpak > /dev/null 2>&1
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y flatpak > /dev/null 2>&1
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm flatpak > /dev/null 2>&1
        fi
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo > /dev/null 2>&1
    } &
    executar_com_spinner "Configurando repositórios e Flatpak" $!
fi

# 1. Instalar o GIMP via Flatpak
enviar_notificacao "Passo 1/6" "Instalando o GIMP via Flatpak..."
if [ "$EXIBIR_LOGS" = true ]; then
    flatpak install -y flathub org.gimp.GIMP
else
    flatpak install -y flathub org.gimp.GIMP > /dev/null 2>&1 &
    executar_com_spinner "A descarregar e instalar o GIMP" $!
fi

if [ $? -ne 0 ]; then
    enviar_notificacao "Erro" "Falha ao instalar o GIMP via Flatpak."
    exit 1
fi

# 2. Baixar e instalar o plugin G'MIC
enviar_notificacao "Passo 2/6" "Instalando o plugin G'MIC..."
if [ "$EXIBIR_LOGS" = true ]; then
    flatpak install -y flathub org.gimp.GIMP.Plugin.GMic//3
else
    flatpak install -y flathub org.gimp.GIMP.Plugin.GMic//3 > /dev/null 2>&1 &
    executar_com_spinner "A instalar o plugin G'MIC" $!
fi

# 3. Abrir o GIMP para gerar as pastas iniciais e fechar automaticamente
enviar_notificacao "Passo 3/6" "Abrindo o GIMP para gerar pastas padrão..."
if [ "$EXIBIR_LOGS" = true ]; then
    flatpak run org.gimp.GIMP &
else
    flatpak run org.gimp.GIMP > /dev/null 2>&1 &
fi
GIMP_PID=$!

TEMPO_ESPERA=0
LIMITE_TEMPO=30
spin='-\|/'
i=0

while kill -0 $GIMP_PID 2>/dev/null; do
    if journalctl --user -t flatpak --since "1 minute ago" 2>/dev/null | grep -q "GIMP.*Initialization"; then
        break
    fi
    
    if [ "$EXIBIR_LOGS" = false ]; then
        i=$(( (i+1) % 4 ))
        printf "\r    [%c] A iniciar o GIMP e a gerar perfis..." "${spin:$i:1}"
    fi
    
    sleep 1
    TEMPO_ESPERA=$((TEMPO_ESPERA + 1))
    
    if [ $TEMPO_ESPERA -ge $LIMITE_TEMPO ]; then
        break
    fi
done

if [ "$EXIBIR_LOGS" = false ]; then
    printf "\r    [✔] A iniciar o GIMP... Concluído!          \n"
fi

# Fechar o GIMP
flatpak kill org.gimp.GIMP > /dev/null 2>&1
pkill -9 -f "org.gimp.GIMP" > /dev/null 2>&1
wait $GIMP_PID 2>/dev/null

# 4. Rodar a cópia de arquivos do PhotoGIMP[cite: 1]
enviar_notificacao "Passo 4/6" "Aplicando a interface do PhotoGIMP..."
if [ ! -d "$PASTA_ATUAL/.config" ] || [ ! -d "$PASTA_ATUAL/.local" ]; then
    enviar_notificacao "Erro" "Pastas .config ou .local não encontradas em $PASTA_ATUAL"
    exit 1
fi

if [ "$EXIBIR_LOGS" = true ]; then
    mkdir -p /tmp/photogimp-backup
    cp -r "$HOME/.config/GIMP" /tmp/photogimp-backup/ 2>/dev/null
    rm -rf "$HOME/.config/GIMP" 2>/dev/null
    rm -rf "$HOME/.local/share/gimp" 2>/dev/null
    cp -rf "$PASTA_ATUAL/.config"/* "$HOME/.config/" 2>/dev/null
    cp -rf "$PASTA_ATUAL/.local"/* "$HOME/.local/" 2>/dev/null
    chmod -R 755 "$HOME/.config/GIMP" 2>/dev/null
    chmod -R 755 "$HOME/.local/share/gimp" 2>/dev/null
else
    {
        mkdir -p /tmp/photogimp-backup > /dev/null 2>&1
        cp -r "$HOME/.config/GIMP" /tmp/photogimp-backup/ > /dev/null 2>&1
        rm -rf "$HOME/.config/GIMP" > /dev/null 2>&1
        rm -rf "$HOME/.local/share/gimp" > /dev/null 2>&1
        cp -rf "$PASTA_ATUAL/.config"/* "$HOME/.config/" > /dev/null 2>&1
        cp -rf "$PASTA_ATUAL/.local"/* "$HOME/.local/" > /dev/null 2>&1
        chmod -R 755 "$HOME/.config/GIMP" > /dev/null 2>&1
        chmod -R 755 "$HOME/.local/share/gimp" > /dev/null 2>&1
    } &
    executar_com_spinner "A aplicar ficheiros de configuração" $!
fi

# 5. Abrir o GIMP configurado final
enviar_notificacao "Passo 5/6" "Iniciando o PhotoGIMP..."
if [ "$EXIBIR_LOGS" = true ]; then
    flatpak run org.gimp.GIMP &
else
    flatpak run org.gimp.GIMP > /dev/null 2>&1 &
fi
sleep 2

# 6. Limpeza restrita e segura: remove apenas 'instalador' e 'instalador.zip' se existirem localmente
enviar_notificacao "Passo 6/6" "Limpando ficheiros temporários de instalação..."
if [ "$EXIBIR_LOGS" = true ]; then
    cd "$HOME"
    [ -d "$PASTA_ATUAL/instalador" ] && rm -rf "$PASTA_ATUAL/instalador"
    [ -f "$PASTA_ATUAL/instalador.zip" ] && rm -f "$PASTA_ATUAL/instalador.zip"
    [[ "$PASTA_ATUAL" == *"/instalador"* ]] && rm -rf "$PASTA_ATUAL"
else
    {
        cd "$HOME"
        [ -d "$PASTA_ATUAL/instalador" ] && rm -rf "$PASTA_ATUAL/instalador" > /dev/null 2>&1
        [ -f "$PASTA_ATUAL/instalador.zip" ] && rm -f "$PASTA_ATUAL/instalador.zip" > /dev/null 2>&1
        [[ "$PASTA_ATUAL" == *"/instalador"* ]] && rm -rf "$PASTA_ATUAL" > /dev/null 2>&1
    } &
    executar_com_spinner "A remover a pasta 'instalador' e 'instalador.zip'" $!
fi

# Notificação Final
enviar_notificacao "Concluído" "🎉 PhotoGIMP e G'MIC instalados com sucesso!"
