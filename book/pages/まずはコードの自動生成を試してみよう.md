# まずはコードの自動生成を試してみよう

## はじめに

AI駆動開発の威力を体感する最良の方法は、実際にコードを生成してみることです。この章では、開発環境の準備なしに、自然言語の指示だけでオセロゲームを作成します。

## 目標

**作るもの：** HTML + CSS + JavaScript で動作するオセロゲーム

**特徴：**
- 開発環境不要（ブラウザだけでOK）
- 1つのHTMLファイルで完結
- すぐに遊べる

**学べること：**
- AIへの効果的な指示の出し方
- 段階的な機能追加
- エラー修正の依頼方法

## 使用するAIツール

以下のいずれかを使います：

- **ChatGPT**（おすすめ：初心者向け）
- **Claude**（高品質な出力）
- **Cursor**（エディタで直接編集）

この例では ChatGPT を使って説明します。

## ステップ1：基本的なオセロゲームの生成

### プロンプト

```
HTML + CSS + JavaScript で完結するオセロゲームを作成してください。

要件：
- 1つのHTMLファイルで完結
- 8x8のボード
- 黒と白のコマ
- 標準的なオセロのルール
- クリックでコマを配置
- ターン表示
- ゲーム終了時に勝敗を表示

シンプルで分かりやすいコードにしてください。
```

### AIの出力

AIが以下のようなコードを生成します：

