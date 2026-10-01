#!/bin/bash
cd "$(dirname "$0")" || exit

SYSTEM_LANG="${LANG:0:2}"

if ! command -v pwsh &>/dev/null; then
    echo ""
    case "$SYSTEM_LANG" in
        ru)
            echo "Ошибка: PowerShell (pwsh) не найден в системе."
            echo "Пожалуйста, установите PowerShell:"
            echo "  - Arch Linux: sudo pacman -S powershell-bin (или через AUR: yay -S powershell-bin)"
            echo "  - Ubuntu/Debian: sudo apt install powershell"
            echo "  - Fedora: sudo dnf install powershell"
            PROMPT_MSG="Нажмите любую клавишу для выхода..."
            ;;
        *)
            echo "Error: PowerShell (pwsh) not found in your system."
            echo "Please install PowerShell:"
            echo "  - Arch Linux: sudo pacman -S powershell-bin (or via AUR: yay -S powershell-bin)"
            echo "  - Ubuntu/Debian: sudo apt install powershell"
            echo "  - Fedora: sudo dnf install powershell"
            PROMPT_MSG="Press any key to exit..."
            ;;
    esac
    echo ""
    echo -n "$PROMPT_MSG"
    read -n 1 -s -r
    echo ""
    exit 1
fi

pwsh -File "./IPA_Downloader.ps1"
echo ""

case "$SYSTEM_LANG" in
    ru)
        PROMPT_MSG="Нажмите любую клавишу для выхода..."
        ;;
    *)
        PROMPT_MSG="Press any key to exit..."
        ;;
esac
echo -n "$PROMPT_MSG"
read -n 1 -s -r
echo ""
