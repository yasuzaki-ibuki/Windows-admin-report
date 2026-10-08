\# Windows-admin-report



Windows Server / Active Directory 環境の運用保守を想定して、検証環境の構築からPowerShellによる運用作業までを自分の手で行った記録です。



\## 目的



Windows Server・ADの運用業務(アカウント管理・パッチ管理)を想定し、

実際に手を動かして仕組みと作業手順を理解するため。



\## 検証環境



| 項目 | 内容 |

| --- | --- |

| ホストOS | Windows 11 |

| 仮想化ソフト | VirtualBox 7.2 |

| サーバーOS | Windows Server 2025 Standard Evaluation(デスクトップ エクスペリエンス) |

| 仮想マシン | メモリ 6GB / CPU 4コア / ディスク 50GB |

| ドメイン | lab.local(NetBIOS名:LAB) |



\## 1. Get-SystemReport.ps1(パッチ・ユーザー確認レポート)



PCの状態を確認し、CSVに出力するPowerShellスクリプトです。



| 出力ファイル | 内容 | 想定業務 |

| --- | --- | --- |

| computer\_日時.csv | コンピューター名・OS・バージョン | 資産管理 |

| hotfix\_日時.csv | インストール済みパッチ(新しい順) | パッチ管理 |

| users\_日時.csv | ローカルユーザーと有効/無効 | アカウント棚卸し |

| admins\_日時.csv | 管理者グループのメンバー | 権限の棚卸し |



実行方法(PowerShell)



&#x20;   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

&#x20;   .\\Get-SystemReport.ps1



\## 2. 検証環境の構築



1\. VBoxManage コマンドで仮想マシンを作成(createvm / modifyvm / createmedium / storageattach)

2\. Windows Server 2025 をインストール

3\. AD DS をインストールし、ドメインコントローラーへ昇格



&#x20;       Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

&#x20;       Install-ADDSForest -DomainName lab.local -DomainNetbiosName LAB -InstallDns



4\. IPアドレスを固定(New-NetIPAddress / Set-DnsClientServerAddress)



\## 3. AD管理業務の再現



| 業務 | 内容 | 主なコマンド |

| --- | --- | --- |

| 入社 | ユーザー作成・部署グループへの追加 | New-ADUser / Add-ADGroupMember |

| 一括登録 | CSVの名簿から複数ユーザーを作成 | Import-Csv / ForEach-Object |

| 異動 | OUの移動・グループの付け替え | Move-ADObject / Remove-ADGroupMember |

| ロック解除 | ロック状態の確認と解除 | Search-ADAccount -LockedOut / Unlock-ADAccount |

| パスワードリセット | 管理者による再設定 | Set-ADAccountPassword -Reset |

| 退職 | アカウントの無効化 | Disable-ADAccount |

| サービス監視 | 自動起動なのに停止しているサービスの確認 | Get-Service / Where-Object |



\## 4. つまずいた点と対処



\- \*\*VirtualBoxの作成画面が反応しない\*\*

&#x20; → VBoxManage コマンドで仮想マシンを作成して回避した

\- \*\*Get-HotFix の並べ替えでエラー\*\*(インストール日が空のパッチがある)

&#x20; → 計算プロパティと try/catch で、空の値をエラーにせず処理した

\- \*\*New-ADUser がパスワードの複雑さ要件で失敗\*\*

&#x20; → ユーザーだけ作成され無効状態で残っていたため、Set-ADAccountPassword -Reset と Enable-ADAccount で対処した

\- \*\*日本語を含むスクリプトが文字化けする\*\*

&#x20; → Windows PowerShell 5.1 向けに UTF-8(BOM付き)で保存した

\- \*\*ホストと仮想マシン間でコピペできない\*\*

&#x20; → Guest Additions を導入し、VBoxTray の稼働確認とクリップボード共有の設定を行った

\- \*\*学び\*\*:ドメインコントローラーは昇格後にコンピューター名を変更すべきではないため、名前は昇格前に決めておく



\## 5. 今後の予定



\- GPO(グループポリシー)によるPCへの設定配布

\- クライアントPCをドメインに参加させての動作確認

\- Entra ID / Azure とのハイブリッド構成の学習

