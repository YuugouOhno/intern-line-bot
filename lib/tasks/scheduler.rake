desc "heroku shedulerから最新のメッセージに対して返信する"
task :push_message => :environment do
  message = Message.order(posted_at: :desc).first
  group_id = message.group.group_id
  case message.message_type
  when "text"
    message = {
      type: 'text',
      text: pickup_random_text('positive')
    }
    client.push_message(group_id, message)
  else
    message = {
      type: "sticker",
      packageId: STICKER_PACKAGE_ID,
      stickerId: pickup_random_sticker_id
    }
    client.push_message(group_id, message)
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
