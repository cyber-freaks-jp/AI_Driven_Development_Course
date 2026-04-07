#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAGES_DIR="$SCRIPT_DIR/pages"
OUTPUT_DIR="$SCRIPT_DIR/output"
COMBINED="$SCRIPT_DIR/.build_combined.md"
REFERENCE_DOCX="$SCRIPT_DIR/.reference-a5.docx"

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

# === Step 1: Generate A5 reference DOCX with Pandoc ===
echo "=== Creating A5 reference DOCX ==="

# Create a minimal markdown to generate a reference docx, then patch it with python
TEMP_MD=$(mktemp /tmp/ref_XXXXXX.md)
echo "Placeholder" > "$TEMP_MD"
pandoc "$TEMP_MD" -o "$REFERENCE_DOCX" -t docx
rm -f "$TEMP_MD"

# Patch the reference DOCX to set A5 page size and Japanese fonts
python3 - "$REFERENCE_DOCX" <<'PYTHON'
import sys
import zipfile
import xml.etree.ElementTree as ET
import shutil
import os
import tempfile

docx_path = sys.argv[1]

# OOXML namespaces
NS = {
    'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
    'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
}
for prefix, uri in NS.items():
    ET.register_namespace(prefix, uri)

# Also register other common namespaces to prevent ns0/ns1 pollution
OTHER_NS = {
    'mc': 'http://schemas.openxmlformats.org/markup-compatibility/2006',
    'o': 'urn:schemas-microsoft-com:office:office',
    'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
    'm': 'http://schemas.openxmlformats.org/officeDocument/2006/math',
    'v': 'urn:schemas-microsoft-com:vml',
    'wp': 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
    'w10': 'urn:schemas-microsoft-com:office:word',
    'wne': 'http://schemas.microsoft.com/office/word/2006/wordml',
    'sl': 'http://schemas.openxmlformats.org/schemaLibrary/2006/main',
    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
    'pic': 'http://schemas.openxmlformats.org/drawingml/2006/picture',
    'c': 'http://schemas.openxmlformats.org/drawingml/2006/chart',
    'lc': 'http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas',
    'dgm': 'http://schemas.openxmlformats.org/drawingml/2006/diagram',
    'wps': 'http://schemas.microsoft.com/office/word/2010/wordprocessingShape',
    'wpg': 'http://schemas.microsoft.com/office/word/2010/wordprocessingGroup',
    'w14': 'http://schemas.microsoft.com/office/word/2010/wordml',
    'w15': 'http://schemas.microsoft.com/office/word/2012/wordml',
}
for prefix, uri in OTHER_NS.items():
    ET.register_namespace(prefix, uri)

W = NS['w']

def mm_to_twips(mm):
    """Convert mm to twips (1mm = 56.7 twips)"""
    return int(mm * 56.7)

def pt_to_half_pt(pt):
    """Convert points to half-points for w:sz"""
    return int(pt * 2)

# Extract, modify, repack
tmp_dir = tempfile.mkdtemp()
with zipfile.ZipFile(docx_path, 'r') as z:
    z.extractall(tmp_dir)

# --- Modify word/document.xml (page size) ---
doc_xml_path = os.path.join(tmp_dir, 'word', 'document.xml')
tree = ET.parse(doc_xml_path)
root = tree.getroot()

# Set page size to A5 (148mm x 210mm)
for sect_pr in root.iter(f'{{{W}}}sectPr'):
    # Remove existing pgSz and pgMar
    for tag in ['pgSz', 'pgMar']:
        for elem in sect_pr.findall(f'{{{W}}}{tag}'):
            sect_pr.remove(elem)

    # Add A5 page size
    pg_sz = ET.SubElement(sect_pr, f'{{{W}}}pgSz')
    pg_sz.set(f'{{{W}}}w', str(mm_to_twips(148)))
    pg_sz.set(f'{{{W}}}h', str(mm_to_twips(210)))

    # Add margins: top=18mm, bottom=18mm, left=25mm(ノド), right=15mm(小口)
    pg_mar = ET.SubElement(sect_pr, f'{{{W}}}pgMar')
    pg_mar.set(f'{{{W}}}top', str(mm_to_twips(18)))
    pg_mar.set(f'{{{W}}}bottom', str(mm_to_twips(18)))
    pg_mar.set(f'{{{W}}}left', str(mm_to_twips(25)))
    pg_mar.set(f'{{{W}}}right', str(mm_to_twips(15)))
    pg_mar.set(f'{{{W}}}header', str(mm_to_twips(10)))
    pg_mar.set(f'{{{W}}}footer', str(mm_to_twips(10)))
    pg_mar.set(f'{{{W}}}gutter', '0')

