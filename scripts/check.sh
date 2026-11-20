#!/usr/bin/env bash
# =============================================================================
# プルリクエストを送る前のセルフチェック
#
#   使い方：このリポジトリのいちばん上のフォルダで，次のコマンドを実行します
#     bash scripts/check.sh
#
#   ファイルやGitの設定は，何も書きかえません（確認して表示するだけです）．
#   [NG]   ：プルリクエストを送る前に，必ず直してください
#   [注意] ：問題ないか，自分の目で確認してください
# =============================================================================

# このスクリプトがある scripts フォルダの1つ上（リポジトリのいちばん上）に移動する
cd "$(dirname "$0")/.." || exit 1

upstream_owner="tomohitoy"   # 大本のリポジトリの持ち主（教員）

ng_count=0    # [NG] の数
note_count=0  # [注意] の数

ok()   { printf '  [OK]   %s\n' "$1"; }
note() { printf '  [注意] %s\n' "$1"; note_count=$((note_count + 1)); }
ng()   { printf '  [NG]   %s\n' "$1"; ng_count=$((ng_count + 1)); }
hint() { printf '         -> %s\n' "$1"; }

lower() { printf '%s' "$1" | tr 'A-Z' 'a-z'; }

# 「- **ニックネーム**：たく」のような行から，「：」のあとの部分（たく）を取り出す．
#   $1：ファイル名   $2：項目の名前（ニックネーム，ひとこと など）
field() {
  grep -m 1 -E "^[-*[:space:]]*$2" "$1" \
    | tr -d '\r' \
    | sed -n -e 's/<!--.*-->//g' -e 's/：/:/' -e 's/^[^:]*:[*[:space:]]*//p' \
    | sed -e 's/[[:space:]]*$//'
}

# Gitのリポジトリの中でなければ，ここで終わり
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ng "ここはGitのリポジトリではありません"
  hint "git clone したフォルダ（oss-gallery-2026）の中で実行しましょう"
  exit 1
fi

