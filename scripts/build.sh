#!/usr/bin/env bash
# =============================================================================
# 一覧ページを作る
#
#   使い方：このリポジトリのいちばん上のフォルダで，次のコマンドを実行します
#     bash scripts/build.sh
#
#   members フォルダの「ユーザー名.md」を1つずつ読んで，_site/index.html を作ります．
#   main ブランチに変更が入る（PRがマージされる）たびに，GitHub Actions が
#   このスクリプトを実行して，できたページを GitHub Pages で公開します．
#   （.github/workflows/pages.yml を参照）
#
#   書き方がまちがっているファイルは，一覧に載せずに読み飛ばします．
#   （1人のまちがいで，ページ全体がこわれないようにするためです）
# =============================================================================

# このスクリプトがある scripts フォルダの1つ上（リポジトリのいちばん上）に移動する
cd "$(dirname "$0")/.." || exit 1

out_dir="_site"                 # できたページを置くフォルダ（.gitignore に入れてあります）
out_file="$out_dir/index.html"
cards_file=$(mktemp)            # カード（1人ぶんのHTML）を，いったんためておくファイル
trap 'rm -f "$cards_file"' EXIT

count=0    # 一覧に載せた人数
skipped=0  # 読み飛ばしたファイルの数

# HTMLで特別な意味をもつ文字（& < > " '）を，ただの文字として表示されるように置きかえる．
# これをしないと，ファイルに書かれたHTMLのタグが，そのままページに入りこんでしまう．
escape_html() {
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&#39;/g"
}

# 「- **ニックネーム**：たく」のような行から，「：」のあとの部分（たく）を取り出す．
#   $1：ファイル名   $2：項目の名前（ニックネーム，ひとこと など）
field() {
  grep -m 1 -E "^[-*[:space:]]*$2" "$1" \
    | tr -d '\r' \
    | sed -n -e 's/<!--.*-->//g' -e 's/：/:/' -e 's/^[^:]*:[*[:space:]]*//p' \
    | sed -e 's/[[:space:]]*$//'
}

# members フォルダのファイルを，名前の順（大文字と小文字は区別しない）に読む
while IFS= read -r file; do
  user=$(basename "$file" .md)

  # README.md と，_ で始まるファイル（_template.md）は，説明用なので読み飛ばす
  case "$user" in
    README | _*) continue ;;
  esac

  # ファイル名が，GitHubのユーザー名として正しい形（英数字とハイフン，39文字まで）か
  if ! printf '%s' "$user" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$'; then
    echo "[読み飛ばし] $file：ファイル名が，GitHubのユーザー名の形になっていません"
    skipped=$((skipped + 1))
    continue
  fi

  name=$(field "$file" 'ニックネーム')
  comment=$(field "$file" 'ひとこと')

  if [ -z "$name" ]; then
    echo "[読み飛ばし] $file：ニックネームが書かれていません"
    skipped=$((skipped + 1))
    continue
  fi

  # サイトのURLは，ファイルの中身ではなく，ファイル名（＝ユーザー名）から作る．
  # ファイルに何が書かれていても，リンク先は必ず「そのユーザーの GitHub Pages」になる．
  user_lower=$(printf '%s' "$user" | tr 'A-Z' 'a-z')
  url="https://${user_lower}.github.io/"

  name_html=$(printf '%s' "$name" | escape_html)
  comment_html=$(printf '%s' "$comment" | escape_html)

  {
    echo "      <li>"
    echo "        <a class=\"card\" href=\"${url}\" rel=\"noopener\">"
    echo "          <span class=\"name\">${name_html}</span>"
    echo "          <span class=\"user\">@${user}</span>"
    if [ -n "$comment_html" ]; then
      echo "          <span class=\"comment\">${comment_html}</span>"
    fi
    echo "          <span class=\"go\">サイトを見る →</span>"
    echo "        </a>"
    echo "      </li>"
  } >> "$cards_file"

  count=$((count + 1))
done < <(find members -maxdepth 1 -type f -name '*.md' | LC_ALL=C sort -f)

# ページを作った日時（日本時間）
built_at=$(TZ=JST-9 date '+%Y-%m-%d %H:%M')

mkdir -p "$out_dir"

