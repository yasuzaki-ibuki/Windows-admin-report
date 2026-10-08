# ===== Windows パッチ・ユーザー確認レポート =====

# 出力先フォルダ(スクリプトと同じ場所に output フォルダを作る)
$outDir = Join-Path $PSScriptRoot "output"
New-Item -Path $outDir -ItemType Directory -Force | Out-Null

# 実行日時(ファイル名に付けて、いつのレポートかわかるようにする)
$date = Get-Date -Format "yyyyMMdd_HHmm"

# 1. PCの基本情報
Get-ComputerInfo -Property CsName, OsName, OsVersion |
    Export-Csv -Path (Join-Path $outDir "computer_$date.csv") -NoTypeInformation -Encoding UTF8

# 2. パッチ一覧(新しい順)
Get-HotFix |
    Select-Object HotFixID, Description,
        @{Name = "InstalledOn"; Expression = { try { $_.InstalledOn } catch { $null } }} |
    Sort-Object InstalledOn -Descending |
    Export-Csv -Path (Join-Path $outDir "hotfix_$date.csv") -NoTypeInformation -Encoding UTF8

# 3. ローカルユーザー一覧
Get-LocalUser |
    Select-Object Name, Enabled, LastLogon |
    Export-Csv -Path (Join-Path $outDir "users_$date.csv") -NoTypeInformation -Encoding UTF8

# 4. 管理者グループのメンバー
Get-LocalGroupMember -Group Administrators |
    Select-Object Name, ObjectClass, PrincipalSource |
    Export-Csv -Path (Join-Path $outDir "admins_$date.csv") -NoTypeInformation -Encoding UTF8

Write-Host "レポートを出力しました: $outDir"