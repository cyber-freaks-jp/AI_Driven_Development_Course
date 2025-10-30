# エディタとツールのセキュリティ設定

エディタやAIツールの設定を適切に行うことで、情報漏洩リスクを大幅に削減できます。このセクションでは、Cursor、GitHub Copilot、ChatGPTなどの主要ツールのセキュリティ設定を解説します。

## 設定すべき2つのポイント

1. **学習データとして使用されない設定**：AIに渡した情報がモデル学習に使われないようにする
2. **操作権限の制限**：AIが実行できる操作を制限する

## Cursorのセキュリティ設定

### 学習データとして使用されない設定

Cursorの設定画面で以下を設定：

**設定手順**：

1. Cursor > Settings（設定）を開く
2. Privacy（プライバシー）セクションへ
3. 以下を無効化：

```
☐ Send anonymous usage data
☐ Allow Cursor to train on my code
☐ Share diagnostic data
```

### プライバシーモード

```json
// .cursor/settings.json
{
  "cursor.privacy.sendTelemetry": false,
  "cursor.privacy.allowTraining": false,
  "cursor.privacy.shareDiagnostics": false
}
```

### 操作権限の制限

```json
// .cursorrules
# セキュリティルール

## 禁止事項
- ファイルの削除は禁止
- データベースへの直接アクセス禁止
- 外部APIへの直接通信禁止
- 環境変数の読み取り禁止

## 許可事項
- 新規ファイルの作成
- 既存ファイルの編集
- ローカルでのテスト実行
```

### APIキーやパスワードを含むファイルを除外

```
# .cursorignore
.env
.env.*
config/secrets.yml
config/database.yml
*.pem
*.key
id_rsa
*.p12
credentials.json
```

## GitHub Copilotのセキュリティ設定

### Enterprise版の設定（推奨）

**GitHub Copilot Business / Enterprise を使用**：

- デフォルトで学習に使用されない
- 組織レベルでのポリシー管理
- コードの保存期間を制御可能

### 個人版での設定

GitHub Copilot Settings：

```
☐ Allow GitHub to use my code snippets for product improvements
☐ Allow GitHub to use my code for research purposes
```

**重要：個人版は企業利用非推奨**

### .gitattributesで機密ファイルを除外

```
# .gitattributes
*.env linguist-generated=true
*.key linguist-generated=true
config/secrets.yml linguist-generated=true
```

### VSCode設定

```json
// settings.json
{
  "github.copilot.enable": {
    "*": true,
    "plaintext": false,
    "markdown": false,
    "scminput": false
  },
  "github.copilot.excludedLanguages": [
    "env",
    "dotenv"
  ]
}
```

## Claude（claude.ai / Claude API）のセキュリティ設定

### デフォルトでセキュア

Anthropicは以下をデフォルトで提供：

- ユーザーデータを学習に使用しない
- 会話は暗号化される
- SOC 2 Type 2準拠

### API使用時の設定

```python
# Python SDK
import anthropic

client = anthropic.Anthropic(
    api_key="YOUR_API_KEY"
)

# データ保存期間を最小化
response = client.messages.create(
    model="claude-3-5-sonnet-20250219",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello"}],
    # メタデータでプロジェクト情報を追跡（任意）
    metadata={"project": "internal-tool"}
)
```

### 機密情報の除外

```python
# 機密情報を自動的にマスク
import re

def mask_sensitive_data(code):
    # APIキーをマスク
    code = re.sub(r'(api_key|API_KEY)\s*=\s*["\'].*?["\']',
                  r'\1="***MASKED***"', code)
    # パスワードをマスク
    code = re.sub(r'(password|PASSWORD)\s*=\s*["\'].*?["\']',
                  r'\1="***MASKED***"', code)
    return code

# AIに送信する前にマスク
safe_code = mask_sensitive_data(source_code)
```

## ChatGPT（OpenAI）のセキュリティ設定

