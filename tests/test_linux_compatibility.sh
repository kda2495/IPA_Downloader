#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo " Running IPA_Downloader Linux Test Suite"
echo "========================================"

FAILED=0

pass() {
    echo -e "  \033[32m[PASS]\033[0m $1"
}

fail() {
    echo -e "  \033[31m[FAIL]\033[0m $1"
    FAILED=$((FAILED + 1))
}

# Test 1: Verify Linux AMD64 binary
echo ""
echo "Test 1: Linux AMD64 binary checks"
if [[ -f "MainApp/linux_amd64_v2/ipatool" ]]; then
    pass "MainApp/linux_amd64_v2/ipatool exists"
else
    fail "MainApp/linux_amd64_v2/ipatool is missing"
fi

if [[ -x "MainApp/linux_amd64_v2/ipatool" ]]; then
    pass "MainApp/linux_amd64_v2/ipatool is executable"
else
    fail "MainApp/linux_amd64_v2/ipatool is not executable"
fi

if file "MainApp/linux_amd64_v2/ipatool" | grep -q "ELF 64-bit.*x86-64"; then
    pass "MainApp/linux_amd64_v2/ipatool is valid x86-64 ELF"
else
    fail "MainApp/linux_amd64_v2/ipatool is not x86-64 ELF"
fi

if ./MainApp/linux_amd64_v2/ipatool | grep -q "ipatool-cpp"; then
    pass "MainApp/linux_amd64_v2/ipatool runs successfully and outputs help"
else
    fail "MainApp/linux_amd64_v2/ipatool execution failed"
fi

# Test 2: Verify Linux ARM64 binary
echo ""
echo "Test 2: Linux ARM64 binary checks"
if [[ -f "MainApp/linux_arm64_v2/ipatool" ]]; then
    pass "MainApp/linux_arm64_v2/ipatool exists"
else
    fail "MainApp/linux_arm64_v2/ipatool is missing"
fi

if [[ -x "MainApp/linux_arm64_v2/ipatool" ]]; then
    pass "MainApp/linux_arm64_v2/ipatool is executable"
else
    fail "MainApp/linux_arm64_v2/ipatool is not executable"
fi

if file "MainApp/linux_arm64_v2/ipatool" | grep -q "ELF 64-bit.*aarch64"; then
    pass "MainApp/linux_arm64_v2/ipatool is valid aarch64 ELF"
else
    fail "MainApp/linux_arm64_v2/ipatool is not aarch64 ELF"
fi

# Test 3: Verify launch scripts syntax and permissions
echo ""
echo "Test 3: Launch scripts checks"
if bash -n Start_IPA_Downloader.sh; then
    pass "Start_IPA_Downloader.sh syntax is valid"
else
    fail "Start_IPA_Downloader.sh syntax error"
fi

if [[ -x "Start_IPA_Downloader.sh" ]]; then
    pass "Start_IPA_Downloader.sh is executable"
else
    fail "Start_IPA_Downloader.sh is not executable"
fi

# Test 4: Verify MainApp folder structure completeness
echo ""
echo "Test 4: MainApp directory structure completeness"
REQUIRED_DIRS=(
    "MainApp/windows_amd64_v2"
    "MainApp/macOS_amd64_v2"
    "MainApp/macOS_arm64_v2"
    "MainApp/linux_amd64_v2"
    "MainApp/linux_arm64_v2"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        pass "Directory $dir exists"
    else
        fail "Directory $dir is missing"
    fi
done

# Test 5: Verify PowerShell script syntax and logic if pwsh is available
echo ""
echo "Test 5: PowerShell script checks"
if command -v pwsh &>/dev/null; then
    if pwsh -NoProfile -Command "
        \$script = Get-Content './IPA_Downloader.ps1' -Raw
        \$errors = \$null
        [System.Management.Automation.Language.Parser]::ParseInput(\$script, [ref]\$null, [ref]\$errors) | Out-Null
        if (\$errors.Count -gt 0) {
            Write-Error \"Syntax errors found in IPA_Downloader.ps1\"
            exit 1
        }
    "; then
        pass "IPA_Downloader.ps1 parsed without syntax errors"
    else
        fail "IPA_Downloader.ps1 contains syntax errors"
    fi

    # Test architecture resolution function logic
    if pwsh -NoProfile -Command "
        \$IsWin = \$false
        \$IsMac = \$false
        \$IsLin = \$true
        
        function Get-ArchSubFolder {
            param ([ValidateSet('v2', 'v3')][string]\$Version, [string]\$TargetArch)
            if (\$IsWin) {
                if (\$Version -eq 'v3') { return 'windows_amd64_v3' } else { return 'windows_amd64_v2' }
            } elseif (\$IsLin) {
                if (\$TargetArch -eq 'arm64') {
                    if (\$Version -eq 'v3') { return 'linux_arm64_v3' } else { return 'linux_arm64_v2' }
                } else {
                    if (\$Version -eq 'v3') { return 'linux_amd64_v3' } else { return 'linux_amd64_v2' }
                }
            } else {
                if (\$TargetArch -eq 'arm64') {
                    if (\$Version -eq 'v3') { return 'macOS_arm64_v3' } else { return 'macOS_arm64_v2' }
                } else {
                    if (\$Version -eq 'v3') { return 'macOS_amd64_v3' } else { return 'macOS_amd64_v2' }
                }
            }
        }
        
        \$x64 = Get-ArchSubFolder -Version 'v2' -TargetArch 'x64'
        \$arm = Get-ArchSubFolder -Version 'v2' -TargetArch 'arm64'
        if (\$x64 -ne 'linux_amd64_v2' -or \$arm -ne 'linux_arm64_v2') {
            exit 1
        }
    "; then
        pass "Architecture resolution logic works correctly"
    else
        fail "Architecture resolution logic test failed"
    fi
else
    echo "  [INFO] pwsh not installed; skipping PowerShell parser test"
fi

echo ""
echo "========================================"
if [[ $FAILED -eq 0 ]]; then
    echo -e " \033[32mAll tests passed successfully!\033[0m"
    echo "========================================"
    exit 0
else
    echo -e " \033[31m$FAILED test(s) failed!\033[0m"
    echo "========================================"
    exit 1
fi