tree.write(doc_xml_path, xml_declaration=True, encoding='UTF-8')

# --- Modify word/styles.xml (fonts and sizes) ---
styles_xml_path = os.path.join(tmp_dir, 'word', 'styles.xml')
tree = ET.parse(styles_xml_path)
root = tree.getroot()

def set_style_font_and_size(style_elem, font_name, size_pt, bold=False, color=None):
    """Set font, size, bold, color for a style element."""
    # Set run properties
    rpr = style_elem.find(f'{{{W}}}rPr')
    if rpr is None:
        rpr = ET.SubElement(style_elem, f'{{{W}}}rPr')

    # Font
    for rfonts in rpr.findall(f'{{{W}}}rFonts'):
        rpr.remove(rfonts)
    rfonts = ET.SubElement(rpr, f'{{{W}}}rFonts')
    rfonts.set(f'{{{W}}}ascii', font_name)
    rfonts.set(f'{{{W}}}hAnsi', font_name)
    rfonts.set(f'{{{W}}}eastAsia', font_name)

    # Size
    for sz in rpr.findall(f'{{{W}}}sz'):
        rpr.remove(sz)
    for sz_cs in rpr.findall(f'{{{W}}}szCs'):
        rpr.remove(sz_cs)
    sz = ET.SubElement(rpr, f'{{{W}}}sz')
    sz.set(f'{{{W}}}val', str(pt_to_half_pt(size_pt)))
    sz_cs = ET.SubElement(rpr, f'{{{W}}}szCs')
    sz_cs.set(f'{{{W}}}val', str(pt_to_half_pt(size_pt)))

    # Bold
    if bold:
        for b in rpr.findall(f'{{{W}}}b'):
            rpr.remove(b)
        ET.SubElement(rpr, f'{{{W}}}b')

    # Color
    if color:
        for c in rpr.findall(f'{{{W}}}color'):
            rpr.remove(c)
        col = ET.SubElement(rpr, f'{{{W}}}color')
        col.set(f'{{{W}}}val', color)

def set_first_line_indent(style_elem, indent_pt):
    """Set first line indent on a style's paragraph properties."""
    ppr = style_elem.find(f'{{{W}}}pPr')
    if ppr is None:
        ppr = ET.SubElement(style_elem, f'{{{W}}}pPr')
    for ind in ppr.findall(f'{{{W}}}ind'):
        ppr.remove(ind)
    if indent_pt > 0:
        ind = ET.SubElement(ppr, f'{{{W}}}ind')
        ind.set(f'{{{W}}}firstLine', str(int(indent_pt * 20)))  # pt to twips
    else:
        # 字下げ0を明示（親スタイルからの継承を防ぐ）
        ind = ET.SubElement(ppr, f'{{{W}}}ind')
        ind.set(f'{{{W}}}firstLine', '0')

# Find and modify styles
style_map = {
    'Normal': ('Yu Mincho', 8, False),
    'Heading 1': ('Yu Gothic', 14, True),
    'Heading 2': ('Yu Gothic', 11, True),
    'Heading 3': ('Yu Gothic', 9.5, True),
    'Heading 4': ('Yu Gothic', 8.5, True),
    'Image Caption': ('Yu Gothic', 6, False, '666666'),
    'Caption': ('Yu Gothic', 6, False, '666666'),
    'Table Caption': ('Yu Gothic', 6, False, '666666'),
}

