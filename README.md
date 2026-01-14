# Harvest - Discord思考整理Bot（エース先輩）

Discordの「殴り書き」チャンネルに投稿された雑多なメッセージを収集し、Gemini AI（エース先輩）がタスクやアイデアとして整理して毎朝届けてくれるBotです。

## 特徴
- **サーバーレス**: GitHub Actionsで完結するため、サーバー代はかかりません（無料枠内で運用可能）。
- **AI搭載**: Gemini 2.0 Flash Lite を使用し、高速かつ安価にコンテキストを解析します。
- **自動化**: 毎日朝7時（JST）に自動実行されます。手動実行も可能です。
- **エース先輩**: 親しみやすい先輩キャラクターとして、優しくタスクをまとめてくれます。

## セットアップ手順

1. **事前準備**
   - **Discord Bot Token**: [Discord Developer Portal](https://discord.com/developers/applications)で取得（※Bot設定で **Message Content Intent** を必ずONにしてください）。
   - **Gemini API Key**: [Google AI Studio](https://aistudio.google.com/)で取得。
   - **チャンネルID**:
     - 収集元チャンネルID（カンマ区切りで複数可）
     - 通知先チャンネルID（開発者モードをONにしてチャンネルを右クリック→「IDをコピー」で取得）

2. **GitHubリポジトリ**
   - このコードをGitHubのリポジトリにプッシュします。

3. **Secretsの設定**
   リポジトリの `Settings > Secrets and variables > Actions` に以下の環境変数を追加してください。
   - `DISCORD_BOT_TOKEN`: Botトークン
   - `GEMINI_API_KEY`: Gemini APIキー
   - `SOURCE_CHANNEL_IDS`: 収集元のチャンネルID (例: `123456789,987654321`)
   - `TARGET_CHANNEL_ID`: 結果を投稿するチャンネルID

## 運用について
このシステムはGitHub Actionsのバッチ処理として動作します。
常時起動のサーバーを持たないため、ボタン操作などのリアルタイムなインタラクション機能は含まれていません。
「書き溜めたものを翌朝受け取る」というサイクルに特化しています。