### ChatGPT Enterpriseを使用（推奨）

**ChatGPT Enterprise の利点**：

- データを学習に使用しない
- SOC 2準拠
- SSO（シングルサインオン）対応
- 管理者による使用状況の監視

### 個人版（無料/Plus）での設定

**Settings > Data Controls**：

```
☑ Chat history & training
    ☐ Improve the model for everyone
```

**重要：無料版は企業利用非推奨**

### Custom Instructionsでルール設定

```
## セキュリティルール

以下の情報は絶対に生成・表示しないでください：
- 実際のAPIキー
- パスワード
- データベース接続文字列
- 個人情報

コード例を提示する際は、プレースホルダーを使用してください。
例：API_KEY="YOUR_API_KEY_HERE"
```

## Claude Code（CLI）のセキュリティ設定

### .claude/instructions.mdでルール設定

```markdown
# セキュリティポリシー

## 禁止事項

### ファイル操作
- `/etc`、`/sys`、`/proc` への書き込み禁止
- `.env`、`*.key`、`*.pem` ファイルの読み取り禁止
- ホームディレクトリ外へのアクセス禁止

### ネットワーク操作
- 外部APIへの直接アクセス禁止
- データベースへの直接接続禁止

### コマンド実行
- `rm -rf` の使用禁止
- `sudo` の使用禁止
- システムコマンドの直接実行は事前承認必須
```

### 環境変数での制限

```bash
# .envrc（direnvを使用）
export CLAUDE_MAX_FILE_SIZE=1048576  # 1MB
export CLAUDE_ALLOWED_DIRS="/workspace,/tmp"
export CLAUDE_DENIED_PATTERNS="*.env,*.key,*.pem"
```

## 操作権限の階層管理

### レベル1：読み取りのみ

```json
{
  "permissions": {
    "read": true,
    "write": false,
    "execute": false,
    "network": false
  }
}
```

### レベル2：ファイル編集可

```json
{
  "permissions": {
    "read": true,
    "write": true,
    "execute": false,
    "network": false
  }
}
```

### レベル3：完全な権限（サンドボックス内のみ）

```json
{
  "permissions": {
    "read": true,
    "write": true,
    "execute": true,
    "network": true
  },
  "sandbox": true  # サンドボックス内でのみ許可
}
```

## 設定の確認チェックリスト

```markdown
## AIツールセキュリティチェックリスト

### Cursor
- [ ] 学習データ使用を無効化
- [ ] テレメトリ送信を無効化
- [ ] .cursorignoreで機密ファイルを除外
- [ ] .cursorrulesでルール設定

### GitHub Copilot
- [ ] Enterprise版を使用（または個人版で学習無効化）
- [ ] .gitattributesで機密ファイルを除外
- [ ] VSCode設定で除外言語を指定

### Claude
- [ ] API使用（claude.aiより安全）
- [ ] 機密情報の自動マスク処理を実装

### ChatGPT
- [ ] Enterprise版を使用（推奨）
- [ ] 個人版の場合は学習無効化
- [ ] Custom Instructionsでルール設定

### Claude Code
- [ ] .claude/instructions.mdでルール設定
- [ ] サンドボックス環境で実行
- [ ] 環境変数で制限設定
```

## まとめ

| ツール | 推奨設定 |
|-------|---------|
| Cursor | プライバシーモード + .cursorignore |
| GitHub Copilot | Enterprise版 + 除外設定 |
| Claude | デフォルトでセキュア（APIキーマスク推奨） |
| ChatGPT | Enterprise版 + Custom Instructions |
| Claude Code | .claude/instructions.md + サンドボックス |

**重要な原則**：
1. 学習データとして使用されない設定を必ず有効化
2. 機密ファイルは除外設定で保護
3. 操作権限は必要最小限に制限
4. 企業利用はEnterprise版またはビジネス版を使用

次のセクションでは、運用面での機密情報の取り扱いルールを学びます。