# 字下げあり：本文段落
styles_with_indent = {'Normal', 'Body Text'}

# 字下げなし：見出し直後、箇条書き、コード、キャプション等
styles_without_indent = {
    'First Paragraph',   # 見出し直後の段落
    'Compact',           # 箇条書き（タイトリスト）
    'Source Code',       # コードブロック
    'Block Text',        # 引用ブロック
    'Definition',        # 定義リスト
    'Definition Term',   # 定義リスト見出し
    'Caption',           # キャプション
    'Image Caption',     # 画像キャプション
    'Table Caption',     # 表キャプション
    'Figure',            # 図
    'Captioned Figure',  # キャプション付き図
    'Footnote Text',     # 脚注
    'Footnote Block Text', # 脚注ブロック
    'TOC Heading',       # 目次見出し
}

for style_elem in root.findall(f'{{{W}}}style'):
    name_elem = style_elem.find(f'{{{W}}}name')
    if name_elem is not None:
        style_name = name_elem.get(f'{{{W}}}val', '')
        if style_name in style_map:
            entry = style_map[style_name]
            font, size, bold = entry[0], entry[1], entry[2]
            color = entry[3] if len(entry) > 3 else None
            set_style_font_and_size(style_elem, font, size, bold, color)

        # 字下げ設定
        if style_name in styles_with_indent:
            set_first_line_indent(style_elem, 8)
        elif style_name in styles_without_indent:
            set_first_line_indent(style_elem, 0)

tree.write(styles_xml_path, xml_declaration=True, encoding='UTF-8')

# Repack the DOCX
tmp_docx = docx_path + '.tmp'
with zipfile.ZipFile(tmp_docx, 'w', zipfile.ZIP_DEFLATED) as zout:
    for dirpath, dirnames, filenames in os.walk(tmp_dir):
        for filename in filenames:
            file_path = os.path.join(dirpath, filename)
            arcname = os.path.relpath(file_path, tmp_dir)
            zout.write(file_path, arcname)

shutil.move(tmp_docx, docx_path)
shutil.rmtree(tmp_dir)
print("A5 reference DOCX patched successfully")
PYTHON

# === Step 2: Build combined markdown ===
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

# === Step 3: Convert to DOCX ===
echo "=== Converting to DOCX ==="

pandoc \
    "$COMBINED" \
    --reference-doc="$REFERENCE_DOCX" \
    --resource-path="$PAGES_DIR:$PAGES_DIR/images" \
    --toc \
    --toc-depth=2 \
    -M toc-title="目次" \
    -f markdown \
    -t docx \
    -o "$OUTPUT_DIR/ai-driven-development-guide.docx"

rm -f "$COMBINED"

# === Step 4: Post-process DOCX for contextual indentation ===
echo "=== Post-processing indentation ==="

python3 - "$OUTPUT_DIR/ai-driven-development-guide.docx" <<'PYPOST'
import sys, zipfile, xml.etree.ElementTree as ET, shutil, os, tempfile

docx_path = sys.argv[1]

NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
W = NS['w']

# Register namespaces to avoid ns0/ns1 pollution
for prefix, uri in {
    'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
    'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
    'mc': 'http://schemas.openxmlformats.org/markup-compatibility/2006',
    'wp': 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
    'pic': 'http://schemas.openxmlformats.org/drawingml/2006/picture',
    'w14': 'http://schemas.microsoft.com/office/word/2010/wordml',
    'w15': 'http://schemas.microsoft.com/office/word/2012/wordml',
    'wps': 'http://schemas.microsoft.com/office/word/2010/wordprocessingShape',
    'wpg': 'http://schemas.microsoft.com/office/word/2010/wordprocessingGroup',
    'v': 'urn:schemas-microsoft-com:vml',
    'o': 'urn:schemas-microsoft-com:office:office',
    'm': 'http://schemas.openxmlformats.org/officeDocument/2006/math',
    'sl': 'http://schemas.openxmlformats.org/schemaLibrary/2006/main',
    'wne': 'http://schemas.microsoft.com/office/word/2006/wordml',
    'w10': 'urn:schemas-microsoft-com:office:word',
    'c': 'http://schemas.openxmlformats.org/drawingml/2006/chart',
    'lc': 'http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas',
    'dgm': 'http://schemas.openxmlformats.org/drawingml/2006/diagram',
}.items():
    ET.register_namespace(prefix, uri)

