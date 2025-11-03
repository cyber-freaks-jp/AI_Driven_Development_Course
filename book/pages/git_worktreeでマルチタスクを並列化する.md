# git worktreeでマルチタスクを並列化する

Claude Codeの完全自動実行モードを使うと、人間が関与しなくても自動でgithubのプルリクエストを作成してくれるようになります。

そうなってくると、複数のAIを並列で走らせて、複数機能を同時に開発したくなってきます。
それを実現するのがgit worktreeです

## 並列実行したいというニーズ

例えば、あなたのプロジェクトに3つのIssueがあるとします。

- **Issue 1**：ユーザー登録機能の追加
- **Issue 2**：パスワードリセット機能のバグ修正
- **Issue 3**：管理画面のUIデザイン改善

通常の開発では、これらを1つずつ順番に実装していきます。Issue 1が完了してから、Issue 2に取り掛かり、Issue 2が終わったらIssue 3に着手します。

しかし、Claude Codeの完全自動実行モードを使えば、こう考えることができます。

「AIに全部任せて自動実行できるなら、3つのタスクを同時に走らせたらもっと早く終わるのでは？」

この考えは正しいです。3つのIssueが互いに独立している場合、並列実行することで開発速度を大幅に向上させることができます。

しかしここで問題が起きます

## 問題：通常のgitでは並列作業ができない

通常、gitでは同時に1つのブランチしかチェックアウトできないので並列作業は出来ません。
これでは、3つのIssueを並列実行することはできません。

それを解決するのがgit worktreeです

## git worktreeとは

git worktreeは、**同時に複数のワーキングディレクトリ(作業スペース)を作成できる機能**です。

**従来の`git checkout`の場合：** 1つのフォルダ(=ワーキングディレクトリ)で作業。git checkoutコマンドでブランチを切り替える

```mermaid
graph TB
    A1[.gitディレクトリ] --> B1[ワーキングディレクトリ]
    B1 -.切り替え.-> C1[mainブランチ]
    B1 -.切り替え.-> D1[feature/issue1]
    B1 -.切り替え.-> E1[feature/issue2]

    style B1 fill:#ffcccc
    style C1 fill:#e0e0e0
    style D1 fill:#e0e0e0
    style E1 fill:#e0e0e0
```

**`git worktree`の場合：** gitディレクトリ配下に、子フォルダ(=ワーキングディレクトリ)が複数作成される。git checkoutではなく、フォルダ移動することで作業場所を切り替える

```mermaid
graph TB
    A2[.gitディレクトリ<br/>メイン] --> B2[ワーキングディレクトリ1<br/>mainブランチ]
    A2 --> C2[ワーキングディレクトリ2<br/>feature/issue1]
    A2 --> D2[ワーキングディレクトリ3<br/>feature/issue2]

    style B2 fill:#ccffcc
    style C2 fill:#ccffcc
    style D2 fill:#ccffcc
```

### git checkoutとの違い

多くの方が「ブランチを切り替えるなら`git checkout`があるじゃないか」と疑問に思うかもしれません。しかし、`git checkout`は同時に1つのブランチしか扱えません

一方、git worktreeコマンドを使うと、いつものgitディレクトリ配下に、1ブランチにつき、1つの子フォルダ(=ワーキングディレクトリ)が作成されます。git checkoutコマンドではなく、フォルダ移動することで作業場所を切り替えます

**`git worktree`の場合：**

```bash
# Issue 1用のディレクトリ
git worktree add ../myproject-issue1 feature/issue1

# Issue 2用のディレクトリ
git worktree add ../myproject-issue2 feature/issue2
```

git worktreeは、以下のような構造を作ります。

```
myproject/                    # メインのリポジトリ
├── .git/                     # 共有される.gitディレクトリ
├── src/
└── package.json

myproject-issue1/             # worktree（feature/issue1）
├── .git -> ../myproject/.git/worktrees/myproject-issue1
├── src/
└── package.json

myproject-issue2/             # worktree（feature/issue2）
├── .git -> ../myproject/.git/worktrees/myproject-issue2
├── src/
└── package.json
```

各worktreeは、メインの`.git`ディレクトリを参照しています。そのため、リポジトリ全体を複製する必要がありません。

