# AIの種類

AI駆動開発でよく耳にする「機械学習」「ディープラーニング」「生成AI」「LLM」といった用語について、それぞれの違いと関係性を説明します

## AI技術の全体像

まず、これらの技術がどのような関係にあるのかを見ていきます。

```mermaid
graph TD
    subgraph AI["AI (人工知能)"]
        subgraph ML["機械学習"]
            subgraph DL["ディープラーニング"]
                subgraph GenAI["生成AI"]
                    LLM["LLM<br/>(大規模言語モデル)"]
                end
            end
        end
    end

    style AI fill:#e1f5ff
    style ML fill:#b3e5ff
    style DL fill:#80d4ff
    style GenAI fill:#00838F,color:#FFFFFF,stroke:#006064
    style LLM fill:#00838F,color:#FFFFFF,stroke:#006064
```

この図が示すように、各技術は階層構造になっています。つまり、外側の技術が内側の技術を含む関係です。

- **AI**が最も大きな概念
- その中に**機械学習**がある
- 機械学習の一種として**ディープラーニング**がある
- ディープラーニングを使った技術の1つが**生成AI**
- 生成AIの中で文章を扱うものが**LLM**

それでは、それぞれの技術を詳しく見ていきます。
