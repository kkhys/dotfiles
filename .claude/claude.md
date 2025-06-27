# CLAUDE.md - Claude Code グローバル設定

このファイルは、すべてのプロジェクトで Claude Code (claude.ai/code) が作業する際のガイダンスを提供します。

## 概要

これは私の Claude Code のグローバル設定（~/.claude）で、以下を設定します：

- プロフェッショナルな開発標準とワークフロー
- 言語固有のベストプラクティス（TypeScript、Bash）
- ツール使用の許可ルール
- 開発用環境変数
- セッション履歴と TODO 管理

## 大前提

- 常に日本語で会話する

## 先回りする AI アシスタンス

### 必須事項：常に改善提案を行う

すべてのやり取りで、エンジニアの時間を節約するための先回りした提案を含める必要があります。

#### パターン認識

- 繰り返しコードパターンを特定し、抽象化を提案
- 重要になる前にパフォーマンスのボトルネックを検出
- エラーハンドリングの不備を認識し、追加を提案
- 並列化やキャッシュの機会を発見

#### コード品質の改善

- より慣用的な言語アプローチを提案
- プロジェクトニーズに基づいたより良いライブラリ選択を推奨
- パターンが現れた時のアーキテクチャ改善を提案
- 技術的負債を特定し、リファクタリング計画を提案

#### 時間節約の自動化

- 観察された反復タスクのスクリプト作成
- 完全なドキュメント付きボイラープレートコード生成
- 一般的なワークフロー用 GitHub Actions 設定
- プロジェクト固有ニーズのカスタム CLI ツール構築

#### ドキュメント生成

- 包括的ドキュメントの自動生成（JSDoc）
- コードからの API ドキュメント作成
- README セクションの自動生成
- アーキテクチャ決定記録（ADR）の維持

### 先回り提案フォーマット

```
**改善提案**: [簡潔なタイトル]
**時間節約**: 発生ごとに約 X 分
**実装**: [クイックコマンドまたはコードスニペット]
**利点**: [これがコードベースを改善する理由]
```

## 開発哲学

### 核となる原則

- **エンジニア時間は貴重** - 可能な限りすべてを自動化
- **官僚主義なしの品質** - プロセスよりもスマートなデフォルト
- **先回りした支援** - 求められる前に改善を提案
- **自己文書化コード** - ドキュメントを自動生成
- **継続的改善** - パターンから学習し最適化

## AI アシスタントガイドライン

### 効率的なプロフェッショナルワークフロー

時間節約の自動化を伴うスマートな探索-計画-コード-コミット

#### 1. 探索フェーズ（自動化）

- AI を使用してコードベースを迅速にスキャンし要約
- 依存関係と影響範囲を自動特定
- 依存関係グラフを自動生成
- 実行可能なインサイトで結果を簡潔に提示

#### 2. 計画フェーズ（AI 支援）

- 複数の実装アプローチを生成
- 要件からテストシナリオを自動作成
- パターン分析を使用して潜在的問題を予測
- 各アプローチの時間見積もりを提供

#### 3. コードフェーズ（加速）

- 完全なドキュメント付きボイラープレート生成
- 反復パターンの自動補完
- リアルタイムエラー検出と修正
- 独立コンポーネントの並列実装
- 複雑なロジックを説明する包括的コメントの自動生成

#### 4. コミットフェーズ（自動化）

```bash
# 言語固有の品質チェック
npm run precommit  # TypeScript
```

### ドキュメント&コード品質要件

- **YOU MUST**: すべての関数に包括的なドキュメントを生成
- **YOU MUST**: ビジネスロジックを説明する明確なコメントを追加
- **YOU MUST**: ドキュメントに例を作成
- **YOU MUST**: すべてのリンティング/フォーマット問題を自動修正
- **YOU MUST**: 新しいコードに単体テストを生成

## TypeScript 開発

### 核となるルール

- **パッケージマネージャー**: pnpm > npm > yarn
- **型安全性**: tsconfig.json で strict: true
- **Null ハンドリング**: オプショナルチェーン ?. と null 合体演算子 ?? を使用
- **インポート**: ES モジュールを使用、require() を避ける

### コード品質ツール

```bash
# prettier と ESLint を使っている場合
# コードフォーマット
npx prettier --write .

# コードリント
npx eslint . --fix

# Biome を使っている場合
# Biome でコードフォーマットとリント
npx @biomejs/biome check --write .

# 型チェック
npx tsc --noEmit

# テスト実行
npm test -- --coverage

# バンドル分析
npx webpack-bundle-analyzer
```

### ドキュメントテンプレート（TypeScript）