**メリット：**
- ディスク容量の節約（リポジトリは1つだけ）
- リポジトリの同期が簡単（`.git`ディレクトリは共有されている）
- 各ワーキングディレクトリで異なるブランチを同時にチェックアウト可能

### git cloneとの違い

「複数のディレクトリで作業するなら、`git clone`で複数回クローンすればいいのでは？」と思う方もいるかもしれません。確かに可能ですが、`git worktree`の方が圧倒的に効率的です。

**`git clone`で複数回クローンする場合：**

```bash
# 1つ目のリポジトリ
git clone https://github.com/user/myproject.git myproject

# 2つ目のリポジトリ（別ディレクトリ）
git clone https://github.com/user/myproject.git myproject-issue1

# 3つ目のリポジトリ（別ディレクトリ）
git clone https://github.com/user/myproject.git myproject-issue2
```

**`git clone`の問題点：**

- **ディスク容量を大量に消費**：各クローンが完全な`.git`ディレクトリを持つため、同じ履歴データが3回保存される
- **同期が面倒**：各リポジトリで個別に`git fetch`や`git pull`を実行する必要がある

**`git worktree`の場合：**

- **ディスク容量を大幅に節約**：`.git`ディレクトリは1つだけ。worktreeは作業ファイルのみを持つ
- **同期が簡単**：メインリポジトリで`git fetch`すれば、すべてのworktreeに反映される

## git worktreeの基本的な使い方

### 1. worktreeの作成

新しいworktreeを作成するには、`git worktree add`コマンドを使います。

```bash
# メインのリポジトリで
cd myproject

# feature/issue1ブランチ用のworktreeを作成
git worktree add ../myproject-issue1 feature/issue1
```

このコマンドは以下のことを実行します：

1. `../myproject-issue1`ディレクトリを作成
2. そのディレクトリで`feature/issue1`ブランチをチェックアウト
3. worktreeをメインリポジトリの`.git`にリンク

### 2. 新しいブランチを作成してworktreeを作成

ブランチがまだ存在しない場合は、`-b`オプションで新しいブランチを作成できます。

```bash
# 新しいブランチ feature/issue2 を作成してworktreeを追加
git worktree add -b feature/issue2 ../myproject-issue2
```

### 3. worktreeの一覧を表示

現在のworktreeの一覧を確認するには、`git worktree list`を使います。

```bash
git worktree list
```

出力例：

```
/Users/yourname/myproject              abc1234 [main]
/Users/yourname/myproject-issue1       def5678 [feature/issue1]
/Users/yourname/myproject-issue2       ghi9012 [feature/issue2]
/Users/yourname/myproject-issue3       jkl3456 [feature/issue3]
```

### 4. worktreeの削除

作業が完了したworktreeは削除できます。

```bash
# worktreeを削除（ディレクトリごと削除）
git worktree remove ../myproject-issue1

# または、ディレクトリを手動で削��した後にクリーンアップ
rm -rf ../myproject-issue1
git worktree prune
```

**注意：**
- `git worktree remove`は、未コミットの変更がある場合は削除を拒否します
- `-f`オプションで強制削除できますが、変更が失われるため注意が必要です

## AI駆動開発での具体的な活用シナリオ

git worktreeとClaude Codeを組み合わせた、実践的な並列開発のワークフローを見ていきます。

### ステップ1：worktreeを複数作成

```bash
# メインのリポジトリで
cd myproject

# Issue 1用のworktreeを作成
git worktree add -b feature/issue1 ../myproject-issue1

# Issue 2用のworktreeを作成
git worktree add -b feature/issue2 ../myproject-issue2
```

### ステップ2：それぞれのworktreeでClaude Codeを起動し、並列で開発を進める

**ターミナル1：**

```bash
cd ../myproject-issue1
claude --dangerously-skip-permissions
# issue1の開発を進める
```

**ターミナル2：**

```bash
cd ../myproject-issue2
claude --dangerously-skip-permissions
# issue2の開発を進める
```

### ステップ3：開発完了後、worktreeを削除

```bash
cd myproject
git worktree remove ../myproject-issue1
git worktree remove ../myproject-issue2
```

## まとめ

git worktreeを活用することで、AI駆動開発の生産性をさらに向上させることができます。

なお、claude codeの --dangerously-skip-permissions のような、完全自動実行してくれるモードの使用を強くお勧めします。
