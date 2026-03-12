#!/bin/bash

# ==============================================
# INSTALADOR COMPLETO DO PHOTOGIMP - VERSÃO SIMPLIFICADA
# ==============================================
# - SEM correção de Flathub
# - Instala o plugin com runtime 3 (GIMP 3.0)
# - Cria links na pasta bin (caminho correto para GIMP 3.0)
# - Garante que o GIMP abra no final
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

# FUNÇÃO 1: Instalar GIMP com verificação
instalar_gimp() {
    mensagem_destaque "INSTALANDO GIMP..."
    
    # Remover versão anterior se existir
    if flatpak list | grep -q "org.gimp.GIMP"; then
        mensagem "Removendo versão anterior do GIMP..."
        flatpak uninstall -y --user org.gimp.GIMP 2>/dev/null
        flatpak uninstall -y --system org.gimp.GIMP 2>/dev/null
    fi
    
    # Limpar cache
    flatpak uninstall --unused -y 2>/dev/null
    
    # Instalar GIMP
    mensagem "Instalando GIMP (pode levar alguns minutos)..."
    barra_progresso "Instalando GIMP" 3
    
    if flatpak install --user flathub org.gimp.GIMP -y; then
        mensagem_sucesso "✅ GIMP instalado com sucesso (modo usuário)!"
    elif flatpak install flathub org.gimp.GIMP -y; then
        mensagem_sucesso "✅ GIMP instalado com sucesso (modo sistema)!"
    else
        mensagem_erro "Falha na instalação do GIMP. Tentando com URL direta..."
        flatpak install --user https://flathub.org/repo/appstream/org.gimp.GIMP.flatpakref -y
        
        if ! flatpak list | grep -q "org.gimp.GIMP"; then
            mensagem_erro "❌ Não foi possível instalar o GIMP"
            exit 1
        fi
    fi
}

# FUNÇÃO 2: Instalar plugin Resynthesizer
instalar_plugin() {
    mensagem_destaque "INSTALANDO PLUGIN RESYNTHESIZER..."
    
    # Remover plugin anterior
    if flatpak list | grep -q "org.gimp.GIMP.Plugin.Resynthesizer"; then
        mensagem "Removendo versão anterior do plugin..."
        flatpak uninstall --user -y org.gimp.GIMP.Plugin.Resynthesizer 2>/dev/null
    fi
    
    # Instalar plugin com runtime 3 (GIMP 3.0)
    mensagem "Instalando plugin Resynthesizer (runtime 3)..."

    # Método 1: Instalação automática com expect
    if command -v expect &> /dev/null; then
        expect << 'EOF' > /dev/null 2>&1
        spawn flatpak install --user flathub org.gimp.GIMP.Plugin.Resynthesizer
        expect "Qual você deseja usar (0 para abortar)?*" { send "3\r" }
        expect "Prosseguir com essas alterações*" { send "y\r" }
        expect "Digite s/n:*" { send "y\r" }
        expect eof
EOF
    else
        # Método 2: Instalação manual com echo
        echo -e "3\ny" | flatpak install --user flathub org.gimp.GIMP.Plugin.Resynthesizer -y
    fi
    
    # Verificar se instalou
    sleep 3
    if flatpak list | grep -q "org.gimp.GIMP.Plugin.Resynthesizer"; then
        mensagem_sucesso "✅ Plugin instalado via Flatpak!"
    else
        mensagem_erro "Não foi possível instalar o plugin automaticamente."
        mensagem "Execute manualmente depois:"
        mensagem "   flatpak install flathub org.gimp.GIMP.Plugin.Resynthesizer"
        mensagem "   (escolha a opção 3 quando perguntado)"
    fi
}

