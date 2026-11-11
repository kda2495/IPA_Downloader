#!/bin/bash
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

if ! command -v pwsh &>/dev/null; then
	echo ""
	echo "$NO_PWSH_MSG"
	echo ""
	echo -n "$PROMPT_MSG"
	read -n 1 -s -r
	echo ""
	exit 1
fi

pwsh -File "./IPA_Downloader.ps1"
echo ""
echo -n "$PROMPT_MSG"
read -n 1 -s -r
echo ""
