# AIでテストコードを自動生成する

実装が完了したら、テストコードを作成します。テストコードもAIに自動生成させることで、高品質なテストを短時間で作成できます。

## テストコード自動生成の流れ

```
実装コード + 設計書 + 要件定義書
    ↓ AIに読み込ませる
テストコード（ユニットテスト）
    ↓ テスト実行
カバレッジ確認
    ↓ Gitにコミット
```

## AIにテストコードを生成させる

### ステップ1：ユニットテストの生成（バックエンド）

実装コードを参照させて、ユニットテストを生成します。

```
プロンプト例：
「@backend/src/routes/auth.ts の register エンドポイントに対するユニットテストを作成してください。
backend/tests/routes/auth.test.ts に実装してください。

以下のテストケースを含めてください：
- 正常系：有効なメールアドレスとパスワードで登録成功
- 異常系：無効なメールアドレス（バリデーションエラー）
- 異常系：パスワードが8文字未満（バリデーションエラー）
- 異常系：既に登録済みのメールアドレス（重複エラー）

Jestを使用してください。
モックは jest.mock() を使用してください。」
```

AIが以下のようなテストコードを生成：

```typescript
// backend/tests/routes/auth.test.ts
import request from 'supertest';
import app from '../../src/app';
import { prisma } from '../../src/db';

describe('POST /api/auth/register', () => {
  afterEach(async () => {
    await prisma.user.deleteMany();
  });

  it('正常系：有効なメールアドレスとパスワードで登録成功', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'SecureP@ss123',
      });

    expect(response.status).toBe(201);
    expect(response.body.status).toBe('success');
    expect(response.body.data.user.email).toBe('test@example.com');
    expect(response.body.data.token).toBeDefined();
  });

  it('異常系：無効なメールアドレス', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'invalid-email',
        password: 'SecureP@ss123',
      });

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('email');
  });

  it('異常系：パスワードが8文字未満', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'short',
      });

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('password');
  });

  it('異常系：既に登録済みのメールアドレス', async () => {
    // 1回目の登録
    await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'SecureP@ss123',
      });

    // 2回目の登録（重複）
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'AnotherP@ss456',
      });

    expect(response.status).toBe(409);
    expect(response.body.error).toContain('already exists');
  });
});
```

### ステップ2：フロントエンドのテスト生成

フロントエンドコンポーネントのテストも生成します。

```
プロンプト例：
「@frontend/src/components/LoginForm.tsx に対するテストを作成してください。
frontend/tests/components/LoginForm.test.tsx に実装してください。

以下のテストケースを含めてください：
- 正常系：有効な入力でログイン成功
- 正常系：バリデーションエラーの表示
- 正常系：ローディング状態の表示
- 正常系：APIエラーの表示

React Testing Library を使用してください。」
```

### ステップ3：カバレッジの確認

テストを実行し、カバレッジを確認します。

```bash
# バックエンドのテスト実行
cd backend
npm test -- --coverage

# フロントエンドのテスト実行
cd frontend
npm test -- --coverage
```

カバレッジが低い場合、追加のテストを生成：

```
プロンプト例：
「@backend/src/services/taskService.ts のカバレッジが60%です。
カバレッジを90%以上にするための追加テストを作成してください。
特に、以下の関数のテストが不足しています：
- updateTask()
- deleteTask()
- getTasksByUser()」
```

## 統合テスト（E2Eテスト）の自動生成

統合テストもAIに生成させることができます。

```
プロンプト例：
「タスク管理アプリの統合テストを作成してください。
tests/e2e/task-management.spec.ts に実装してください。

以下のシナリオをテストしてください：
1. ユーザー登録
2. ログイン
3. タスク作成
4. タスク一覧表示
5. タスク編集
6. タスク削除
7. ログアウト

Playwrightを使用してください。」
```

## AIにテストケースの漏れを指摘させる

要件定義書と設計書を参照させて、テストケースの漏れを確認させます。

```
プロンプト例：
「@Docs/要件定義書.md と @Docs/設計書.md を確認してください。
@backend/tests/ 配下の既存テストコードをレビューし、
不足しているテストケースを指摘してください。

特に以下の観点でチェックしてください：
- 要件定義書の機能要件がすべてテストされているか
- エッジケースのテストが不足していないか
- エラーハンドリングのテストが十分か
- セキュリティ関連のテストがあるか」
```

AIが不足しているテストケースを指摘してくれます：

```markdown
## 不足しているテストケース

### 1. タスク共有機能のテスト
要件定義書に「タスクを複数ユーザーで共有する」とありますが、
この機能のテストが見つかりません。
以下のテストが必要です：
- タスクに他のユーザーを招待
- 共有されたタスクの閲覧権限
- 共有されたタスクの編集権限

### 2. 優先度フィルタリングのテスト
タスク一覧APIで優先度によるフィルタリングのテストが不足しています。

### 3. 認証トークンの有効期限テスト
JWTトークンの有効期限切れのテストがありません。

...
```

## テストコード生成のベストプラクティス

### 1. 実装コード・設計書・要件定義書を参照させる

```
✅ 良い例：
「@backend/src/routes/tasks.ts
@Docs/設計書.md
@Docs/要件定義書.md
を参照して、タスク一覧APIの完全なテストスイートを作成してください。」
```

これにより、AIが仕様を正確に理解し、漏れのないテストを生成できます。

### 2. テストフレームワークを指定する

```
✅ 良い例：
「Jestを使用してください。
モックはjest.mock()を使用してください。
アサーションはexpect()を使用してください。」
```

### 3. 正常系と異常系の両方をカバーする

```
✅ 良い例：
「以下のテストケースを含めてください：
- 正常系：成功パターン
- 異常系：バリデーションエラー
- 異常系：認証エラー
- 異常系：権限エラー
- 異常系：リソース���在エラー」
```

### 4. エッジケースも忘れずに

```
✅ 良い例：
「エッジケースのテストも追加してください：
- 空文字列
- null/undefined
- 最大文字数超過
- 境界値（0, 1, -1）」
```

## Claude Codeで完全自動化

テストコード生成は定型的な作業なので、Claude Codeの完全自動モードが効果的です。

```bash
claude-code --dangerously-skip-permissions
```

```
プロンプト：
「@backend/src/ 配下の全ファイルに対して、
ユニットテストを自動生成してください。
テストファイルは @backend/tests/ に配置してください。
カバレッジ90%以上を目指してください。」
```

Claude Codeが自動的に：
1. 全ファイルを解析
2. テストコードを生成
3. テストを実行
4. カバレッジを確認
5. 不足分を追加

詳しくは「[テストコードの自動生成](./テストコードの自動生成.md)」を参照してください。

## まとめ：テストコード自動生成のポイント

| ポイント | 内容 |
|---------|------|
| **参照** | 実装コード・設計書・要件定義書を参照させる |
| **フレームワーク** | 使用するテストフレームワークを明示 |
| **網羅性** | 正常系・異常系・エッジケースをカバー |
| **レビュー** | AIに不足テストケースを指摘させる |
| **自動化** | Claude Codeで完全自動化 |

**重要な原則**

1. **実装と同時にテストを書く**：実装後すぐにテストを生成
2. **要件定義書を参照させる**：仕様漏れを防ぐ
3. **カバレッジを確認する**：90%以上を目指す
4. **AIにレビューさせる**：不足テストケースを指摘させる
5. **人間が最終確認する**：AIが生成したテストの妥当性を確認

次のセクションでは、シナリオテスト仕様書の自動生成について学びます。
