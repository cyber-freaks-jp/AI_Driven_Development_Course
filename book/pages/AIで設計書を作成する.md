# AIで設計書を作成する

要件定義書が完成したら、次は設計書を作成します。ここでもAIを最大限活用することで、設計の品質とスピードを大幅に向上させることができます。

## 要件定義書から設計書を自動生成する流れ

```
要件定義書.md（マークダウン）
    ↓ AIに読み込ませる
設計書.md（マークダウン）
    ↓ 詳細化・修正
完成した設計書
    ↓ Gitにコミット
実装フェーズへ
```

## 設計書の基本構成

マークダウンで書く設計書は、以下の構成がおすすめです：

```markdown
# 設計書：[プロジェクト名]

## 1. システム概要
- アーキテクチャ概要
- 技術スタック
- 外部サービス連携

## 2. データベース設計
### 2.1 ER図
### 2.2 テーブル定義
### 2.3 インデックス設計

## 3. API設計
### 3.1 エンドポイント一覧
### 3.2 リクエスト/レスポンス仕様
### 3.3 エラーハンドリング

## 4. フロントエンド設計
### 4.1 画面遷移図
### 4.2 コンポーネント設計
### 4.3 状態管理

## 5. セキュリティ設計
### 5.1 認証・認可
### 5.2 データ暗号化
### 5.3 脆弱性対策

## 6. パフォーマンス設計
### 6.1 キャッシュ戦略
### 6.2 スケーリング戦略
```

## CursorのComposerで設計書を自動生成

### ステップ1：要件定義書を参照させる

Composerを起動（`Cmd+I`）し、`@`記法で要件定義書を指定します：

```
プロンプト例：
「@Docs/要件定義書.md をもとに、設計書.mdを作成してください。
以下の内容を含めてください：
- システムアーキテクチャ（3層構造: フロントエンド、バックエンド、データベース）
- データベース設計（ER図とテーブル定義）
- API設計（RESTful API）
- 認証・認可の設計（JWT認証）

マークダウン形式で、Mermaid図も活用してください。」
```

### ステップ2：AIが生成した設計書をレビュー

AIが自動生成した設計書を確認します。例：

```markdown
# 設計書：タスク管理Webアプリケーション

## 1. システム概要

### 1.1 アーキテクチャ概要

本システムは3層アーキテクチャで構成します。

\`\`\`mermaid
flowchart LR
    A[フロントエンド<br/>React + TypeScript] --> B[バックエンド<br/>Node.js + Express]
    B --> C[データベース<br/>PostgreSQL]
    B --> D[Redis<br/>キャッシュ]
\`\`\`

### 1.2 技術スタック

| レイヤー | 技術 |
|---------|------|
| フロントエンド | React 18, TypeScript, TailwindCSS |
| バックエンド | Node.js 20, Express, TypeScript |
| データベース | PostgreSQL 16 |
| キャッシュ | Redis 7 |
| 認証 | JWT |
| デプロイ | Docker, AWS ECS |

## 2. データベース設計

### 2.1 ER図

\`\`\`mermaid
erDiagram
    USER ||--o{ TASK : creates
    USER {
        uuid id PK
        varchar email UK
        varchar password_hash
        timestamp created_at
        timestamp updated_at
    }
    TASK ||--o{ COMMENT : has
    TASK {
        uuid id PK
        uuid user_id FK
        varchar title
        text description
        int priority
        timestamp deadline
        varchar status
        timestamp created_at
        timestamp updated_at
    }
    COMMENT {
        uuid id PK
        uuid task_id FK
        uuid user_id FK
        text content
        timestamp created_at
    }
\`\`\`

### 2.2 テーブル定義

#### USER テーブル

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|---|------|----------|------|
| id | UUID | NOT NULL | uuid_generate_v4() | 主キー |
| email | VARCHAR(255) | NOT NULL | - | メールアドレス（一意） |
| password_hash | VARCHAR(255) | NOT NULL | - | bcryptハッシュ化パスワード |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |

**インデックス**
- PRIMARY KEY (id)
- UNIQUE INDEX (email)

...
```

### ステップ3：詳細を段階的に追加

複雑な設計は、段階的に詳細化します。

#### API設計を詳細化