```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>オセロゲーム</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 20px;
            background-color: #f0f0f0;
        }
        
        h1 {
            color: #333;
        }
        
        #game-info {
            margin: 20px 0;
            font-size: 18px;
            font-weight: bold;
        }
        
        #board {
            display: grid;
            grid-template-columns: repeat(8, 60px);
            grid-template-rows: repeat(8, 60px);
            gap: 2px;
            background-color: #2d5016;
            padding: 10px;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        }
        
        .cell {
            width: 60px;
            height: 60px;
            background-color: #3d7026;
            border: 1px solid #2d5016;
            display: flex;
            justify-content: center;
            align-items: center;
            cursor: pointer;
            transition: background-color 0.2s;
        }
        
        .cell:hover {
            background-color: #4d8036;
        }
        
        .cell.valid-move {
            background-color: #5d9046;
        }
        
        .piece {
            width: 50px;
            height: 50px;
            border-radius: 50%;
            transition: all 0.3s;
        }
        
        .black {
            background-color: #000;
            box-shadow: inset 0 -2px 5px rgba(255,255,255,0.3);
        }
        
        .white {
            background-color: #fff;
            box-shadow: inset 0 -2px 5px rgba(0,0,0,0.3);
        }
        
        #score {
            margin: 20px 0;
            display: flex;
            gap: 40px;
            font-size: 16px;
        }
        
        .score-item {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .score-piece {
            width: 30px;
            height: 30px;
            border-radius: 50%;
        }
        
        button {
            margin-top: 20px;
            padding: 10px 30px;
            font-size: 16px;
            cursor: pointer;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            transition: background-color 0.3s;
        }
        
        button:hover {
            background-color: #45a049;
        }
    </style>
</head>
<body>
    <h1>オセロゲーム</h1>
    <div id="game-info">黒のターン</div>
    <div id="score">
        <div class="score-item">
            <div class="score-piece black"></div>
            <span id="black-score">2</span>
        </div>
        <div class="score-item">
            <div class="score-piece white"></div>
            <span id="white-score">2</span>
        </div>
    </div>
    <div id="board"></div>
    <button onclick="resetGame()">新しいゲーム</button>

    <script>
        const BOARD_SIZE = 8;
        const BLACK = 1;
        const WHITE = 2;
        const EMPTY = 0;
        
        let board = [];
        let currentPlayer = BLACK;
        let gameOver = false;
        
        // ボードの初期化
        function initBoard() {
            board = Array(BOARD_SIZE).fill(null).map(() => Array(BOARD_SIZE).fill(EMPTY));
            
            // 初期配置
            const mid = BOARD_SIZE / 2;
            board[mid-1][mid-1] = WHITE;
            board[mid-1][mid] = BLACK;
            board[mid][mid-1] = BLACK;
            board[mid][mid] = WHITE;
            
            currentPlayer = BLACK;
            gameOver = false;
            renderBoard();
            updateInfo();
        }
        
        // ボードの描画
        function renderBoard() {
            const boardElement = document.getElementById('board');
            boardElement.innerHTML = '';
            
            for (let row = 0; row < BOARD_SIZE; row++) {
                for (let col = 0; col < BOARD_SIZE; col++) {
                    const cell = document.createElement('div');
                    cell.className = 'cell';
                    cell.dataset.row = row;
                    cell.dataset.col = col;
                    
                    if (isValidMove(row, col, currentPlayer)) {
                        cell.classList.add('valid-move');
                    }
                    
                    cell.addEventListener('click', () => handleCellClick(row, col));
                    
                    if (board[row][col] !== EMPTY) {
                        const piece = document.createElement('div');
                        piece.className = `piece ${board[row][col] === BLACK ? 'black' : 'white'}`;
                        cell.appendChild(piece);
                    }
                    
                    boardElement.appendChild(cell);
                }
            }
        }
        
        // セルクリック処理
        function handleCellClick(row, col) {
            if (gameOver || board[row][col] !== EMPTY || !isValidMove(row, col, currentPlayer)) {
                return;
            }
            
            makeMove(row, col, currentPlayer);
            currentPlayer = currentPlayer === BLACK ? WHITE : BLACK;
            
            // 相手がパスの場合
            if (!hasValidMove(currentPlayer)) {
                currentPlayer = currentPlayer === BLACK ? WHITE : BLACK;
                
                // 両方パスの場合はゲーム終了
                if (!hasValidMove(currentPlayer)) {
                    endGame();
                    return;
                }
            }
            
            renderBoard();
            updateInfo();
        }
        
        // 手を打つ
        function makeMove(row, col, player) {
            board[row][col] = player;
            
            const directions = [
                [-1, -1], [-1, 0], [-1, 1],
                [0, -1],           [0, 1],
                [1, -1],  [1, 0],  [1, 1]
            ];
            
            for (const [dr, dc] of directions) {
                flipPieces(row, col, dr, dc, player);
            }
        }
        
        // コマを裏返す
        function flipPieces(row, col, dr, dc, player) {
            const opponent = player === BLACK ? WHITE : BLACK;
            const toFlip = [];
            let r = row + dr;
            let c = col + dc;
            
            while (r >= 0 && r < BOARD_SIZE && c >= 0 && c < BOARD_SIZE) {
                if (board[r][c] === EMPTY) {
                    return;
                }
                if (board[r][c] === opponent) {
                    toFlip.push([r, c]);
                } else {
                    // 自分のコマに到達
                    for (const [fr, fc] of toFlip) {
                        board[fr][fc] = player;
                    }
                    return;
                }
                r += dr;
                c += dc;
            }
        }
        
        // 有効な手かチェック
        function isValidMove(row, col, player) {
            if (board[row][col] !== EMPTY) {
                return false;
            }
            
            const opponent = player === BLACK ? WHITE : BLACK;
            const directions = [
                [-1, -1], [-1, 0], [-1, 1],
                [0, -1],           [0, 1],
                [1, -1],  [1, 0],  [1, 1]
            ];
            
            for (const [dr, dc] of directions) {
                let r = row + dr;
                let c = col + dc;
                let hasOpponent = false;
                
                while (r >= 0 && r < BOARD_SIZE && c >= 0 && c < BOARD_SIZE) {
                    if (board[r][c] === EMPTY) {
                        break;
                    }
                    if (board[r][c] === opponent) {
                        hasOpponent = true;
                    } else {
                        if (hasOpponent) {
                            return true;
                        }
                        break;
                    }
                    r += dr;
                    c += dc;
                }
            }
            
            return false;
        }
        
        // 有効な手があるかチェック
        function hasValidMove(player) {
            for (let row = 0; row < BOARD_SIZE; row++) {
                for (let col = 0; col < BOARD_SIZE; col++) {
                    if (isValidMove(row, col, player)) {
                        return true;
                    }
                }
            }
            return false;
        }
        
        // スコアを計算
        function countPieces() {
            let black = 0, white = 0;
            for (let row = 0; row < BOARD_SIZE; row++) {
                for (let col = 0; col < BOARD_SIZE; col++) {
                    if (board[row][col] === BLACK) black++;
                    if (board[row][col] === WHITE) white++;
                }
            }
            return { black, white };
        }
        
        // 情報表示を更新
        function updateInfo() {
            const { black, white } = countPieces();
            document.getElementById('black-score').textContent = black;
            document.getElementById('white-score').textContent = white;
            
            if (gameOver) {
                const info = document.getElementById('game-info');
                if (black > white) {
                    info.textContent = `ゲーム終了！黒の勝ち！(${black} - ${white})`;
                } else if (white > black) {
                    info.textContent = `ゲーム終了！白の勝ち！(${white} - ${black})`;
                } else {
                    info.textContent = `ゲーム終了！引き分け！(${black} - ${white})`;
                }
            } else {
                document.getElementById('game-info').textContent = 
                    currentPlayer === BLACK ? '黒のターン' : '白のターン';
            }
        }
        
        // ゲーム終了
        function endGame() {
            gameOver = true;
            updateInfo();
        }
        
        // ゲームリセット
        function resetGame() {
            initBoard();
        }
        
        // ゲーム開始
        initBoard();
    </script>
</body>
</html>
```

