# AI 駆動開発入門

このリポジトリは「AI 駆動開発入門」のソースコードです。

## 概要

この本では、AI を活用したソフトウェア開発の基礎から実践までを解説します。
最新の AI ツールを活用して、より効率的で質の高い開発を実現する方法を学びましょう。

## ローカルでの実行方法

1. 必要なツールのインストール

```bash
pip install mkdocs-material
```

2. ローカルサーバーの起動

```bash
cd book
mkdocs serve
```

3. ブラウザで確認

- http://127.0.0.1:8000 にアクセス

## ビルド方法

```bash
mkdocs build
```

## ディレクトリ構成

```
book/
├── docs/                    # マークダウンファイル
│   ├── images/             # 画像ファイル
│   │   └── illustrations/  # イラストレーション
│   │
│   ├── chapter1.md         # 第1章
│   ├── chapter2.md         # 第2章
│   └── index.md            # トップページ
├── mkdocs.yml              # MkDocs設定ファイル
└── README.md               # このファイル
```

## ライセンス

この本は [MIT License](LICENSE) のもとで公開されています。

## 貢献

1. このリポジトリをフォーク
2. 新しいブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成
