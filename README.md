# oss-gallery-2026
拓殖大学工学部　2026年度『オープンソースソフトウェア』の受講生が，GitHub Pages で公開したサイトの一覧です．

**一覧ページ**：https://tomohitoy.github.io/oss-gallery-2026/

このリポジトリの `members` フォルダに，自分のファイルを1つ追加する**プルリクエスト（PR）** を送ると，一覧ページに自分のサイトが載ります．
くわしい手順は，[第8回の資料](https://github.com/tomohitoy/oss-practice-2026/blob/main-08/chap08/README.md)を見てください．

## 参加のしかた（プルリクエストの送り方）
1. このリポジトリを **Fork** する（右上の **Fork** ボタン）
2. 自分の Fork を，SSH のURLで `git clone` する
3. ブランチを作る（`git switch -c add-my-site`）
4. `members/_template.md` をコピーして，`members/自分のユーザー名.md` を作って書く（[書き方](./members/README.md)）
5. `bash scripts/check.sh` で，セルフチェックをする
6. `git add` → `git commit` → `git push origin add-my-site` する
7. GitHubの画面で，このリポジトリ（`tomohitoy/oss-gallery-2026`）の `main` に向けて，プルリクエストを作る

マージされると，数分で一覧ページに反映されます．

## 決まりごと
- 追加するのは，**`members/自分のユーザー名.md` の1ファイルだけ**です
- このリポジトリは Public です．ファイルの中身・コミットの履歴・コミットに記録された名前とメールアドレス・プルリクエストの文章は，誰でも見ることができます．**本名のフルネーム・学籍番号・メールアドレスなど，公開したくない情報は書かないでください**
- プルリクエストやコメントでは，相手への敬意をもって，ていねいな言葉でやり取りしましょう

## ファイルの役割

| ファイル | 役割 |
| --- | --- |
| `members/ユーザー名.md` | 1人につき1つのファイル．ニックネーム・サイトのURL・ひとことを書きます |
| `members/_template.md` | 自分のファイルを作るときの，コピー元のひな形 |
| `members/README.md` | ファイルの書き方の説明 |
| `scripts/check.sh` | プルリクエストを送る前のセルフチェック（下の説明を参照） |
| `scripts/build.sh` | `members` フォルダから，一覧ページ（`_site/index.html`）を作るスクリプト |
| `.github/pull_request_template.md` | プルリクエストの本文のひな形．プルリクエストを作る画面に，自動で入ります |
| `.github/workflows/pages.yml` | `main` に変更が入るたびに `scripts/build.sh` を動かして，一覧ページを公開する設定（GitHub Actions） |
| `.gitignore` | Gitで管理しないファイル（`.DS_Store` や，作った一覧ページの `_site` フォルダ）の一覧 |
| `.gitattributes` | Windows でも，スクリプトの改行コードが変わらないようにする設定 |
| `LICENSE` | ライセンス（MITライセンス） |

## セルフチェック（scripts/check.sh）
リポジトリのいちばん上のフォルダで，次のコマンドを実行します．
ファイルやGitの設定は何も書きかえず，確認した結果を表示するだけです．

```bash
bash scripts/check.sh
```

表示例：
```
== 1. リポジトリとブランチ ==
         origin：git@github.com:taku-shoku/oss-gallery-2026.git
  [OK]   origin は，taku-shoku さんの Fork です
  [OK]   add-my-site ブランチにいます

== 2. 自分のファイル（members/ユーザー名.md） ==
  [OK]   members/taku-shoku.md があります
         ニックネーム：たく
         サイトのURL ：https://taku-shoku.github.io/
         ひとこと    ：週末はだいたい自転車に乗っています．好きな色の緑でまとめました．
  [OK]   ニックネームが書かれています
  [OK]   サイトのURLが，自分のユーザー名のURLになっています
  [OK]   ひとことが書かれています

== 3. 変更したファイル（プルリクエストに入るもの） ==
  [OK]   変更したのは members/taku-shoku.md の1ファイルだけです

== 4. コミットに記録される名前とメールアドレス（全世界から見えます） ==
         名前：taku-shoku
         メール：12345678+taku-shoku@users.noreply.github.com
  [OK]   名前が設定されています（公開してよい名前か，上の表示を確認しましょう）
  [OK]   メールアドレスは GitHub の noreply アドレスです

== 5. Git の状態 ==
  [注意] まだ push していないコミットがあります
         -> git push origin add-my-site で GitHub に送りましょう

== 結果 ==
  [NG] はありません．[注意] の 1 個を確認してから進みましょう
  ※ このチェックは目安です．最後は，GitHubの「Files changed」で自分の目で確認しましょう
```

- **[NG]**：プルリクエストを送る前に，必ず直してください
- **[注意]**：問題ないか，自分の目で確認してください

## 一覧ページの仕組み
`main` ブランチに変更が入る（プルリクエストがマージされる）たびに，GitHub Actions が `scripts/build.sh` を実行します．
`scripts/build.sh` は，`members` フォルダのファイルを1つずつ読んで，1人ぶんずつカードにした `_site/index.html` を作ります．

- リンク先は，ファイルの中身ではなく**ファイル名（ユーザー名）** から `https://ユーザー名.github.io/` として作ります
- 書き方がまちがっているファイルは，一覧に載せずに読み飛ばします（1人のまちがいで，ページ全体がこわれないようにするためです）

手元でも，同じページを作って見ることができます．

```bash
bash scripts/build.sh
```

Macの場合：
```bash
open _site/index.html
```

Windows（Git Bash）の場合：
```bash
start _site/index.html
```

## メンテナー（教員）向け
- **はじめに1回だけ**：**Settings → Pages → Build and deployment** の **Source** を **GitHub Actions** にします．そのあと，**Actions** タブの「一覧ページを公開する」を **Run workflow** で1回実行すると，一覧ページが公開されます
- **マージの前に見るところ**（**Files changed** タブ）：追加されているのが `members/PRを送った人のユーザー名.md` の1ファイルだけか，公開してはいけない情報が書かれていないか
- 1人1ファイルなので，プルリクエストどうしがぶつかる（コンフリクトする）ことはありません．どの順番でマージしてもかまいません
- 続けてマージしても，公開の処理は順番に実行されます．反映されないときは，**Actions** タブで「一覧ページを公開する」が緑のチェックになっているか確認します