### 試してみる

1. 上記のコードをコピー
2. テキストエディタに貼り付け
3. `othello.html` として保存
4. ブラウザで開く

**おめでとうございます！** 数秒で動作するオセロゲームが完成しました。

## ステップ2：機能を追加する

### 追加機能の例

ゲームが動いたら、さらに機能を追加してみましょう。

#### 例1：アニメーション追加

**プロンプト：**
```
コマが裏返る時のアニメーションを追加してください。
回転するアニメーションにして、滑らかに動くようにしてください。
```

#### 例2：サウンド追加

**プロンプト：**
```
コマを置いた時の効果音を追加してください。
Web Audio APIを使って、シンプルなクリック音を生成してください。
```

#### 例3：AI対戦機能

**プロンプト：**
```
コンピュータと対戦できる機能を追加してください。

要件：
- 「1人プレイ」「2人プレイ」のモード選択
- シンプルな思考アルゴリズム（ランダムまたは基本的な評価関数）
- コンピュータの手番は1秒後に自動的に打つ
```

#### 例4：デザイン改善

**プロンプト：**
```
より現代的でスタイリッシュなデザインに変更してください。

要素：
- グラデーション背景
- シャドウ効果
- ホバーアニメーション
- レスポンシブデザイン（スマホ対応）
```

## ステップ3：エラーが出た場合

### エラー修正の依頼方法

もしエラーが出たら、以下のように伝えます：

```
以下のエラーが出ました：
[エラーメッセージをコピペ]

このエラーを修正してください。
```

または

```
コマをクリックしても配置されません。
クリックイベントが動作していないようです。
修正してください。
```

**ポイント：**
- 具体的な症状を伝える
- エラーメッセージをそのまま貼り付ける
- どの操作で問題が起きたか説明する

## ステップ4：コードの理解を深める

### AIに質問する

```
このコードの以下の部分を説明してください：
[該当コードを貼り付け]
```

```
isValidMove関数はどのように動作していますか？
詳しく説明してください。
```

```
このゲームのアルゴリズムを改善する方法を教えてください。
```

## 学んだこと

### 1. 自然言語でコードが生成できる

- プログラミング知識がなくても、やりたいことを伝えるだけ
- AIが適切なコードを生成
- すぐに動くものができる

### 2. 段階的に改善できる

- まず基本形を作る
- 動作確認
- 機能追加や改善を依頼
- 繰り返し

### 3. エラーもAIが修正できる

- エラーメッセージを伝えるだけ
- AIが原因を特定
- 修正コードを提供

### 4. 学習にも使える

- コードの説明を依頼
- アルゴリズムの解説
- 改善提案

## 応用例

同じアプローチで他のゲームも作れます：

### 簡単なゲーム

- 三目並べ（Tic-Tac-Toe）
- 神経衰弱
- マインスイーパー
- テトリス
- ブロック崩し

### プロンプト例（テトリス）

```
HTML + CSS + JavaScript で完結するテトリスゲームを作成してください。

要件：
- 1つのHTMLファイルで完結
- 基本的なテトリスのルール
- キーボード操作（矢印キー、スペースキー）
- スコア表示
- ライン消去のアニメーション
- ゲームオーバー処理

シンプルで分かりやすいコードにしてください。
```

## 次のステップ

このアプローチに慣れたら：

1. **より複雑なアプリケーション**
   - ToDoアプリ
   - タイマーアプリ
   - 計算機アプリ

2. **実用的なツール**
   - マークダウンエディタ
   - カラーピッカー
   - 画像リサイザー

3. **バックエンド連携**
   - API連携
   - データベース利用
   - 認証機能

4. **本格的な開発環境**
   - Cursorで開発
   - GitHubで管理
   - デプロイまで

## まとめ

**今日学んだこと：**

✓ 自然言語でコードが生成できる
✓ 開発環境なしでも動くものが作れる
✓ 段階的に改善していける
✓ エラーもAIが修正してくれる

**重要なポイント：**

1. **具体的に指示する**
   - 曖昧な指示より、詳細な要件
   - 期待する動作を明確に

2. **段階的に進める**
   - まず基本形
   - 動作確認
   - 機能追加

3. **エラーを恐れない**
   - エラーが出ても大丈夫
   - AIに修正を依頼すればいい

4. **質問しながら学ぶ**
   - コードの意味を質問
   - 理解を深める

これがAI駆動開発の第一歩です！
