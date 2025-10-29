# サンドボックス環境の構築

AI駆動開発には、大きく分けて3つのセキュリティリスクがあります：

1. **情報漏洩**：AIプロバイダーへの機密情報・個人情報の送信
2. **コード/データ破壊**：AIが生成した破壊的なコードの実行（`rm -rf /`、`DROP DATABASE`等）
3. **意図せぬコード生成**：セキュリティホール（SQLインジェクション、XSS等）やバックドアの埋め込み

**結論：これら3つのリスクは、サンドボックス環境を正しく構築・運用することで全て対応できます。**

## サンドボックス環境とは

**サンドボックス環境＝本番環境から完全に隔離された環境**

具体的には：
- 壊れても問題のない環境（Dockerコンテナ等）
- 本番DB、本番サーバーへの通信が遮断されている
- いつでも作り直せる使い捨て環境

**加えて、重要な運用ルール：**
- サンドボックス環境に持ち込むデータは、**必ず機密情報をマスキング**する
  - 例：メールアドレスを `test@example.com` に置換
  - 例：決済情報テーブルを除外
  - 例：APIキーをダミー値に置換

この隔離環境と運用ルールを組み合わせることで、**AIツールを安全に使用できます。**

## サンドボックス環境が3つのリスクを解決する仕組み

### リスク1：情報漏洩を防ぐ

**問題**：本番環境の個人情報・機密情報がAIプロバイダーに送信されてしまう

**解決策**：
サンドボックス環境
本番環境のデータはマスキングした上
```
本番環境のデータ
  ↓ 機密情報をマスキング
サンドボックス環境（マスキング済みデータ）
  ↓ AIに送信されても安全
AIプロバイダー（OpenAI、Anthropic等）
```

**大前提**：サンドボックス環境に持ち込むデータは、**必ず個人情報・機密情報をマスキング**してから使用します。これがサンドボックス環境の定義の一部です。

### リスク2：コード/データ破壊を防ぐ

**問題**：AIが生成した破壊的なコードが本番環境で実行されてしまう

```bash
# AIが生成した破壊的なコード例
rm -rf /  # システム全体が削除される
DROP DATABASE production;  # 本番DBが削除される
while true; do fork; done  # システムダウン
```

**解決策**：
```
AIコード生成
  ↓
サンドボックス環境で実行（本番DBにアクセス不可）
  ↓ 破壊されてもサンドボックスだけ
本番環境は無傷
```

サンドボックス環境は**本番に通信できない**ため、AIが破壊的なコードを生成しても本番には影響しません。

### リスク3：意図せぬコード生成を防ぐ

**問題**：AIがセキュリティホールを含むコードを生成してしまう

```javascript
// AIが生成したコード（SQLインジェクション脆弱性あり）
const query = `SELECT * FROM users WHERE email = '${email}'`;
db.execute(query);
```

**解決策**：

サンドボックス環境でテストすることで、本番に適用する前に脆弱性を発見・修正できます。

```
AIコード生成
  ↓
サンドボックスでテスト
  ↓ 脆弱性を発見
修正
  ↓ 安全確認
本番環境に適用
```

## サンドボックス環境の2つの用途

### 用途1：AIコード生成時の隔離環境

AIが生成したコードを安全にテストする環境。

```
AIコード生成
  ↓
サンドボックスでテスト
  ↓ 安全確認
本番環境に適用
```

### 用途2：本番バグ調査時の隔離環境

本番環境のデータ（ダンプ、ログ）をコピーし、AIで調査する環境。

```
本番環境
  ↓ データコピー
サンドボックス環境（本番へのアクセス不可）
  ↓
AIで調査
```

どちらの用途でも、**本番環境を保護する**ことが目的です。

## サンドボックス環境で得られる2つのメリット

サンドボックス環境を構築することで、2つの大きなメリットが得られます。

### メリット1：リスクの完全回避（最重要）

**これが最も重要な目的です。**

サンドボックス環境であれば、AIが何をやらかしても本番環境には影響しません。

### メリット2：AIの完全自律実行モードが使える（生産性の爆発的向上）

通常、AIは危険なコマンドを実行する際、人間に確認を求めます：