# -----------------------------------------------------------------------------
echo "== 1. リポジトリとブランチ =="
# -----------------------------------------------------------------------------
# origin のURLから，リポジトリの持ち主（ユーザー名）を取り出す
origin_url=$(git config --get remote.origin.url)
owner=""
case "$origin_url" in
  git@github.com:*)
    owner=${origin_url#git@github.com:}
    owner=${owner%%/*}
    ;;
  https://github.com/*)
    owner=${origin_url#https://github.com/}
    owner=${owner%%/*}
    ;;
esac
echo "         origin：${origin_url:-（未設定）}"

if [ -z "$owner" ]; then
  ng "origin のURLから，ユーザー名を読み取れませんでした"
  hint "第8回 2-B を見て，自分の Fork を SSH のURLで clone し直しましょう"
elif [ "$(lower "$owner")" = "$upstream_owner" ]; then
  ng "origin が，教員のリポジトリ（${upstream_owner}）になっています．ここには push できません"
  hint "自分の Fork（自分のユーザー名/oss-gallery-2026）を clone し直しましょう（第8回 2-B）"
  owner=""
else
  ok "origin は，${owner} さんの Fork です"
  case "$origin_url" in
    https://*)
      note "origin が HTTPS のURLです．push のときに，ユーザー名を聞かれて止まるかもしれません"
      hint "git remote set-url origin git@github.com:${owner}/oss-gallery-2026.git で，SSH のURLに変えられます"
      ;;
  esac
fi

branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" = "main" ]; then
  ng "main ブランチにいます．プルリクエスト用のブランチで作業しましょう"
  hint "git switch -c add-my-site でブランチを作ると，いまの変更をそのまま持っていけます（第8回 3-A）"
else
  ok "${branch} ブランチにいます"
fi

# -----------------------------------------------------------------------------
echo ""
echo "== 2. 自分のファイル（members/ユーザー名.md） =="
# -----------------------------------------------------------------------------
my_file=""
if [ -n "$owner" ]; then
  # 大文字と小文字のちがいは気にせずに，自分のユーザー名のファイルを探す
  for f in members/*.md; do
    [ -e "$f" ] || continue
    if [ "$(lower "$(basename "$f" .md)")" = "$(lower "$owner")" ]; then
      my_file="$f"
    fi
  done

  if [ -z "$my_file" ]; then
    ng "members/${owner}.md がありません"
    hint "cp members/_template.md members/${owner}.md でコピーして作りましょう（第8回 3-C）"
    hint "ファイル名が「ユーザー名.md」のままになっていたり，.md.txt になっていたりしないかも確認しましょう"
  else
    ok "${my_file} があります"

    my_name=$(field "$my_file" 'ニックネーム')
    my_url=$(field "$my_file" 'サイトのURL')
    my_comment=$(field "$my_file" 'ひとこと')
    echo "         ニックネーム：${my_name:-（空）}"
    echo "         サイトのURL ：${my_url:-（空）}"
    echo "         ひとこと    ：${my_comment:-（空）}"

    if [ -z "$my_name" ]; then
      ng "ニックネームが書かれていません"
      hint "「- **ニックネーム**：」の「：」のあとに書きましょう（行の形は変えないでください）"
    else
      ok "ニックネームが書かれています"
    fi

    expected_url="https://$(lower "$owner").github.io/"
    my_url_norm=$(lower "$my_url")
    if [ "$my_url_norm" = "$expected_url" ] || [ "${my_url_norm}/" = "$expected_url" ]; then
      ok "サイトのURLが，自分のユーザー名のURLになっています"
    else
      ng "サイトのURLが ${expected_url} になっていません"
      hint "「ユーザー名」の部分を，自分のユーザー名に書きかえましょう"
    fi

    if [ -z "$my_comment" ]; then
      ng "ひとことが書かれていません"
      hint "「- **ひとこと**：」の「：」のあとに，サイトの紹介を1〜2文で書きましょう"
    elif [ "$(printf '%s' "$my_comment" | wc -c)" -gt 300 ]; then
      note "ひとことが長めです．一覧のページでは，途中までしか表示されません（100文字以内が目安です）"
    else
      ok "ひとことが書かれています"
    fi

    # メールアドレスのような文字列
    emails=$(grep -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$my_file" | sort -u)
    if [ -n "$emails" ]; then
      note "メールアドレスのような文字列があります．公開してよいものか確認しましょう"
      printf '%s\n' "$emails" | sed 's/^/           /'
    fi

    # 電話番号のような文字列（090-1234-5678，03-1234-5678，09012345678 など）
    phones=$(grep -oE '0[0-9]{1,4}-[0-9]{1,4}-[0-9]{3,4}|0[789]0[0-9]{8}' "$my_file" | sort -u)
    if [ -n "$phones" ]; then
      note "電話番号のような文字列があります．公開してよいものか確認しましょう"
      printf '%s\n' "$phones" | sed 's/^/           /'
    fi
  fi
else
  note "ユーザー名がわからないので，ファイルの確認を飛ばしました（1. の [NG] を先に直しましょう）"
fi

# -----------------------------------------------------------------------------
echo ""
echo "== 3. 変更したファイル（プルリクエストに入るもの） =="
# -----------------------------------------------------------------------------
if git rev-parse --verify -q origin/main >/dev/null; then
  # origin/main（Fork したときの状態）とくらべて，ちがっているファイルの一覧
  changed=$( {
    git -c core.quotepath=false diff --name-only origin/main
    git -c core.quotepath=false ls-files --others --exclude-standard
  } | sort -u )

  if [ -z "$changed" ]; then
    note "まだ何も変更していません"
  else
    others=$(printf '%s\n' "$changed" | grep -vxF "${my_file:-（なし）}")
    if [ -n "$my_file" ] && [ -z "$others" ]; then
      ok "変更したのは ${my_file} の1ファイルだけです"
    elif [ -n "$others" ]; then
      ng "自分のファイルのほかにも，変更されているファイルがあります"
      printf '%s\n' "$others" | sed 's/^/           /'
      hint "追加するのは「members/自分のユーザー名.md」の1ファイルだけです．第8回の「困ったときは」を見て，元に戻しましょう"
    fi
  fi
else
  note "origin/main が見つからないので，変更したファイルの確認を飛ばしました"
fi

# -----------------------------------------------------------------------------
echo ""
echo "== 4. コミットに記録される名前とメールアドレス（全世界から見えます） =="
# -----------------------------------------------------------------------------
name=$(git config user.name)
email=$(git config user.email)
echo "         名前：${name:-（未設定）}"
echo "         メール：${email:-（未設定）}"

if [ -z "$name" ]; then
  ng "名前（user.name）が設定されていません"
  hint "第8回 2-C を見て設定しましょう"
elif printf '%s' "$name" | LC_ALL=C grep -q '[^ -~]'; then
  note "名前に日本語が入っています．本名のフルネームなら，ユーザー名に変えることをおすすめします（第8回 2-C）"
else
  ok "名前が設定されています（公開してよい名前か，上の表示を確認しましょう）"
fi

case "$email" in
  "")
    ng "メールアドレス（user.email）が設定されていません"
    hint "第8回 2-C を見て，GitHub の noreply アドレスを設定しましょう"
    ;;
  *@users.noreply.github.com)
    ok "メールアドレスは GitHub の noreply アドレスです"
    ;;
  *)
    note "メールアドレスが GitHub の noreply アドレスではありません．公開してよいアドレスか確認しましょう"
    hint "第8回 2-C を見て，noreply アドレスに変えることをおすすめします"
    ;;
esac

# 自分が作ったコミットに，noreply 以外のアドレスが記録されていないか
if git rev-parse --verify -q origin/main >/dev/null; then
  other_emails=$(git log --format='%ae' origin/main..HEAD | grep -v '@users.noreply.github.com$' | sort -u)
  if [ -n "$other_emails" ]; then
    note "自分が作ったコミットに，次のアドレスが記録されています"
    printf '%s\n' "$other_emails" | sed 's/^/           /'
    if [ "$(git rev-list --count origin/main..HEAD)" -eq 1 ]; then
      hint "2-C の設定のあとで，git commit --amend --reset-author --no-edit を実行すると，直前のコミットを作り直せます"
    else
      # コミットが2つ以上あるときは，--amend では直前の1つしか直らない
      hint "2-C の設定のあとで，次のコマンドを実行すると，自分が作ったコミットをまとめて作り直せます"
      hint "git rebase origin/main --exec \"git commit --amend --reset-author --no-edit\""
    fi
  fi
fi

# -----------------------------------------------------------------------------
echo ""
echo "== 5. Git の状態 =="
# -----------------------------------------------------------------------------
changes=$(git -c core.quotepath=false status --porcelain)
if [ -n "$changes" ]; then
  note "まだコミットしていない変更があります"
  printf '%s\n' "$changes" | sed 's/^/           /'
  hint "git add ファイル名 → git commit -m \"メッセージ\" でコミットしましょう"
fi

if git rev-parse --verify -q origin/main >/dev/null; then
  ahead=$(git rev-list --count origin/main..HEAD)
  if [ "$ahead" -eq 0 ]; then
    if [ -z "$changes" ]; then
      note "まだコミットがありません"
    fi
  elif [ "$branch" != "main" ]; then
    # GitHub（origin）に，同じ名前のブランチがあって，同じコミットを指しているか
    remote_head=$(git rev-parse --verify -q "origin/${branch}")
    if [ "$remote_head" = "$(git rev-parse HEAD)" ]; then
      ok "コミットは ${ahead} 個で，すべて push 済みです．プルリクエストを作りましょう（作成済みなら，自動で更新されています）"
    elif [ -n "$remote_head" ] && ! git merge-base --is-ancestor "$remote_head" HEAD; then
      # push したあとでコミットを作り直す（--amend など）と，GitHub のブランチと枝分かれする
      note "push したあとで，コミットを作り直しています．ふつうの git push では送れません"
      hint "git push --force-with-lease origin ${branch} で，GitHub のブランチを，作り直したコミットに置きかえましょう"
    else
      note "まだ push していないコミットがあります"
      hint "git push origin ${branch} で GitHub に送りましょう"
    fi
  fi
fi

# -----------------------------------------------------------------------------
echo ""
echo "== 結果 =="
# -----------------------------------------------------------------------------
if [ "$ng_count" -gt 0 ]; then
  echo "  [NG] が ${ng_count} 個あります．直してから push しましょう"
  exit 1
elif [ "$note_count" -gt 0 ]; then
  echo "  [NG] はありません．[注意] の ${note_count} 個を確認してから進みましょう"
else
  echo "  すべてOKです！"
fi
echo "  ※ このチェックは目安です．最後は，GitHubの「Files changed」で自分の目で確認しましょう"
