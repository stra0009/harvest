require 'bundler/setup'
Bundler.require(:default)

require 'discordrb'
require 'net/http'

require 'dotenv/load'
require 'json'
require 'date'

# Configuration
DISCORD_TOKEN = ENV['DISCORD_BOT_TOKEN']
GEMINI_API_KEY = ENV['GEMINI_API_KEY']
SOURCE_CHANNELS = ENV['SOURCE_CHANNEL_IDS']&.split(',') || []
TARGET_CHANNEL_ID = ENV['TARGET_CHANNEL_ID']

# Initialize Clients
def run
  begin
    main_logic
  rescue => e
    warn "CRITICAL ERROR: #{e.message}"
    warn e.backtrace.join("\n")
    exit(1)
  end
end

def main_logic
  if !DISCORD_TOKEN || !GEMINI_API_KEY || SOURCE_CHANNELS.empty? || !TARGET_CHANNEL_ID
    puts "Error: Missing environment variables."
    exit(1)
  end

  # 1. Collect Messages
  all_messages = []
  
  SOURCE_CHANNELS.each do |channel_id|
    puts "Fetching messages from #{channel_id}..."
    # Fetch last 100 messages (limit for simplicity, or implement pagination for time-based)
    # Using REST API directly avoids Gateway connection overhead
    begin
      msgs = JSON.parse(Discordrb::API::Channel.messages("Bot #{DISCORD_TOKEN}", channel_id, 50))
      
      # Filter for messages from last 24 hours
      one_day_ago = (DateTime.now - 1).to_s
      recent_msgs = msgs.select { |m| m['timestamp'] > one_day_ago }
      
      recent_msgs.each do |msg|
        author = msg['author']['username']
        content = msg['content']
        next if content.strip.empty?
        all_messages << "[#{msg['timestamp']}] #{author}: #{content}"
      end
    rescue => e
      puts "Error fetching channel #{channel_id}: #{e.message}"
    end
  end

  if all_messages.empty?
    puts "No recent messages found."
    return
  end

  puts "Collected #{all_messages.size} messages. Sending to Gemini..."

  # 2. Analyze with Gemini
  # 2. Analyze with Gemini (REST API Direct)
  prompt = <<~PROMPT
    あなたは優秀な先輩社員「エース」です。
    以下はDiscordチームの雑談や殴り書きのログです。
    ここから明確な「タスク」「アイデア」「バグ報告」を抽出し、リスト化してください。
    
    1. 挨拶やただの雑談は無視してください。
    2. 創作や開発や運営に関連するアクション可能な項目を特定してください。
    3. 結果は必ず有効な **JSON配列** 形式のみで返してください。
    
    フォーマット例:
    [
      {
        "title": "ログインバグの修正",
        "description": "ログイン時に500エラーが出るとの報告あり。調査が必要。",
        "priority": "高",
        "original_context": "..."
      }
    ]

    メッセージログ:
    #{all_messages.join("\n")}
  PROMPT

  begin
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=#{GEMINI_API_KEY}")
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req.body = {
      contents: [{ parts: [{ text: prompt }] }]
    }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    result = JSON.parse(res.body)
    
    if result['error']
      raise "Gemini API Error: #{result['error']['message']}"
    end

    # Extract JSON from response
    raw_response = result['candidates'][0]['content']['parts'][0]['text']
    # Clean up markdown code blocks if present
    json_str = raw_response.gsub(/```json/, '').gsub(/```/, '').strip
    tasks = JSON.parse(json_str)
  rescue => e
    puts "Error calling Gemini or parsing JSON: #{e.message}"
    puts "Raw response: #{raw_response}" if raw_response
    return
  end

  if tasks.empty?
    puts "No tasks identified."
    # Optionally notify discord there were no tasks
    return
  end

  # 3. Post to Target Channel
  puts "Found #{tasks.size} tasks. Posting to Discord..."

  # Build the report content
  header = "アナタの先輩、エースです。\n昨日のメッセージを確認して **#{tasks.size}件** のタスク候補をまとめておきました。\n\n"
  
  report_body = ""
  tasks.each do |task|
    priority_icon = case task['priority']
                    when '高', 'High' then '🔴'
                    when '中', 'Medium' then '🟡'
                    else '🔵'
                    end
    
    report_body += "### #{priority_icon} #{task['title']}\n"
    report_body += "#{task['description']}\n"
    if task['original_context']
      # Quote the original context slightly
      report_body += "> #{task['original_context'].to_s.gsub("\n", " ")}\n"
    end
    report_body += "\n"
  end

  full_message = header + report_body
  
  # Send via Net::HTTP (Handling 2000 char limit by simple splitting if needed)
  discord_uri = URI("https://discord.com/api/v10/channels/#{TARGET_CHANNEL_ID}/messages")
  http = Net::HTTP.new(discord_uri.host, discord_uri.port)
  http.use_ssl = true

  # Simple chunking loop (Discord has 2000 char limit)
  full_message.chars.each_slice(1900).map(&:join).each do |chunk|
    req = Net::HTTP::Post.new(discord_uri)
    req['Authorization'] = "Bot #{DISCORD_TOKEN}"
    req['Content-Type'] = 'application/json'
    req.body = { content: chunk }.to_json

    begin
      res = http.request(req)
      if res.code.to_i >= 400
        puts "Error sending Discord message: #{res.code} #{res.body}"
      end
    rescue => e
      puts "Network error sending to Discord: #{e.message}"
    end
    sleep 0.5
  end
  
  puts "Done!"
end

run
