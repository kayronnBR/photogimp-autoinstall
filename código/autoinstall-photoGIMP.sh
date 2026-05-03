#!/bin/bash

# ==============================================
# PHOTOGIMP - APENAS CÓPIA DE CONFIGURAÇÕES + NOTIFICAÇÃO
# ==============================================

# Diretório onde o script está sendo executado
PASTA_ATUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Pasta atual: $PASTA_ATUAL"

# 1. Verificar se os arquivos necessários existem na pasta do download
if [ ! -d "$PASTA_ATUAL/.config" ] || [ ! -d "$PASTA_ATUAL/.local" ]; then
    echo "❌ Erro: Pastas .config ou .local não encontradas em $PASTA_ATUAL"
    exit 1
fi

# 2. Fechar o GIMP se estiver aberto (versão Flatpak)
echo "🚀 Fechando GIMP..."
flatpak kill org.gimp.GIMP 2>/dev/null
pkill -9 -f "org.gimp.GIMP" 2>/dev/null

# 3. Backup (Opcional, mas seguro)
echo "💾 Criando backup em /tmp/photogimp-backup"
mkdir -p /tmp/photogimp-backup
cp -r "$HOME/.config/GIMP" /tmp/photogimp-backup/ 2>/dev/null

# 4. Limpar configurações antigas
echo "🧹 Removendo configurações antigas..."
rm -rf "$HOME/.config/GIMP" 2>/dev/null
rm -rf "$HOME/.local/share/gimp" 2>/dev/null

# 5. Mover/Copiar novos arquivos para a Home do usuário
echo "📂 Aplicando interface PhotoGIMP..."
cp -rf "$PASTA_ATUAL/.config"/* "$HOME/.config/" 2>/dev/null
cp -rf "$PASTA_ATUAL/.local"/* "$HOME/.local/" 2>/dev/null

# 6. Ajustar permissões
chmod -R 755 "$HOME/.config/GIMP" 2>/dev/null
chmod -R 755 "$HOME/.local/share/gimp" 2>/dev/null

# 7. Notificação Final
if command -v notify-send &> /dev/null; then
    notify-send "PhotoGIMP" "🎉 Instalação concluída com sucesso!" --icon=gimp
fi

echo "✅ Concluído! A interface foi aplicada."
