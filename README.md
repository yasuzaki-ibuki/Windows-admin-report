\# Windows-admin-report



Windows Server / Active Directory の運用保守を想定し、\*\*検証環境の構築からPowerShellによる運用作業まで\*\*を自分の手で行った記録です。



\## 概要



\- VirtualBox上に \*\*Windows Server 2025\*\* を構築し、\*\*ドメインコントローラーへ昇格\*\*

\- AD管理の代表的な業務(\*\*入社・異動・ロック解除・退職\*\*)をPowerShellで再現

\- パッチ・ユーザー・管理者権限を棚卸しする \*\*PowerShellスクリプト\*\*を作成



\## 構成



```mermaid

flowchart LR

&#x20;   A\[ホストPC<br>Windows 11] --> B\[VirtualBox 7.2]

&#x20;   B --> C\[DC01<br>Windows Server 2025]

&#x20;   C --> D\[AD DS<br>lab.local]

&#x20;   C --> E\[DNS]

```



| 項目 | 内容 |

| --- | --- |

| ホストOS | Windows 11 |

| 仮想化ソフト | VirtualBox 7.2 |

| サーバーOS | Windows Server 2025 Standard Evaluation(デスクトップ エクスペリエンス) |

| 仮想マシン | メモリ 6GB / CPU 4コア / ディスク 50GB |

| ドメイン | lab.local(NetBIOS名:LAB) |

| ネットワーク | NAT / IPアドレス固定(10.0.2.15/24)/ DNSは自身を参照 |



\## 1. 検証環境の構築



| 手順 | 内容 | 主なコマンド |

| --- | --- | --- |

| 1 | 仮想マシンの作成 | `VBoxManage createvm` / `modifyvm` / `createmedium` / `storageattach` |

| 2 | Windows Server 2025 のインストール | (インストーラー) |

| 3 | AD DS の役割をインストール | `Install-WindowsFeature` |

| 4 | ドメインコントローラーへ昇格 | `Install-ADDSForest` |

| 5 | IPアドレスとDNSの固定 | `New-NetIPAddress` / `Set-DnsClientServerAddress` |



```powershell

\# AD DS のインストールと、ドメインコントローラーへの昇格

Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Install-ADDSForest -DomainName lab.local -DomainNetbiosName LAB -InstallDns

```



\## 2. AD管理業務の再現



| 業務 | 内容 | 主なコマンド |

| --- | --- | --- |

| 入社 | ユーザー作成・部署グループへの追加 | `New-ADUser` / `Add-ADGroupMember` |

| 一括登録 | CSVの名簿から複数ユーザーを作成(初回ログイン時にパスワード変更を強制) | `Import-Csv` / `ForEach-Object` |

| 異動 | OUの移動・グループの付け替え | `Move-ADObject` / `Remove-ADGroupMember` |

| ロック解除 | ロックアウトポリシーを設定し、ロック状態の確認と解除 | `Set-ADDefaultDomainPasswordPolicy` / `Search-ADAccount` / `Unlock-ADAccount` |

| パスワードリセット | 管理者による再設定 | `Set-ADAccountPassword -Reset` |

| 退職 | アカウントの無効化(削除せず無効化) | `Disable-ADAccount` |

| サービス確認 | 自動起動なのに停止しているサービスの確認 | `Get-Service` / `Where-Object` |



```powershell

\# 例:CSVの名簿からユーザーを一括作成し、部署グループに追加

Import-Csv C:\\users.csv | ForEach-Object {

&#x20;   New-ADUser -Name $\_.Name -SamAccountName $\_.Id -Path $\_.OU -AccountPassword $pw -Enabled $true -ChangePasswordAtLogon $true

&#x20;   Add-ADGroupMember -Identity $\_.Group -Members $\_.Id

}

```



\## 3. Get-SystemReport.ps1(パッチ・ユーザー確認レポート)



PCの状態を確認し、結果をCSVに出力するスクリプトです。



| 出力ファイル | 内容 | 想定業務 |

| --- | --- | --- |

| `computer\_日時.csv` | コンピューター名・OS・バージョン | 資産管理 |

| `hotfix\_日時.csv` | インストール済みパッチ(新しい順) | パッチ管理 |

| `users\_日時.csv` | ローカルユーザーと有効/無効 | アカウント棚卸し |

| `admins\_日時.csv` | 管理者グループのメンバー | 権限の棚卸し |



\*\*実行方法\*\*



```powershell

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.\\Get-SystemReport.ps1

```



※ 出力されたCSVは `output` フォルダに保存されます(PC名などを含むため、GitHubには公開していません)。



\## 4. トラブルと対処



| 現象 | 原因 | 対処 |

| --- | --- | --- |

| VirtualBoxの作成画面で「完了」が反応しない | GUIの不具合 | `VBoxManage` コマンドで仮想マシンを作成して回避 |

| `Get-HotFix` の並べ替えでエラー | インストール日が空のパッチが存在する | 計算プロパティと `try/catch` で、空の値をエラーにせず処理 |

| `New-ADUser` が失敗し、再実行すると「既に存在」 | パスワードの複雑さ要件を満たさず、ユーザーだけ無効状態で作成されていた | `Set-ADAccountPassword -Reset` と `Enable-ADAccount` で対処 |

| ホストと仮想マシン間でコピペできない | クリップボード共有が有効になっていなかった | Guest Additions を導入し、`VBoxTray` の稼働確認とクリップボード共有を設定 |



\## 5. 工夫した点・学んだこと



\- 日本語を含むスクリプトを Windows PowerShell 5.1 で正しく動かすため、\*\*UTF-8(BOM付き)\*\*で保存

\- 退職者は\*\*削除せず無効化\*\*する(ファイルの権限情報や引き継ぎに影響するため)

\- ドメインコントローラーは\*\*昇格後にコンピューター名を変更すべきではない\*\*ため、名前は昇格前に決めておく

\- 実行結果に含まれるPC名・ユーザー名は `.gitignore` で除外し、公開範囲に注意



\## 6. 今後の予定



\- GPO(グループポリシー)によるPCへの設定配布

\- クライアントPCをドメインに参加させての動作確認

\- Entra ID / Azure とのハイブリッド構成の学習

