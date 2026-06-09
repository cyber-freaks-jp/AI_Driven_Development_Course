# AI駆動開発 入門講座

「ITエンジニアのためのAI駆動開発入門｜2026年版」の原稿リポジトリです。

## ディレクトリ構成

```
book/
├── pages/           # 各章のMarkdownファイル（原稿本体）
│   └── images/      # 本文中で使用する画像ファイル
├── output/          # ビルド成果物の出力先
├── build-epub.sh    # Kindle電子書籍用EPUBビルド
├── build-docx.sh    # ペーパーバック用DOCXビルド
├── build-a5pdf.sh   # ページ数確認用A5 PDFビルド
├── epub-metadata.yaml  # EPUB用メタデータ（タイトル・著者等）
├── epub.css         # EPUB用スタイルシート
├── epub-style.css   # EPUB追加スタイル
└── .reference-a5.docx  # DOCX変換用リファレンステンプレート（自動生成）
```

## ビルドスクリプト

### 前提条件

- [Pandoc](https://pandoc.org/) がインストールされていること
- [WeasyPrint](https://weasyprint.org/) がインストールされていること（A5 PDFビルド時のみ）
- Python 3 がインストールされていること（DOCXビルド時のみ）

### build-epub.sh — Kindle電子書籍用EPUB生成

`book/pages/` 配下のMarkdownファイルを章順に結合し、Pandocで EPUB3 形式に変換します。

- 各セクションの見出しレベルを自動で1段下げ、章見出し（`# 第X章`）を挿入
- `epub-metadata.yaml` のメタデータ（タイトル・著者・言語等）を埋め込み
- `epub.css` でスタイルを適用
- `cover.png` が存在すれば表紙画像として使用
- 出力先: `book/output/ai-driven-development-guide.epub`

```bash
cd book && bash build-epub.sh
```

### build-docx.sh — ペーパーバック用DOCX生成

Kindle ペーパーバック入稿用の A5 サイズ DOCX を生成します。3つのステップで処理されます。

1. **リファレンスDOCX生成**: Pandocのデフォルトテンプレートを生成し、Python で A5 ページサイズ（148mm×210mm）、マージン（ノド25mm）、日本語フォント（游明朝・游ゴシック）、フォントサイズを設定
2. **Markdown → DOCX変換**: リファレンスDOCXをテンプレートとして、全Markdownを結合しPandocでDOCXに変換（目次付き）
3. **後処理（字下げ調整）**: Python で DOCX を直接編集し、太字行・画像段落・ラベル行など字下げ不要な段落の字下げを除去

- 出力先: `book/output/ai-driven-development-guide.docx`

```bash
cd book && bash build-docx.sh
```

### build-a5pdf.sh — ページ数確認用A5 PDF生成

ペーパーバックのページ数を事前確認するための A5 PDF を生成します。

1. Pandocで Markdown → HTML5 に変換
2. WeasyPrint で HTML → A5 PDF に変換（CSS でページサイズ・マージン・フォント等を指定）
3. 生成後にページ数を表示

- 出力先: `book/output/a5-page-count.pdf`

```bash
cd book && bash build-a5pdf.sh
```

## Kindle出版の手順

### デジタル書籍（Kindle本）

1. **原稿の準備**: `book/pages/` 配下のMarkdownファイルを編集
2. **EPUBビルド**: `bash build-epub.sh` を実行
3. **表紙画像の準備**: Kindle推奨サイズ（1600×2560px）の表紙画像を `book/cover.png` として配置
4. **KDPにアップロード**: [Kindle Direct Publishing](https://kdp.amazon.co.jp/) にログインし、生成された `book/output/ai-driven-development-guide.epub` をアップロード

### ペーパーバック（紙の書籍）

1. **原稿の準備**: `book/pages/` 配下のMarkdownファイルを編集
2. **DOCXビルド**: `bash build-docx.sh` を実行
3. **目検・手作業チェック**: 生成された `book/output/ai-driven-development-guide.docx` を Word で開き、以下を確認・修正
   - ページ番号の設定（奇数ページは右下、偶数ページは左下に配置）
   - 画像の表示崩れやサイズ調整
   - 表の列幅・改行の調整
   - ページ跨ぎによるレイアウト崩れ
   - 見出し前後の改ページ位置
   - フォントの適用状況
   - 全体の体裁と可読性
4. **ページ数の確認**: チェック済みの DOCX でページ数を確認（KDPの表紙テンプレートにページ数が必要なため）
5. **PDF変換**: チェック済みの DOCX を Word から「名前を付けて保存」で PDF に変換
6. **KDPにアップロード**: KDP のペーパーバック設定で、PDF原稿と表紙をアップロード

