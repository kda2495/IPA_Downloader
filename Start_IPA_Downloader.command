#!/bin/zsh
cd "$(dirname "$0")" || exit
pwsh -File "./IPA_Downloader.ps1"
echo ""
SYSTEM_LANG="${LANG:0:2}"
case "$SYSTEM_LANG" in
    ru)
        PROMPT_MSG="Нажмите любую клавишу для выхода..."
        ;;
    *)
        PROMPT_MSG="Press any key to exit..."
        ;;
esac
echo -n "$PROMPT_MSG"
read -k 1 -s -r