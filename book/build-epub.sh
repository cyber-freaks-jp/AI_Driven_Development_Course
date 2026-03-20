#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAGES_DIR="$SCRIPT_DIR/pages"
OUTPUT_DIR="$SCRIPT_DIR/output"
COMBINED="$SCRIPT_DIR/.build_combined.md"

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

# はじめに
standalone "はじめに.md"

# 第1章
chapter "第1章：AI駆動開発の世界へようこそ！"
section "もうエンジニアは不要_AI駆動開発とは.md"

# 第2章
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

# 第3章
chapter "第3章：AIとのコミュニケーション術"
section "プロンプトの基本とコツ.md"
section "コンテキストとは.md"
section "コンテキストウィンドウとは.md"
section "明確さは力なり.md"
section "タスク分割の技術.md"
section "ロールプレイの活用.md"
section "チェーンオブソート（思考連鎖）の活用.md"
section "ハルシネーションへの対策.md"

# 第4章
chapter "第4章：AIを活用した技術"
section "AIエージェントとは.md"
section "RAGとは.md"
section "MCP（ModelContextProtocol）とは.md"

# 第5章
chapter "第5章：実践！AI駆動開発入門"
section "主要なAI開発ツールとおすすめのエディタ.md"
section "Cursorの紹介.md"
section "ClaudeCodeの紹介.md"
section "git_worktreeでマルチタスクを並列化する.md"
section "ルールファイルの設定.md"
section "スキル（AgentSkills）とは.md"
section "サブエージェントとスキルの使い分け.md"
section "ハーネスエンジニアリング.md"

# 第6章
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

# 第7章
chapter "第7章：AI駆動開発のセキュリティ対策"
section "AIがもたらす3つのセキュリティリスク.md"
section "AIはサンドボックス環境で動かすのがオススメ.md"
section "リスクを考慮したLLMの選定方法.md"
section "AIツールのセキュリティ設定.md"
section "セキュリティチェックリスト.md"

# 第8章
chapter "第8章：エンジニアの未来"
section "今後の展望とエンジニアに求められるスキル.md"
section "AI駆動開発協会の活用.md"
section "生産性よりも大事なこと.md"

# あとがき
standalone "あとがき.md"

echo "=== Converting to EPUB3 ==="

COVER_ARGS=""
if [ -f "$SCRIPT_DIR/cover.png" ]; then
    COVER_ARGS="--epub-cover-image=$SCRIPT_DIR/cover.png"
fi

pandoc \
    "$COMBINED" \
    --metadata-file="$SCRIPT_DIR/epub-metadata.yaml" \
    --css="$SCRIPT_DIR/epub.css" \
    $COVER_ARGS \
    --toc \
    --toc-depth=2 \
    --split-level=1 \
    --resource-path="$PAGES_DIR:$PAGES_DIR/images" \
    -f markdown \
    -t epub3 \
    -o "$OUTPUT_DIR/ai-driven-development-guide.epub"

rm -f "$COMBINED"

FILE_SIZE=$(ls -lh "$OUTPUT_DIR/ai-driven-development-guide.epub" | awk '{print $5}')
echo "=== Done ==="
echo "Output: $OUTPUT_DIR/ai-driven-development-guide.epub"
echo "Size:   $FILE_SIZE"
