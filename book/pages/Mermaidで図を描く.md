# Mermaidで図を描く

要件定義書や設計書には、システムの構成やフローを視覚的に表現する図が不可欠です。しかし、従来の方法（PowerPoint、Drawioなど）には問題があります。

## 従来の図作成の問題点

### PowerPointやDrawioの課題

- **バイナリファイル**：AIが認識できない
- **バージョン管理が困難**：Gitで差分を確認できない
- **修正が面倒**：図を手動で更新する必要がある
- **一貫性の欠如**：誰が編集するかで品質がバラバラ

## Mermaidとは？

**Mermaid**は、テキストベースで図を描ける記法です。マークダウン内にコードとして記述でき、自動的に図が生成されます。

### Mermaidの利点

- ✅ テキストファイル：AIが完璧に認識できる
- ✅ Gitで管理可能：差分が一目瞭然
- ✅ 自動生成可能：AIに図を描かせられる
- ✅ 修正が簡単：テキストを編集するだけ

## Mermaidで描ける図の種類

### 1. フローチャート（flowchart）

システムのフローを表現します。

```markdown
\`\`\`mermaid
flowchart TD
    A[ユーザー] --> B{ログイン済み?}
    B -->|はい| C[ダッシュボード表示]
    B -->|いいえ| D[ログイン画面表示]
    D --> E[認証処理]
    E --> F{認証成功?}
    F -->|はい| C
    F -->|いいえ| G[エラーメッセージ表示]
    G --> D
\`\`\`
```

これが自動的に以下のようなフローチャートになります：

```
┌─────────┐
│ユーザー  │
└────┬────┘
     │
     v
┌──────────┐
│ログイン済み?│
└─┬──────┬─┘
  │はい   │いいえ
  v      v
```

### 2. シーケンス図（sequenceDiagram）

システム間のやりとりを時系列で表現します。

```markdown
\`\`\`mermaid
sequenceDiagram
    participant U as ユーザー
    participant F as フロントエンド
    participant B as バックエンド
    participant D as データベース

    U->>F: ログインボタンをクリック
    F->>B: POST /api/login
    B->>D: ユーザー情報を検索
    D-->>B: ユーザーデータ
    B->>B: パスワード検証
    B-->>F: JWTトークン
    F-->>U: ダッシュボード表示
\`\`\`
```

### 3. ER図（erDiagram）

データベース設計を表現します。

```markdown
\`\`\`mermaid
erDiagram
    USER ||--o{ TASK : creates
    USER {
        int id PK
        string email
        string password
        datetime created_at
    }
    TASK {
        int id PK
        int user_id FK
        string title
        string description
        int priority
        datetime deadline
        datetime created_at
    }
    TASK ||--o{ COMMENT : has
    COMMENT {
        int id PK
        int task_id FK
        int user_id FK
        string content
        datetime created_at
    }
\`\`\`
```

### 4. クラス図（classDiagram）

オブジェクト指向設計を表現します。

```markdown
\`\`\`mermaid
classDiagram
    class User {
        +int id
        +string email
        +string password
        +login()
        +logout()
    }
    class Task {
        +int id
        +string title
        +string description
        +int priority
        +create()
        +update()
        +delete()
    }
    class TaskService {
        +createTask()
        +updateTask()
        +deleteTask()
        +getTasks()
    }
    User "1" --> "*" Task
    TaskService --> Task
\`\`\`
```

### 5. ガントチャート（gantt）

プロジェクトのスケジュールを表現します。

```markdown
\`\`\`mermaid
gantt
    title タスク管理アプリ開発スケジュール
    dateFormat  YYYY-MM-DD
    section 要件定義
    要件定義書作成           :a1, 2025-01-01, 7d
    レビュー                :a2, after a1, 3d
    section 設計
    データベース設計         :b1, after a2, 5d
    API設計                 :b2, after a2, 5d
    section 実装
    バックエンド実装         :c1, after b1, 14d
    フロントエンド実装       :c2, after b2, 14d
    section テスト
    ユニットテスト           :d1, after c1, 7d
    統合テスト              :d2, after d1, 7d
\`\`\`
```

