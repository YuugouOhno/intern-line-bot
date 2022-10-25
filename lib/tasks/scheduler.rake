desc "heroku shedulerから最新のメッセージに対して返信する"
task :push_message => :environment do
  time_10min_ago = Time.zone.now - 10.minutes
  time_20min_ago = Time.zone.now - 20.minutes
  # 20分未満に送られたメッセージを新しい順に並べ、group_idごとに取得
  recent_message = Message.where(posted_at: time_20min_ago...).order(posted_at: "DESC").group_by{|message| message.group}
  recent_message.each do |group, messages|
    group_id = group.group_id
    # 同じグループの中で一番新しいメッセージを取得
    latest_message = messages.first
    # 最新のメッセージが現在時刻より10分以上前に送られている場合、最後の一言と判断してpush_messageを送信
    if latest_message.posted_at <= time_10min_ago
      # 最後のメッセージがテキストならテキスト、それ以外ならスタンプを送信
      case latest_message.message_type
      when "text"
        message = {
          type: 'text',
          text: pickup_random_text('positive')
        }
        client.push_message(group_id, message)
        # 個人へのメッセージを送信
        message = {
          type: 'text',
          text: "あなたの最後の一言「#{latest_message.text}」によってグループの会話が止まりました。"
        }
        client.push_message(latest_message.user_id, message)
      else
        message = {
          type: "sticker",
          packageId: STICKER_PACKAGE_ID,
          stickerId: pickup_random_sticker_id
        }
        client.push_message(group_id, message)
      end
    end
  end
  
end

private
def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

STICKER_PACKAGE_ID = 446
STICKER_ID_BEGIN = 1988
STICKER_ID_END = 2027

# ランダムなスタンプのIDを返す
def pickup_random_sticker_id
  return rand(STICKER_ID_BEGIN..STICKER_ID_END)
end

POSITIVE_TEXT_LIST = %w[なるほど 確かに そうだね すごい 最高だね 天才だわ]
NEGATIVE_TEXT_LIST = %w[何言ってんの それはない いい加減にして？ そうかなぁ]
POLITE_TEXT_LIST = %w[仰る通りです その通りですね ごもっともですね 興味深いですね 全くもって同感です]

# 任意のテキストリストからランダムに取得する
def pickup_random_text(type)
  case type
  when 'positive'
    return POSITIVE_TEXT_LIST.sample
  when 'negative'
    return NEGATIVE_TEXT_LIST.sample
  when 'polite'
    return POLITE_TEXT_LIST.sample
  end
end