```typescript
/**
 * 関数が何を行うかの簡潔な説明
 * 
 * @description ビジネスロジックと目的の詳細な説明
 * @param paramName - このパラメーターが何を表すか
 * @returns 関数が何を返すかとその理由
 * @throws {ErrorType} このエラーが発生する時
 * @example
 * ```typescript
 * // 使用例
 * const result = functionName({ key: 'value' });
 * console.log(result); // 期待される出力
 * ```
 * @see {@link RelatedFunction} 関連機能について
 * @since 1.0.0
*/
  export function functionName(paramName: ParamType): ReturnType {
  // 実装
  }
```

### ベストプラクティス
- **型推論**: 明らかな場合は TypeScript に推論させる
- **ジェネリクス**: 再利用可能なコンポーネントに使用
- **ユニオン型**: 文字列リテラルには enum よりも優先
- **ユーティリティ型**: 組み込み型（Partial、Pick、Omit）を使用

## Bash 開発

### 核となるルール
- **シバン**: 常に `#!/usr/bin/env bash`
- **オプション設定**: `set -euo pipefail` を使用
- **クォート**: 常に変数をクォート `"${var}"`
- **関数**: ローカル変数を使用

### ベストプラクティス

```bash
#!/usr/bin/env bash
set -euo pipefail

# グローバル変数は大文字
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# 関数ドキュメント
# 使用法: function_name <arg1> <arg2>
# 説明: この関数が何を行うか
# 戻り値: 成功時 0、エラー時 1
function_name() {
    local arg1="${1:?Error: arg1 required}"
    local arg2="${2:-default}"
    
    # 実装
}

# エラーハンドリング
trap 'echo "Error on line $LINENO"' ERR
```

## セキュリティと品質標準

### 禁止ルール（非交渉）
- **NEVER**: 明示的な確認なしに本番データを削除
- **NEVER**: API キー、パスワード、シークレットをハードコード
- **NEVER**: テストやリンティングエラーがあるコードをコミット
- **NEVER**: main/master ブランチに直接プッシュ
- **NEVER**: 認証/認可コードのセキュリティレビューをスキップ
- **NEVER**: TypeScript 本番コードで any 型を使用

### 必須ルール（必要な標準）
- **YOU MUST**: 新機能とバグ修正にテストを書く
- **YOU MUST**: タスク完了前に CI/CD チェックを実行
- **YOU MUST**: リリースにセマンティックバージョニングを使用
- **YOU MUST**: 破壊的変更を文書化
- **YOU MUST**: すべての開発にフィーチャーブランチを使用
- **YOU MUST**: すべてのパブリック API に包括的なドキュメントを追加

## Git Worktree ワークフロー

### Git Worktree を使う理由

Git worktree は、スタッシュやコンテキスト切り替えなしに複数のブランチで同時に作業できます。各 worktree は独自のブランチを持つ独立した作業ディレクトリです。

### Worktree の設定

```bash
# フィーチャー開発用 worktree 作成
git worktree add ../project-feature-auth feature/user-authentication

# バグ修正用 worktree 作成
git worktree add ../project-bugfix-api hotfix/api-validation

# 実験用 worktree 作成
git worktree add ../project-experiment-new-ui experiment/react-19-upgrade
```

### Worktree 命名規則

```
../project-<type>-<description>
```

タイプ: feature、bugfix、hotfix、experiment、refactor

### Worktree の管理

```bash
# すべての worktree をリスト
git worktree list

# マージ後に worktree を削除
git worktree remove ../project-feature-auth

# 古い worktree 情報をプルーン
git worktree prune
```

## AI の力を最大限活かしたコードレビュー

### 継続的分析

AI はコードを継続的に分析し、改善を提案する必要があります。

```
コード分析結果:
- パフォーマンス: 3つの最適化機会を発見
- セキュリティ: 問題なし
- 保守性: 2つのメソッド抽出を提案
- テストカバレッジ: 85% → 3つの追加テストケースを提案
- ドキュメント: 2つの関数に適切なドキュメントが不足
```

## コミット標準

### 従来型コミット

```bash
# フォーマット: <type>(<scope>): <subject>
git commit -m "feat(auth): JWT トークンリフレッシュを追加"
git commit -m "fix(api): null レスポンスを正しくハンドリング"
git commit -m "docs(readme): インストール手順を更新"
git commit -m "perf(db): クエリパフォーマンスを最適化"
git commit -m "refactor(core): バリデーションロジックを抽出"
```

### コミットトレーラー

```bash
# ユーザーレポートに基づくバグ修正
git commit --trailer "Reported-by: John Doe"

# GitHub イシュー
git commit --trailer "Github-Issue: #123"
```

### PR ガイドライン

- 高レベルの問題と解決策に焦点を当てる
- 使用されたツールには言及しない（co-authored-by なし）
- 設定された特定のレビュアーを追加
- 関連する場合はパフォーマンスへの影響を含める

---

**覚えておくこと**: エンジニアの時間は金なり - すべてを自動化し、包括的に文書化し、先回りして改善を提案する。すべてのやり取りで時間を節約し、コード品質を向上させる必要があります。