```
プロンプト例：
「設計書.mdの「3. API設計」セクションを詳細化してください。
以下のエンドポイントを追加してください：

### ユーザー認証API
- POST /api/auth/register（ユーザー登録）
- POST /api/auth/login（ログイン）
- POST /api/auth/logout（ログアウト）
- POST /api/auth/refresh（トークン更新）

### タスクAPI
- GET /api/tasks（タスク一覧取得）
- POST /api/tasks（タスク作成）
- GET /api/tasks/:id（タスク詳細取得）
- PUT /api/tasks/:id（タスク更新）
- DELETE /api/tasks/:id（タスク削除）

各エンドポイントについて、以下を記述してください：
- リクエストボディ（JSON形式）
- レスポンスボディ（JSON形式）
- ステータスコード（成功/エラー）
- 認証要否」
```

AIが以下のように詳細化してくれます：

```markdown
## 3. API設計

### 3.1 ユーザー認証API

#### POST /api/auth/register

**概要**: 新規ユーザー登録

**認証**: 不要

**リクエストボディ**:
\`\`\`json
{
  "email": "user@example.com",
  "password": "SecureP@ssw0rd"
}
\`\`\`

**レスポンス（成功）**:
\`\`\`json
{
  "status": "success",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "created_at": "2025-01-15T10:00:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
\`\`\`

**ステータスコード**:
- 201: 登録成功
- 400: バリデーションエラー
- 409: メールアドレス重複

...
```

## AIに設計の妥当性をチェックさせる

設計書が完成したら、AIに妥当性をチェックさせることもできます。

```
プロンプト例：
「@Docs/設計書.md をレビューしてください。
以下の観点で問題点を指摘してください：
- セキュリティ上の懸念
- パフォーマンスのボトルネック
- スケーラビリティの問題
- データ整合性の問題
- ベストプラクティスとの乖離」
```

AIが以下のようにフィードバックしてくれます：

```
レビュー結果：

【セキュリティ】
1. パスワードのバリデーションが弱い
   → 8文字以上、英数字記号の組み合わせを必須にすべき
2. JWTのリフレッシュトークンの有効期限が長すぎる（30日）
   → 7日に短縮すべき

【パフォーマンス】
1. タスク一覧APIでページネーションが未実装
   → LIMIT/OFFSETまたはカーソルベースのページネーションを追加すべき
2. N+1クエリ問題が発生する可能性
   → JOINまたはDataLoaderの使用を検討すべき

【スケーラビリティ】
1. データベース接続がプール管理されていない
   → pg-poolの導入を推奨

...
```

## 要件定義書と設計書を同時に参照

要件定義書と既存の設計書を同時に参照させて、整合性を保ちます。

```
プロンプト例：
「@Docs/要件定義書.md と @Docs/設計書.md を確認してください。
要件定義書に「タスクの優先度を3段階（高・中・低）で管理する」とありますが、
設計書のTASKテーブルのpriority カラムが int型 になっています。
ENUMまたはCHECK制約を使って、1〜3の範囲に制限してください。」
```

## Gitにコミット

設計書が完成したら、Gitにコミットします。

```bash
git add Docs/設計書.md
git commit -m "feat: タスク管理アプリの設計書を作成"
```

## まとめ：設計書作成のベストプラクティス

| ステップ | 内容 | ツール |
|---------|------|-------|
| 1 | 要件定義書を参照して設計書の雛形を生成 | Composer + @記法 |
| 2 | 各セクションを段階的に詳細化 | Composer / Cmd+K |
| 3 | Mermaid図を追加（ER図、シーケンス図など） | AIに生成させる |
| 4 | AIにレビューさせる | Composer |
| 5 | 要件定義書との整合性を確認 | @記法で両方参照 |
| 6 | Gitにコミット | Bash |

**重要なポイント**

- 要件定義書をもとに設計書を生成する（手動で書かない）
- 複雑な設計は段階的に詳細化する（一度に全部指示しない）
- Mermaid図を積極的に活用する
- AIにレビューさせてフィードバックを得る
- 要件定義書と設計書の整合性を常にチェック
- 必ずGitで管理する

次のセクションでは、設計について迷ったときにAIに相談する方法を学びます。