tmp_dir = tempfile.mkdtemp()
with zipfile.ZipFile(docx_path, 'r') as z:
    z.extractall(tmp_dir)

doc_xml = os.path.join(tmp_dir, 'word', 'document.xml')
tree = ET.parse(doc_xml)
root = tree.getroot()

fixed_count = 0

for para in root.iter(f'{{{W}}}p'):
    runs = para.findall(f'{{{W}}}r')
    if not runs:
        continue

    # --- 段落のテキスト全体を取得 ---
    full_text = ''
    for r in runs:
        t = r.find(f'{{{W}}}t')
        if t is not None and t.text:
            full_text += t.text

    text = full_text.strip()
    if not text:
        continue

    # --- 字下げを除去すべき段落かどうか判定 ---
    should_remove_indent = False

    # 1. 全てのrunが太字の段落（太字ラベル行）
    all_bold = True
    has_text_run = False
    for r in runs:
        t = r.find(f'{{{W}}}t')
        if t is not None and t.text and t.text.strip():
            has_text_run = True
            rpr = r.find(f'{{{W}}}rPr')
            if rpr is None:
                all_bold = False
                break
            b = rpr.find(f'{{{W}}}b')
            if b is None:
                all_bold = False
                break
    if has_text_run and all_bold:
        should_remove_indent = True

    # 2. 画像を含む段落
    if para.findall(f'.//{{{W}}}drawing'):
        should_remove_indent = True

    # 3. 短いラベル行（30文字以下で：や:で終わる）
    if len(text) <= 30 and (text.endswith('：') or text.endswith(':') or text.endswith('**')):
        should_remove_indent = True

    # 4. 短い導入文（箇条書きの前のラベル的な行、40文字以下で：で終わる）
    if len(text) <= 40 and (text.endswith('：') or text.endswith(':')) and not text.startswith('　'):
        should_remove_indent = True

    # --- スタイル名を取得 ---
    ppr = para.find(f'{{{W}}}pPr')
    style_id = ''
    if ppr is not None:
        ps = ppr.find(f'{{{W}}}pStyle')
        if ps is not None:
            style_id = ps.get(f'{{{W}}}val', '')

    # BodyText スタイル（字下げあり）の段落のみ対象
    if not should_remove_indent or style_id not in ('BodyText', ''):
        continue

    # --- 字下げ除去を実行（スタイル継承の字下げを直接指定で上書き）---
    if ppr is None:
        ppr = ET.SubElement(para, f'{{{W}}}pPr')
        para.remove(ppr)
        para.insert(0, ppr)

    ind = ppr.find(f'{{{W}}}ind')
    if ind is None:
        ind = ET.SubElement(ppr, f'{{{W}}}ind')
    ind.set(f'{{{W}}}firstLine', '0')
    fixed_count += 1

tree.write(doc_xml, xml_declaration=True, encoding='UTF-8')

# Repack
tmp_docx = docx_path + '.tmp'
with zipfile.ZipFile(tmp_docx, 'w', zipfile.ZIP_DEFLATED) as zout:
    for dirpath, dirnames, filenames in os.walk(tmp_dir):
        for filename in filenames:
            fp = os.path.join(dirpath, filename)
            arcname = os.path.relpath(fp, tmp_dir)
            zout.write(fp, arcname)
shutil.move(tmp_docx, docx_path)
shutil.rmtree(tmp_dir)

print(f"Fixed indentation on {fixed_count} paragraphs")
PYPOST

FILE_SIZE=$(ls -lh "$OUTPUT_DIR/ai-driven-development-guide.docx" | awk '{print $5}')
echo "=== Done ==="
echo "Output: $OUTPUT_DIR/ai-driven-development-guide.docx"
echo "Size:   $FILE_SIZE"
