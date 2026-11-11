#!/bin/zsh
cd "$(dirname "$0")" || exit
SYSTEM_LANG="${LANG:0:2}"
case "$SYSTEM_LANG" in
	ru)
		NO_PWSH_MSG="Ошибка: PowerShell (pwsh) не установлен."
		PROMPT_MSG="Нажмите любую клавишу для выхода..."
		;;
	*)
		NO_PWSH_MSG="Error: PowerShell (pwsh) is not installed."
		PROMPT_MSG="Press any key to exit..."
		;;
esac
pwsh -File "./IPA_Downloader.ps1"
PWSH_STATUS=$?
if [ "$PWSH_STATUS" -eq 127 ]; then
	echo "$NO_PWSH_MSG"
fi
echo ""
echo -n "$PROMPT_MSG"
read -k 1 -s -r