```
AI: 「rm -rf /tmp/old_files を実行してもよろしいですか？」
人間: 「はい」
AI: 「実行しました」
```

この確認作業は安全ですが、**生産性が低い**です。あなたが会議中、就寝中、トイレに行っている間、AIは待機してしまいます。

#### 完全自律実行モードとは

Claude Codeのような自律性の高いAIには、**完全自律実行モード**があります：

```bash
# 人間の許可を求めずに完全自律実行
claude --dangerously-skip-permissions
```

このモードでは：
- AIが人間に確認を求めない
- あなたが寝ている間もAIがタスクを進める
- あなたが会議中もAIがタスクを進める
- **生産性が桁違いに向上する**

#### 完全自律実行モードのリスク

ただし、このモードは**非常に危険**です：

| リスク | 具体例 |
|-------|--------|
| **本番環境への影響** | 本番DBを勝手に更新、本番サーバーで破壊的コマンド実行 |
| **ファイルシステム破壊** | `rm -rf /` を実行してシステム全体削除 |
| **機密情報の送信** | 個人情報をどこかに送信してしまう |

一応、設定でAIの行動を制限することはできますが、**最終的にはAIが暴走して何をやらかすかわからない**という前提で考えるべきです。

#### サンドボックス環境なら安全に使える

**サンドボックス環境であれば、完全自律実行モードを安全に使えます：**

```
ローカルPC
  ↓
Dockerサンドボックス環境（隔離・本番アクセス不可）
  ↓
claude --dangerously-skip-permissions で完全自律実行
  ↓ AIが暴走しても...
本番環境は無傷（サンドボックスだけが影響を受ける）
```

**結論**：

1. **最優先目的**：リスクを完全に回避する
2. **副次的メリット**：完全自律実行モードを解放することで、AIの生産性が爆発的に向上（寝ている間もAIがタスクを進める）

**だからこそ、サンドボックス環境でAIを動かすことを強く強くお勧めします。**

## Dockerによるサンドボックス環境

### Dockerとは

- コンテナ型の仮想化技術
- ホストOSから隔離された環境
- 軽量で高速
- 簡単に作成・削除可能

### 基本的なサンドボックス構成

```
ホストOS（本番環境）
    ↓ 完全に隔離
Dockerコンテナ（サンドボックス）
    ↓ この中でAIを使用
    → 破壊されても本番環境に影響なし
```

## サンドボックス環境の構築手順

### ステップ1：Dockerのインストール

```bash
# macOS
brew install --cask docker

# Ubuntu
sudo apt-get update
sudo apt-get install docker.io docker-compose

# Windows
# Docker Desktopをインストール
```

### ステップ2：サンドボックス用のDockerfile作成

```dockerfile
# Dockerfile
FROM ubuntu:22.04

# 基本的なツールをインストール
RUN apt-get update && apt-get install -y \
    curl \
    git \
    nodejs \
    npm \
    python3 \
    python3-pip \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリ
WORKDIR /workspace

# 非rootユーザーで実行（セキュリティ向上）
RUN useradd -m -s /bin/bash developer
USER developer

# デフォルトコマンド
CMD ["/bin/bash"]
```

### ステップ3：docker-compose.ymlの作成

```yaml
# docker-compose.yml
version: '3.8'

services:
  sandbox:
    build: .
    container_name: ai-sandbox
    volumes:
      - ./workspace:/workspace  # ホストとファイル共有
    # リソース制限（重要！）
    deploy:
      resources:
        limits:
          cpus: '2.0'      # CPU使用量を制限
          memory: 2G       # メモリ使用量を制限
    # セキュリティ設定
    security_opt:
      - no-new-privileges:true  # 特権昇格を防止
    read_only: true  # ファイルシステムを読み取り専用に
    tmpfs:
      - /tmp  # 一時ファイル用
      - /workspace/.cache  # キャッシュ用

  # 本番バグ調査用のサンドボックスDB
  sandbox-db:
    image: mysql:8.0
    container_name: sandbox-db
    environment:
      MYSQL_ROOT_PASSWORD: sandbox-password
      MYSQL_DATABASE: sandbox
    volumes:
      - sandbox-db-data:/var/lib/mysql
    # 外部からのアクセスを遮断（sandboxコンテナからのみアクセス可）
    networks:
      - sandbox-network

networks:
  sandbox-network:
    driver: bridge
    internal: true  # インターネットアクセスを完全に遮断

volumes:
  sandbox-db-data:
```

