#!/bin/zsh
cd "$(dirname "$0")" || exit
pwsh -File "./IPA_Installer.ps1"
echo ""
echo -n "Нажмите любую клавишу для выхода..."
read -k 1 -s -r