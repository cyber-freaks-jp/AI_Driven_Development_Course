#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAGES_DIR="$SCRIPT_DIR/pages"
OUTPUT_DIR="$SCRIPT_DIR/output"
COMBINED="$SCRIPT_DIR/.build_combined.md"
HTML_FILE="$PAGES_DIR/.build_combined.html"

mkdir -p "$OUTPUT_DIR"
rm -f "$COMBINED"

shift_headings() {
    awk '
    /^```/ { in_code = !in_code }
    !in_code && /^##### / { sub(/^##### /, "###### "); print; next }
    !in_code && /^#### /  { sub(/^#### /,  "##### ");  print; next }
    !in_code && /^### /   { sub(/^### /,   "#### ");   print; next }
    !in_code && /^## /    { sub(/^## /,    "### ");    print; next }
    !in_code && /^# /     { sub(/^# /,     "## ");     print; next }
    { print }
    ' "$1"
}

section() {
    local file="$PAGES_DIR/$1"
    if [ ! -f "$file" ]; then
        echo "WARNING: File not found: $file" >&2
        return
    fi
    shift_headings "$file" >> "$COMBINED"
    printf "\n\n" >> "$COMBINED"
}

standalone() {
    local file="$PAGES_DIR/$1"
    if [ ! -f "$file" ]; then
        echo "WARNING: File not found: $file" >&2
        return
    fi
    cat "$file" >> "$COMBINED"
    printf "\n\n" >> "$COMBINED"
}

chapter() {
    printf "# %s\n\n" "$1" >> "$COMBINED"
}

phase() {
    {
        echo "---"
        echo ""
        echo "**$1**"
        echo ""
    } >> "$COMBINED"
}

echo "=== Building combined markdown ==="

standalone "はじめに.md"
chapter "第1章：AI駆動開発の世界へようこそ！"
section "もうエンジニアは不要_AI駆動開発とは.md"
chapter "第2章：AIの基本知識"
section "そもそもAIって何？.md"
section "AIの種類.md"
section "機械学習とは.md"
section "ディープラーニングとは.md"
section "生成AIとは.md"
section "LLMとは.md"
section "モデルとは.md"
section "クラウドLLMとローカルLLM.md"
section "トークンとは.md"
section "LLMの料金とトークンの関係.md"
section "AIエンジニアとAI駆動開発エンジニアの違い.md"
section "AI技術のまとめ.md"
chapter "第3章：AIとのコミュニケーション術"
section "プロンプトの基本とコツ.md"
section "コンテキストとは.md"
section "コンテキストウィンドウとは.md"
section "明確さは力なり.md"
section "タスク分割の技術.md"
section "ロールプレイの活用.md"
section "チェーンオブソート（思考連鎖）の活用.md"
section "ハルシネーションへの対策.md"
chapter "第4章：AIを活用した技術"
section "AIエージェントとは.md"
section "RAGとは.md"
section "MCP（ModelContextProtocol）とは.md"
chapter "第5章：実践！AI駆動開発入門"
section "主要なAI開発ツールとおすすめのエディタ.md"
section "Cursorの紹介.md"
section "ClaudeCodeの紹介.md"
section "git_worktreeでマルチタスクを並列化する.md"
section "ルールファイルの設定.md"
section "スキル（AgentSkills）とは.md"
section "サブエージェントとスキルの使い分け.md"
section "ハーネスエンジニアリング.md"
chapter "第6章：AIを活用した開発フロー"
phase "要件定義フェーズ"
section "AIで要件定義書を作成する.md"
phase "実装フェーズ"
section "AIで実装を自動化する.md"
section "コードレビューの効率化.md"
phase "テストフェーズ"
section "AIでテストする.md"
section "シナリオテスト仕様書の自動生成.md"
phase "保守フェーズ"
section "本番環境でのバグ調査.md"
phase "よくある失敗と解決策"
section "よくある失敗と解決策.md"
chapter "第7章：AI駆動開発のセキュリティ対策"
section "AIがもたらす3つのセキュリティリスク.md"
section "AIはサンドボックス環境で動かすのがオススメ.md"
section "リスクを考慮したLLMの選定方法.md"
section "AIツールのセキュリティ設定.md"
section "セキュリティチェックリスト.md"
chapter "第8章：エンジニアの未来"
section "今後の展望とエンジニアに求められるスキル.md"
section "AI駆動開発協会の活用.md"
section "生産性よりも大事なこと.md"
standalone "あとがき.md"

echo "=== Converting to HTML ==="

pandoc \
    "$COMBINED" \
    --standalone \
    --resource-path="$PAGES_DIR:$PAGES_DIR/images" \
    -f markdown \
    -t html5 \
    -o "$HTML_FILE"

echo "=== Converting to A5 PDF ==="

weasyprint \
    "$HTML_FILE" \
    "$OUTPUT_DIR/a5-page-count.pdf" \
    --stylesheet <(cat <<'CSS'
/* ============================================
   A5書籍用CSS（148mm × 210mm）
   目標：本文8pt / 1行約38文字 / ノド25mm
   ============================================ */

/* --- ページ設定 --- */
@page {
    size: 148mm 210mm;   /* A5 */
    margin: 18mm 15mm 18mm 25mm;  /* 天18 小口15 地18 ノド25 */
}
@page :left {
    margin: 18mm 25mm 18mm 15mm;  /* 左ページ：ノドが右側 */
}
@page :right {
    margin: 18mm 15mm 18mm 25mm;  /* 右ページ：ノドが左側 */
}

/* --- 本文 --- */
body {
    font-family: "Hiragino Mincho ProN", "Yu Mincho", serif;
    font-size: 8pt;
    line-height: 1.8;
    max-width: none;
    margin: 0;
    padding: 0;
    color: #222;
    text-align: justify;
    orphans: 2;
    widows: 2;
}
p {
    margin: 0 0 0.6em 0;
    text-indent: 0;
}

/* --- 見出し --- */
h1 {
    font-size: 14pt;
    font-weight: bold;
    page-break-before: always;
    margin-top: 40mm;
    margin-bottom: 8mm;
    line-height: 1.3;
}
h1:first-of-type {
    page-break-before: avoid;
}
h2 {
    font-size: 11pt;
    font-weight: bold;
    margin-top: 6mm;
    margin-bottom: 3mm;
    line-height: 1.4;
    page-break-after: avoid;
}
h3 {
    font-size: 9.5pt;
    font-weight: bold;
    margin-top: 4mm;
    margin-bottom: 2mm;
    line-height: 1.4;
    page-break-after: avoid;
}
h4 {
    font-size: 8.5pt;
    font-weight: bold;
    margin-top: 3mm;
    margin-bottom: 1.5mm;
    line-height: 1.4;
    page-break-after: avoid;
}

/* --- コードブロック --- */
pre {
    font-family: "Menlo", "Courier New", monospace;
    font-size: 6.5pt;
    line-height: 1.5;
    overflow-wrap: break-word;
    white-space: pre-wrap;
    background: #f5f5f5;
    border: 0.5pt solid #ddd;
    padding: 2mm;
    margin: 2mm 0 3mm 0;
    page-break-inside: avoid;
}
code {
    font-family: "Menlo", "Courier New", monospace;
    font-size: 7pt;
}

/* --- インラインコード --- */
p code, li code, td code {
    background: #f0f0f0;
    padding: 0 1px;
}

/* --- 表 --- */
table {
    font-size: 7pt;
    line-height: 1.4;
    border-collapse: collapse;
    width: 100%;
    margin: 2mm 0 3mm 0;
    page-break-inside: avoid;
}
th, td {
    border: 0.5pt solid #999;
    padding: 1.5mm 2mm;
    text-align: left;
    vertical-align: top;
}
th {
    background: #f0f0f0;
    font-weight: bold;
}

/* --- リスト --- */
ul, ol {
    margin: 1mm 0 2mm 0;
    padding-left: 5mm;
}
li {
    margin-bottom: 0.8mm;
}

/* --- 画像 --- */
img {
    max-width: 100%;
    height: auto;
    display: block;
    margin: 3mm auto;
}
figcaption {
    font-size: 6.5pt;
    color: #666;
    text-align: center;
    margin-top: 1mm;
    margin-bottom: 3mm;
}

/* --- 水平線（フェーズ区切り） --- */
hr {
    border: none;
    border-top: 0.5pt solid #ccc;
    margin: 4mm 0;
}

/* --- 太字・強調 --- */
strong {
    font-weight: bold;
}

/* --- ブロック引用 --- */
blockquote {
    margin: 2mm 0 2mm 4mm;
    padding-left: 3mm;
    border-left: 1.5pt solid #ccc;
    font-size: 7.5pt;
    color: #444;
}
CSS
)

rm -f "$COMBINED" "$HTML_FILE"

# Count pages
PAGE_COUNT=$(python3 -c "
import subprocess, re
r = subprocess.run(['mdls', '-name', 'kMDItemNumberOfPages', '$OUTPUT_DIR/a5-page-count.pdf'], capture_output=True, text=True)
m = re.search(r'(\d+)', r.stdout)
print(m.group(1) if m else 'unknown')
")

FILE_SIZE=$(ls -lh "$OUTPUT_DIR/a5-page-count.pdf" | awk '{print $5}')
echo "=== Done ==="
echo "Output: $OUTPUT_DIR/a5-page-count.pdf"
echo "Size:   $FILE_SIZE"
echo "Pages:  $PAGE_COUNT"