### ステップ4：サンドボックスの起動

```bash
# サンドボックスを起動
docker-compose up -d

# サンドボックスに入る
docker-compose exec sandbox bash

# 確認
pwd  # /workspace
whoami  # developer（非rootユーザー）
```

## 本番バグ調査時のセキュリティ原則

本番環境のデータをAIで調査する際は、以下の原則を必ず守ってください。

### 原則1：本番環境で直接AIツールを使わない

- 本番環境でCursor、Claude Code等のAIツールを直接使用しない
- 本番サーバーにAIツールをインストールしない
- 必ず隔離された環境にコピーしてから使う

**理由**：
AIが本番DBを勝手に更新する、本番サーバーで破壊的なコマンドを実行するなど、予期しない動作をするリスクがあります。

### 原則2：ローカル環境でもサンドボックス環境を使う

ローカル環境にAIツールがインストールされていて、かつその環境から本番にSSH接続ができてしまう場合、**AIが本番環境にアクセスできてしまうため、これも絶対にNGです。**

**悪い例**：
```
ローカルPC（AIツールあり）
  ├─ ~/.ssh/config に本番サーバーへの接続設定
  ↓ SSH接続可能
本番サーバー
  ↓ AIが本番にアクセスできてしまう（NG）
```

**良い例**：
```
ローカルPC
  ↓
Dockerサンドボックス環境（AIツールあり）
  - 本番へのSSH設定なし
  - 本番へのネットワーク接続を遮断
  - サンドボックスDBのみ接続可
  ↓ AIは隔離環境のみアクセス（OK）
```

**正しい方法**：
1. ローカル環境上に**サンドボックス環境（Docker）を立てる**
2. サンドボックス環境の中でAIツールを使う
3. サンドボックス環境からは本番に接続できないようにする（SSH設定を分離）
4. `docker-compose.yml`の`networks: internal: true`で外部通信を遮断

### 原則3：機密情報を除外・マスキングする

**除外すべきデータ**：
- 個人情報（氏名、メールアドレス、電話番号、住所）
- 決済情報、クレジットカード情報
- 認証情報（パスワード、トークン、APIキー）

**マスキング方法**：

#### 方法1：ダミーデータに置換
```bash
# SQLダンプのメールアドレスを置換
sed -E 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/test@example.com/g' dump.sql > masked_dump.sql
```

#### 方法2：機密テーブルを除外
```bash
# 決済情報テーブルを除外してダンプ
mysqldump --ignore-table=database.payments --ignore-table=database.credit_cards database > dump.sql
```

#### 方法3：ログのマスキング
```bash
# ログからトークンをマスキング
sed -E 's/Bearer [A-Za-z0-9_-]+/Bearer ***/g' production.log > masked.log
```

### 原則4：本番への通信を遮断する

サンドボックス環境から本番環境への通信を完全に遮断します。

**docker-compose.ymlの設定**：
```yaml
networks:
  sandbox-network:
    driver: bridge
    internal: true  # インターネットアクセスを完全に遮断
```

**確認方法**：
```bash
# サンドボックス内から本番にアクセスできないことを確認
docker-compose exec sandbox bash
ping production-server.com  # 失敗するはず
ssh production-server  # 失敗するはず
```

### 原則5：必ず上司・セキュリティ担当に相談する

- 本番データの取り扱いは個人判断で行わない
- データのコピーや調査方法について、必ず上司の許可を取る
- 組織のセキュリティポリシーに従う
- 不明な点があれば、セキュリティ担当者に相談

## 本番バグ調査の実践例

### シナリオ：ECサイトの決済エラーを調査

#### Step 1: 本番データを取得（運用チームが実施）

```bash
# 本番DBダンプを取得
mysqldump -h production-db -u user -p database > production_dump.sql

# 本番ログをダウンロード
scp production-server:/var/log/app/* ./logs/
```

#### Step 2: 機密情報をマスキング