## AIにMermaid図を描かせる

### Cursorでの使い方

要件定義書や設計書を作成する際に、AIにMermaid図も一緒に作ってもらえます。

#### 例1：フローチャートを追加

```
プロンプト：
「要件定義書.mdの「2.1 ユーザー登録・ログイン機能」セクションに、
ログインフローのMermaidフローチャートを追加してください。」
```

AIが自動的に以下のようなコードを生成：

```markdown
### ログインフロー

\`\`\`mermaid
flowchart TD
    Start[ユーザーがログインページにアクセス] --> Input[メールアドレスとパスワードを入力]
    Input --> Submit[ログインボタンをクリック]
    Submit --> Validate{入力検証}
    Validate -->|失敗| Error1[エラーメッセージ表示]
    Error1 --> Input
    Validate -->|成功| Auth{認証処理}
    Auth -->|失敗| Error2[認証エラー表示]
    Error2 --> Input
    Auth -->|成功| Token[JWTトークン発行]
    Token --> Dashboard[ダッシュボードにリダイレクト]
\`\`\`
```

#### 例2：ER図を追加

```
プロンプト：
「設計書.mdに、タスク管理システムのER図をMermaid形式で追加してください。
以下のテーブルを含めてください：
- USER（id, email, password, created_at）
- TASK（id, user_id, title, description, priority, deadline, created_at）
- COMMENT（id, task_id, user_id, content, created_at）

リレーションシップも明記してください。」
```

#### 例3：シーケンス図を追加

```
プロンプト：
「設計書.mdの「API設計」セクションに、
タスク作成APIのシーケンス図をMermaid形式で追加してください。
フロントエンド、バックエンド、データベースの3層構成で記述してください。」
```

## Mermaidの修正もAIに任せる

既存のMermaid図を修正する場合も、AIに指示できます。

```
プロンプト例：
「このMermaidフローチャートに、
「パスワードリセット」フローを追加してください。」
```

AIが既存のコードを理解し、適切に修正してくれます。

## Gitで差分管理

Mermaidはテキストなので、Gitで変更履歴が追跡できます：

```diff
 \`\`\`mermaid
 flowchart TD
     A[ユーザー] --> B{ログイン済み?}
     B -->|はい| C[ダッシュボード表示]
     B -->|いいえ| D[ログイン画面表示]
+    D --> E[2要素認証]
+    E --> F{認証成功?}
-    D --> E[認証処理]
-    E --> F{認証成功?}
 \`\`\`
```

従来のPowerPointやDrawioでは不可能だった差分管理が、Mermaidなら簡単にできます。

## CursorやVSCodeでMermaidをプレビュー

### Cursorでのプレビュー

CursorはデフォルトでMermaidをサポートしています。マークダウンファイルをプレビューすると、Mermaid図が自動的にレンダリングされます。

1. マークダウンファイルを開く
2. `Cmd+Shift+V`でプレビュー表示
3. Mermaid図が自動的に描画される

### VSCode拡張機能

VSCodeを使っている場合は、「Markdown Preview Mermaid Support」拡張機能をインストールすれば、同様にプレビュー���きます。

## まとめ

| 比較項目 | PowerPoint/Drawio | Mermaid |
|---------|------------------|---------|
| ファイル形式 | バイナリ | テキスト |
| AI認識性 | △ 低い | ◎ 完璧 |
| Git管理 | × 不可能 | ◎ 完璧 |
| 修正の手軽さ | △ 手動で編集 | ◎ テキスト編集 |
| AI自動生成 | × 不可能 | ◎ 可能 |
| プレビュー | ○ アプリ必要 | ◎ エディタで可能 |

**要件定義書や設計書の図は、Mermaidで描くべきです。**

次のセクションでは、要件定義書をもとにAIで設計書を作成する方法を学びます。
