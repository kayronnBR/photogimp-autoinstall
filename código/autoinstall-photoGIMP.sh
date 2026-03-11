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

# Função para matar GIMP
matar_gimp() {
    flatpak kill org.gimp.GIMP 2>/dev/null
    pkill -9 -f "org.gimp.GIMP" 2>/dev/null
    sleep 2
}

# Função para instalar plugin com opção 3 automática
instalar_plugin_resynthesizer() {
    mensagem "Instalando plugin Resynthesizer (selecionando opção 3 automaticamente)..."
    
    # Usa expect para selecionar a opção 3 automaticamente
    if command -v expect &> /dev/null; then
        # Se expect estiver instalado, usa ele
        expect << EOF
set timeout 30
spawn flatpak install --user flathub org.gimp.GIMP.Plugin.Resynthesizer -y
expect {
    "Qual você deseja usar (0 para abortar)?*" { send "3\r"; exp_continue }
    eof
}
EOF
    else
        # Fallback: tenta instalar sem interação e depois com pipe
        echo "3" | flatpak install --user flathub org.gimp.GIMP.Plugin.Resynthesizer -y 2>/dev/null | \
        while IFS= read -r line; do
            echo "$line"
            if [[ "$line" == *"Qual você deseja usar"* ]]; then
                echo "3"
            fi
        done
    fi
}

# Limpa a tela
clear
echo "=================================================="
echo "   INSTALADOR COMPLETO DO PHOTOGIMP"
echo "   Inclui GIMP Flatpak + Plugin + PhotoGIMP"
echo "=================================================="
echo ""

# Diretório onde o script está
PASTA_ATUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mensagem "📁 Pasta do script: $PASTA_ATUAL"
echo ""

# Verificar se as pastas do PhotoGIMP existem
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

# PASSO 1: VERIFICAR/INSTALL FLATPAK
# ===================================
mensagem_atencao " PASSO 1/5: Verificando Flatpak..."

if ! command -v flatpak &> /dev/null; then
    mensagem "Instalando Flatpak..."
    sudo apt update && sudo apt install flatpak -y
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    mensagem_sucesso "Flatpak já instalado."
fi
echo ""

# PASSO 2: INSTALAR/REINSTALAR GIMP FLATPAK
# ==========================================
mensagem_atencao " PASSO 2/5: (Re)Instalando GIMP Flatpak..."

# Remover versão anterior se existir
if flatpak list | grep -q "org.gimp.GIMP"; then
    mensagem "Removendo versão anterior do GIMP..."
    flatpak uninstall --user -y org.gimp.GIMP 2>/dev/null
    flatpak uninstall -y org.gimp.GIMP 2>/dev/null
fi

mensagem "Instalando GIMP (isso pode levar alguns minutos)..."
flatpak install --user flathub org.gimp.GIMP -y --noninteractive

if [ $? -eq 0 ]; then
    mensagem_sucesso "GIMP instalado com sucesso!"
else
    mensagem_erro "Falha na instalação do GIMP"
    exit 1
fi
echo ""

# PASSO 3: INSTALAR/REINSTALAR PLUGIN RESYNTHESIZER
# ==================================================
mensagem_atencao " PASSO 3/5: (Re)Instalando plugin Resynthesizer..."

# Remover plugin anterior se existir
if flatpak list | grep -q "org.gimp.GIMP.Plugin.Resynthesizer"; then
    mensagem "Removendo versão anterior do plugin..."
    flatpak uninstall --user -y org.gimp.GIMP.Plugin.Resynthesizer 2>/dev/null
    flatpak uninstall -y org.gimp.GIMP.Plugin.Resynthesizer 2>/dev/null
fi

# Instalar plugin com opção 3 automática
instalar_plugin_resynthesizer

# Verificar se instalou
if flatpak list | grep -q "org.gimp.GIMP.Plugin.Resynthesizer"; then
    mensagem_sucesso "Plugin Resynthesizer instalado com sucesso (runtime 3)!"
else
    # Tentativa alternativa
    mensagem_atencao "Tentando método alternativo de instalação..."
    echo "3" | flatpak install --user flathub org.gimp.GIMP.Plugin.Resynthesizer -y --noninteractive 2>/dev/null
    
    if flatpak list | grep -q "org.gimp.GIMP.Plugin.Resynthesizer"; then
        mensagem_sucesso "Plugin Resynthesizer instalado com sucesso!"
    else
        mensagem_erro "Falha na instalação do plugin"
    fi
fi
echo ""

# PASSO 4: ABRIR GIMP POR 35 SEGUNDOS
# ====================================
mensagem_atencao " PASSO 4/5: Abrindo GIMP para criar pastas de configuração..."

# Garantir que GIMP não está rodando
matar_gimp

# Abrir GIMP em segundo plano
mensagem "🚀 Iniciando GIMP por 35 segundos..."
flatpak run org.gimp.GIMP &
GIMP_PID=$!

# Barra de progresso
echo -n "⏰ Aguardando: ["
for ((i=0; i<35; i++)); do
    echo -n "#"
    sleep 1
done
echo "] 35 segundos concluídos!"

# Matar GIMP
mensagem "🔪 Fechando GIMP..."
matar_gimp
mensagem_sucesso "GIMP fechado!"
echo ""

# PASSO 5: COPIAR ARQUIVOS DO PHOTOGIMP
# ======================================
mensagem_atencao " PASSO 5/5: Copiando arquivos do PhotoGIMP..."

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
echo ""

# ==============================================
# FINALIZAR E ABRIR GIMP
# ==============================================
clear
echo "=================================================="
echo "   🎉 REINSTALAÇÃO COMPLETADA COM SUCESSO! 🎉"
echo "=================================================="
echo ""
mensagem_sucesso "PhotoGIMP foi reinstalado completamente!"
echo ""
echo "📌 RESUMO DA REINSTALAÇÃO:"
echo "   ✅ PASSO 1: Flatpak verificado/instalado"
echo "   ✅ PASSO 2: GIMP Flatpak removido e reinstalado"
echo "   ✅ PASSO 3: Plugin removido e reinstalado (runtime 3)"
echo "   ✅ PASSO 4: GIMP aberto por 35s (pastas criadas)"
echo "   ✅ PASSO 5: Configurações antigas removidas e novas copiadas"
echo ""
echo "📂 ARQUIVOS INSTALADOS:"
echo "   • Configurações: ~/.config/GIMP/"
echo "   • Scripts/Dados: ~/.local/share/gimp/"
echo ""
echo "🎨 ABRINDO GIMP AGORA..."
echo ""
echo "=================================================="
echo ""

# Pequena pausa para ler as mensagens
sleep 3

# Abrir GIMP
mensagem "🚀 Iniciando GIMP com PhotoGIMP..."
flatpak run org.gimp.GIMP &

# Mensagem final
mensagem_sucesso "GIMP foi aberto! Aproveite o PhotoGIMP! 🎨"
echo ""

exit 0