# ----- ここから，ページの上半分 -----
cat > "$out_file" <<'HTML'
<!DOCTYPE html>
<!-- このファイルは，scripts/build.sh が members フォルダから自動で作ったものです．直接書きかえても，次に作り直すと消えます． -->
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <!-- 検索エンジンへのお願い：このページを検索結果に載せないでください -->
  <meta name="robots" content="noindex">
  <title>みんなのサイト 2026</title>
  <style>
    /* ===== 色の設定 ===== */
    :root {
      --main-color: #2e7d32;  /* メインの色（見出し・リンク） */
      --bg-color: #f5f8f5;    /* ページの背景の色 */
      --card-color: #ffffff;  /* カードの背景の色 */
      --text-color: #222222;  /* 文字の色 */
      --sub-color: #666666;   /* 補足の文字の色 */
      --line-color: #dfe6df;  /* 区切り線の色 */
    }

    /* パソコンやスマートフォンがダークモードのときの色 */
    @media (prefers-color-scheme: dark) {
      :root {
        --main-color: #81c784;
        --bg-color: #121512;
        --card-color: #1e231e;
        --text-color: #e8ece8;
        --sub-color: #a0a8a0;
        --line-color: #2f362f;
      }
    }

    /* ページ全体 */
    body {
      margin: 0;
      padding: 32px 16px 48px;
      font-family: "Hiragino Sans", "Yu Gothic", "Meiryo", sans-serif;
      line-height: 1.8;
      color: var(--text-color);
      background: var(--bg-color);
    }

    /* 中身の横幅をそろえる */
    header, main, footer {
      max-width: 960px;
      margin: 0 auto;
    }

    h1 {
      margin: 0;
      font-size: clamp(1.5rem, 7vw, 2rem);  /* スマートフォンでは少し小さくする */
      line-height: 1.4;
      color: var(--main-color);
    }

    /* 補足の小さな文字 */
    .sub {
      margin: 4px 0 0;
      font-size: 0.9rem;
      color: var(--sub-color);
    }

    /* 「○人のサイト」のバッジ */
    .badge {
      display: inline-block;
      margin: 16px 0 24px;
      padding: 2px 14px;
      font-size: 0.9rem;
      font-weight: bold;
      color: var(--card-color);
      background: var(--main-color);
      border-radius: 999px;
    }

    /* カードを，画面の幅に合わせて何列かに並べる */
    .cards {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
      gap: 16px;
      margin: 0;
      padding: 0;
      list-style: none;
    }

    /* 1人ぶんのカード（カード全体がリンクになっている） */
    .card {
      display: flex;
      flex-direction: column;
      height: 100%;
      padding: 18px 20px;
      box-sizing: border-box;
      color: inherit;
      text-decoration: none;
      background: var(--card-color);
      border-top: 4px solid var(--main-color);
      border-radius: 10px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.07);
      overflow-wrap: anywhere;  /* 長い英数字も，カードからはみ出さないように折り返す */
      transition: transform 0.15s, box-shadow 0.15s;
    }
    .card:hover, .card:focus-visible {
      transform: translateY(-2px);
      box-shadow: 0 6px 18px rgba(0, 0, 0, 0.14);
    }

    /* ニックネーム */
    .name {
      font-size: 1.15rem;
      font-weight: bold;
      line-height: 1.5;
    }

    /* GitHubのユーザー名 */
    .user {
      font-family: "SFMono-Regular", Consolas, monospace;
      font-size: 0.82rem;
      color: var(--sub-color);
    }

    /* ひとこと（長いときは4行まで表示する） */
    .comment {
      display: -webkit-box;
      margin-top: 10px;
      font-size: 0.92rem;
      line-height: 1.7;
      -webkit-box-orient: vertical;
      -webkit-line-clamp: 4;
      line-clamp: 4;
      overflow: hidden;
    }

    /* 「サイトを見る」 */
    .go {
      margin-top: auto;      /* カードのいちばん下に寄せる */
      padding-top: 12px;
      font-size: 0.88rem;
      font-weight: bold;
      color: var(--main-color);
    }

    /* まだ誰も載っていないときの表示 */
    .empty {
      padding: 32px 20px;
      text-align: center;
      color: var(--sub-color);
      background: var(--card-color);
      border: 1px dashed var(--line-color);
      border-radius: 10px;
    }

    /* いちばん下の小さな文字 */
    footer {
      margin-top: 40px;
      padding-top: 12px;
      font-size: 0.8rem;
      color: var(--sub-color);
      border-top: 1px solid var(--line-color);
    }
    a {
      color: var(--main-color);
    }
  </style>
</head>
<body>
  <header>
    <h1>みんなのサイト 2026</h1>
    <p class="sub">拓殖大学工学部『オープンソースソフトウェア』2026年度の受講生が，GitHub Pages で公開したサイトの一覧です．</p>
HTML

# ----- ここから，人数とカード -----
{
  echo "    <p class=\"badge\">${count} 人のサイト</p>"
  echo "  </header>"
  echo ""
  echo "  <main>"
  if [ "$count" -gt 0 ]; then
    echo "    <ul class=\"cards\">"
    cat "$cards_file"
    echo "    </ul>"
  else
    echo "    <p class=\"empty\">まだ誰も載っていません．最初の1人になりましょう！</p>"
  fi
  echo "  </main>"
  echo ""
  echo "  <footer>"
  echo "    この一覧に自分のサイトを載せるには，プルリクエストを送ります（<a href=\"https://github.com/tomohitoy/oss-practice-2026/blob/main-08/chap08/README.md\">第8回の資料</a>）．<br>"
  echo "    <a href=\"https://github.com/tomohitoy/oss-gallery-2026\">このページのリポジトリ（tomohitoy/oss-gallery-2026）</a>"
  echo "    ・最終更新：${built_at}（日本時間）"
  echo "  </footer>"
  echo "</body>"
  echo "</html>"
} >> "$out_file"

echo "${out_file} を作りました（${count} 人．読み飛ばし ${skipped} 個）"