```bash
# メールアドレスを置換
sed -E 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/test@example.com/g' production_dump.sql > masked_dump.sql

# 決済情報テーブルを除外済みか確認
grep -i "INSERT INTO payments" masked_dump.sql  # 何も出力されなければOK
```

#### Step 3: サンドボックス環境に復元

```bash
# サンドボックスを起動
docker-compose up -d

# ダンプを復元
docker-compose exec -T sandbox-db mysql -u root -psandbox-password sandbox < masked_dump.sql

# ログをコピー
cp logs/* workspace/logs/
```

#### Step 4: AIで調査

```bash
# サンドボックスに入る
docker-compose exec sandbox bash

# 本番に接続できないことを確認
ping production-server.com  # 失敗
ssh production-server  # 失敗

# AIツールで調査開始
cursor .  # または claude-code
```

プロンプト例：
```
「決済エラーを調査してください。

【環境】
- DB：mysql -h sandbox-db -u root -psandbox-password sandbox
- ログ：/workspace/logs/application.log

【調査手順】
1. ログから該当時間帯のエラーを検索
2. transactionsテーブルで該当レコードを確認
3. 原因を特定

必ず証拠を提示してください。」
```

#### Step 5: 調査完了後の環境削除

```bash
# サンドボックス環境を削除
docker-compose down -v

# データも完全削除
rm -rf workspace/logs masked_dump.sql
```

## AIコード生成時の使い方

### Claude Codeでサンドボックスを使用

```bash
# サンドボックス内でClaude Codeを実行
docker-compose exec sandbox bash -c "claude-code"
```

### Cursorでサンドボックスを使用

Cursorの設定：

```json
// .vscode/settings.json
{
  "terminal.integrated.defaultProfile.linux": "docker",
  "terminal.integrated.profiles.linux": {
    "docker": {
      "path": "docker",
      "args": ["exec", "-it", "ai-sandbox", "bash"]
    }
  }
}
```

これで、Cursorのターミナルが自動的にサンドボックス内で開きます。

## サンドボックスのリセット

コンテナが破壊された場合、簡単にリセットできます：

```bash
# コンテナを削除
docker-compose down

# 再作成
docker-compose up -d

# 完全にクリーンな状態に戻る
```

## まとめ

### サンドボックス環境の定義（再確認）

サンドボックス環境とは：

1. **隔離された環境**（本番から分離）
2. **本番への通信遮断**（本番DB・サーバーにアクセス不可）
3. **機密情報のマスキング**（個人情報・機密情報を除外/置換）

**この3つを満たすことで、3つのセキュリティリスク全てに対応できます。**

### 3つのリスクへの対応

| リスク | サンドボックスでの対応 | 具体的な方法 |
|-------|-----------------|------------|
| **リスク1：情報漏洩** | ✅ 対応可能 | 機密情報をマスキングしてから持ち込む（サンドボックスの定義の一部） |
| **リスク2：コード/データ破壊** | ✅ 対応可能 | 隔離環境で実行し、本番との通信を遮断 |
| **リスク3：意図せぬコード生成** | △ 一部対応可能 | セキュリティホールの検証は可能。バックドア検出は困難 |

### セキュリティ原則まとめ

1. **本番環境で直接AIツールを使わない**（リスク2対応）
2. **ローカル環境でもサンドボックス環境を使う**（リスク2対応）
3. **機密情報を除外・マスキングする**（リスク1対応）← サンドボックスの必須要件
4. **本番への通信を遮断する**（リスク2対応）← サンドボックスの必須要件
5. **必ず上司・セキュリティ担当に相談する**（全リスク対応）

### サンドボックス環境の利点

1. **機密情報漏洩を防ぐ**（リスク1対応）← マスキングを徹底
2. **AIの破壊的なコードから本番環境を保護**（リスク2対応）
3. **本番データを安全に調査できる**（リスク2対応）
4. **セキュリティホールを事前検証できる**（リスク3対応）
5. 簡単にリセット可能
6. リソース制限でシステムダウンを防止
7. 権限を最小化してセキュリティ向上

**サンドボックス環境を正しく構築・運用することで、AI駆動開発の3つのセキュリティリスクに対応できます。特に、機密情報のマスキングはサンドボックス環境の必須要件です。**
