<h1> [DOWNLOAD](https://downgit.github.io/#/home?url=https://github.com/kayronnBR/photogimp-autoinstall/tree/main/instalador) </h1>

# 🚀 PhotoGIMP Automated Installer & GMic Plugin Setup

Este repositório contém um script Bash automatizado e inteligente para instalar, configurar e otimizar a experiência do **GIMP** no Linux, aplicando o patch **PhotoGIMP** (projeto criado pela comunidade [Diolinux](https://github.com/Diolinux/PhotoGIMP) e instalando automaticamente o plugin de efeitos **G'MIC**.

O **PhotoGIMP** transforma a interface e os atalhos do GIMP para ficarem o mais próximos e familiares possível do **Adobe Photoshop**, ideal para quem está migrando de sistema operacional ou busca maior produtividade na edição de imagens.

---

## 📌 Funcionalidades do Script

- **Instalação Automática:** Configura o **Flatpak** e o repositório **Flathub** caso ainda não estejam ativos no sistema (compatível com Ubuntu, Debian, Fedora, Arch, Manjaro, etc.).
- **Download do GIMP & G'MIC:** Baixa e instala a versão mais recente do GIMP via Flatpak e instala automaticamente a *branch* compatível do plugin `org.gimp.GIMP.Plugin.GMic`.
- **Seleção Interativa com Timeout (10s):**
  - **Modo 1 (Padrão):** Instalação limpa com barra de carregamento dinâmica (*spinner*) e console silencioso.
  - **Modo 2:** Exibição detalhada de *logs* de saída no terminal.
  - Se nenhuma opção for pressionada em 10 segundos, o modo silencioso é selecionado automaticamente.
- **Notificações Desktop Multidistro:** Notificações em tempo real durante cada etapa do processo via `notify-send`, `gdbus` ou `kdialog` (testado no KDE Plasma, XFCE, GNOME e outros).
- **Fechamento Inteligente:** Abre o GIMP temporariamente para gerar as pastas padrão de sistema, monitora a inicialização pelos *logs* e encerra o programa automaticamente assim que o perfil é carregado.
- **Aplicação da Interface:** Aplica o patch PhotoGIMP copiando com segurança os arquivos das pastas `.config` e `.local` para o diretório do usuário (`$HOME`).
- **Limpeza Segura:** Limpa arquivos temporários ao final do processo sem apagar dados indevidos do sistema.

---

## 🛠️ Como Utilizar

1. **Faça o download do PhotoGIMP** do repositório oficial ou extraia os arquivos compactados.
2. araste o script `autoinstall-photoGIMP.sh` dentro do seu terminal e click enter.
3. depois vai perguta se você quer modo limpo ou com logs, então você escolhe porque o resto já é automatico.

---

## 👥 Créditos e Agradecimentos

- **PhotoGIMP Project:** Desenvolvido e mantido pela equipe [Diolinux](https://github.com/Diolinux).
- **Repositório Oficial:** [GitHub - Diolinux/PhotoGIMP](https://github.com/Diolinux/PhotoGIMP)
- **GIMP:** [gimp.org](https://www.gimp.org/)
- **G'MIC Plugin:** [gmic.eu](https://gmic.eu/)
- **Google Gemini:** quem fez o codigo [Google Gemini](https://gemini.google.com/?hl=pt-BR)