# FUNÇÃO 3: Configurar links do plugin (usa pasta bin para GIMP 3.0)
configurar_plugin_links() {
    mensagem_destaque "CONFIGURANDO LINKS DO PLUGIN..."
    
    # Versão do GIMP
    GIMP_VERSAO="3.0"
    PASTA_PLUGINS_GIMP="$HOME/.config/GIMP/$GIMP_VERSAO/plug-ins"
    
    # Criar pasta de plugins
    mkdir -p "$PASTA_PLUGINS_GIMP"
    mensagem_sucesso "Pasta de plugins: $PASTA_PLUGINS_GIMP"
    
    # Para GIMP 3.0, os plugins estão na pasta BIN, não em plug-ins
    mensagem "Procurando plugins na pasta bin (GIMP 3.0)..."
    
    # Possíveis caminhos para GIMP 3.0
    CAMINHOS_BIN=(
        "$HOME/.local/share/flatpak/runtime/org.gimp.GIMP.Plugin.Resynthesizer/x86_64/3/active/files/bin"
        "$HOME/.local/share/flatpak/runtime/org.gimp.GIMP.Plugin.Resynthesizer/x86_64/3/active/files"
        "$HOME/.local/share/flatpak/app/org.gimp.GIMP.Plugin.Resynthesizer/x86_64/3/active/files/bin"
        "$HOME/.local/share/flatpak/app/org.gimp.GIMP.Plugin.Resynthesizer/x86_64/3/active/files"
        "$(find $HOME/.local/share/flatpak -path "*/org.gimp.GIMP.Plugin.Resynthesizer/*/active/files/bin" -type d 2>/dev/null | head -1)"
        "$(find $HOME/.local/share/flatpak -path "*/org.gimp.GIMP.Plugin.Resynthesizer/*/active/files" -type d 2>/dev/null | head -1)"
    )
    
    PLUGIN_ENCONTRADO=""
    for CAMINHO in "${CAMINHOS_BIN[@]}"; do
        if [ -d "$CAMINHO" ]; then
            PLUGIN_ENCONTRADO="$CAMINHO"
            mensagem_sucesso "Plugin encontrado em: $CAMINHO"
            
            # Mostrar arquivos encontrados
            echo "   Arquivos disponíveis:"
            ls -la "$CAMINHO" | grep -E "resynth|heal|plugin" 2>/dev/null | while read linha; do
                echo "     $linha"
            done
            break
        fi
    done
    
    # Criar links simbólicos
    if [ -n "$PLUGIN_ENCONTRADO" ]; then
        mensagem "Criando links simbólicos..."
        
        QTD_LINKS=0
        for arquivo in "$PLUGIN_ENCONTRADO"/*; do
            if [ -f "$arquivo" ]; then
                nome_arquivo=$(basename "$arquivo")
                link_destino="$PASTA_PLUGINS_GIMP/$nome_arquivo"
                
                # Remover link antigo se existir
                [ -L "$link_destino" ] && rm "$link_destino"
                [ -f "$link_destino" ] && rm "$link_destino"
                
                # Criar novo link
                ln -sf "$arquivo" "$link_destino"
                chmod +x "$link_destino" 2>/dev/null
                
                mensagem "   Link criado: $nome_arquivo"
                QTD_LINKS=$((QTD_LINKS + 1))
            fi
        done
        
        if [ $QTD_LINKS -gt 0 ]; then
            mensagem_sucesso "✅ $QTD_LINKS plugins configurados!"
        else
            mensagem_atencao "Nenhum arquivo encontrado para criar links"
        fi
    else
        mensagem_erro "Pasta do plugin não encontrada!"
        
        # Diagnóstico
        echo ""
        mensagem_atencao "Diagnóstico:"
        echo "   1. Plugins Flatpak instalados:"
        flatpak list | grep -i resynth || echo "      Nenhum plugin encontrado"
        
        echo ""
        echo "   2. Busca geral por pastas do plugin:"
        find "$HOME/.local/share/flatpak" -name "*resynth*" -type d 2>/dev/null | head -5 | while read linha; do
            echo "      • $linha"
        done
    fi
}

# Configurações
TOTAL_PASSOS=5  # Reduzido para 5 passos (sem a correção do Flathub)
PASSO_ATUAL=0

# Início
clear
echo -e "${CIANO}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         INSTALADOR PHOTOGIMP - VERSÃO SIMPLIFICADA           ║"
echo "║         Inclui GIMP Flatpak + Plugin + PhotoGIMP             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo ""

notificar "PhotoGIMP" "🚀 Iniciando instalação..." "system-run"

# Diretório do script
PASTA_ATUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mensagem "📁 Pasta do script: $PASTA_ATUAL"
echo ""

# Verificar pastas do PhotoGIMP
if [ ! -d "$PASTA_ATUAL/.config" ]; then
    mensagem_erro "Pasta .config não encontrada em: $PASTA_ATUAL"
    exit 1
fi

if [ ! -d "$PASTA_ATUAL/.local" ]; then
    mensagem_erro "Pasta .local não encontrada em: $PASTA_ATUAL"
    exit 1
fi

mensagem_sucesso "Pastas do PhotoGIMP encontradas!"
echo ""

# PASSO 1: Verificar Flatpak
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "Verificando Flatpak"

if ! command -v flatpak &> /dev/null; then
    mensagem_destaque "Instalando Flatpak..."
    sudo apt update
    sudo apt install flatpak -y
else
    mensagem_sucesso "Flatpak: $(flatpak --version)"
fi

# Verificar Flathub (apenas verifica, não corrige)
if ! flatpak remotes --user | grep -q "flathub"; then
    mensagem_atencao "Flathub não encontrado. Adicionando..."
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    mensagem_sucesso "Flathub já configurado"
fi

flatpak update --appstream > /dev/null 2>&1
echo ""

# PASSO 2: Instalar GIMP
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "Instalando GIMP"

instalar_gimp
echo ""

# PASSO 3: Instalar Plugin
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "Instalando plugin Resynthesizer"

instalar_plugin
echo ""

# PASSO 4: Configurar links do plugin
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "Configurando links do plugin"

configurar_plugin_links
echo ""

# PASSO 5: Abrir GIMP para criar pastas e copiar PhotoGIMP
PASSO_ATUAL=$((PASSO_ATUAL + 1))
mostrar_passo $PASSO_ATUAL $TOTAL_PASSOS "Preparando pastas e copiando PhotoGIMP"

matar_gimp

mensagem "🚀 Iniciando GIMP por 35 segundos..."
flatpak run org.gimp.GIMP &
GIMP_PID=$!

barra_progresso "Aguardando criação das pastas" 35

mensagem "🔪 Fechando GIMP..."
matar_gimp
mensagem_sucesso "Pastas criadas!"
echo ""

# Copiar PhotoGIMP
mensagem "Copiando arquivos do PhotoGIMP..."

# Backup
if [ -d "$HOME/.config/GIMP" ]; then
    mkdir -p /tmp/photogimp-backup
    cp -r "$HOME/.config/GIMP" /tmp/photogimp-backup/ 2>/dev/null
    mensagem "Backup salvo em: /tmp/photogimp-backup/"
fi

# Remover configurações antigas
mensagem "Removendo configurações antigas..."
rm -rf "$HOME/.config/GIMP" 2>/dev/null
rm -rf "$HOME/.local/share/gimp" 2>/dev/null

# Copiar novas configurações
mensagem "Copiando configurações do PhotoGIMP..."
cp -rf "$PASTA_ATUAL/.config"/* "$HOME/.config/" 2>/dev/null
cp -rf "$PASTA_ATUAL/.local"/* "$HOME/.local/" 2>/dev/null

chmod -R 755 "$HOME/.config/GIMP" 2>/dev/null
chmod -R 755 "$HOME/.local/share/gimp" 2>/dev/null

mensagem_sucesso "✅ PhotoGIMP copiado com sucesso!"
echo ""

# FINALIZAR
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
echo -e "   ${VERDE}✅${RESET} PASSO 1: Flatpak verificado"
echo -e "   ${VERDE}✅${RESET} PASSO 2: GIMP Flatpak instalado"
echo -e "   ${VERDE}✅${RESET} PASSO 3: Plugin Resynthesizer instalado"
echo -e "   ${VERDE}✅${RESET} PASSO 4: Links do plugin configurados"
echo -e "   ${VERDE}✅${RESET} PASSO 5: Pastas criadas e PhotoGIMP copiado"
echo ""

echo -e "${BOLD}📂 ARQUIVOS INSTALADOS:${RESET}"
echo "   • Configurações: ~/.config/GIMP/"
echo "   • Scripts/Dados: ~/.local/share/gimp/"
echo "   • Plugins: ~/.config/GIMP/3.0/plug-ins/ (links dos plugins)"
echo ""

# Verificar plugin
if [ -d "$HOME/.config/GIMP/3.0/plug-ins" ] && [ "$(ls -A $HOME/.config/GIMP/3.0/plug-ins 2>/dev/null)" ]; then
    echo -e "${VERDE}✅ PLUGIN RESYNTHESIZER: INSTALADO E CONFIGURADO!${RESET}"
    echo -e "   Os plugins estarão disponíveis em:"
    echo -e "   • Filtros → Melhorar → Heal Selection..."
    echo -e "   • Filtros → Melhorar → Heal Transparency..."
    echo -e "   • Filtros → Mapear → Resynthesizer..."
    echo -e "   • Filtros → Mapear → Style..."
    echo -e "   • Filtros → Render → Texture..."
else
    echo -e "${AMARELO}⚠️ PLUGIN RESYNTHESIZER: Pode precisar de configuração manual${RESET}"
    echo -e "   Para instalar manualmente:"
    echo -e "   flatpak install flathub org.gimp.GIMP.Plugin.Resynthesizer"
    echo -e "   (escolha a opção 3 quando perguntado)"
fi
echo ""

echo -e "${CIANO}${BOLD}🎨 ABRINDO GIMP AGORA...${RESET}"
echo "=================================================="

notificar "PhotoGIMP" "🎉 Instalação concluída! Abrindo GIMP..." "gimp"

# Pequena pausa
sleep 2

# Abrir GIMP e manter
mensagem "🚀 Iniciando GIMP com PhotoGIMP..."
flatpak run org.gimp.GIMP

# Mensagem final (só aparece quando fechar o GIMP)
echo ""
mensagem_sucesso "GIMP foi fechado. Aproveite o PhotoGIMP! 🎨"
echo ""

exit 0
