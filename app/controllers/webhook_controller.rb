require 'line/bot'

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head 470
    end
    
    events = client.parse_events_from(body)

    events.each { |event|
      case event
      # グループ参加時
      when Line::Bot::Event::Join
        group_id = event['source']['groupId']
        @group = Group.create({group_id: group_id})
      # グループ退会時
      when Line::Bot::Event::Leave
        group_id = event['source']['groupId']
        Group.where({group_id: group_id}).destroy_all
      # メッセージ受信時
      when Line::Bot::Event::Message
        group = Group.find_by(group_id: event['source']['groupId'])
        posted_at = Time.now
        message_type = event["message"]["type"]
        text = event["message"]["text"]
        @message = Message.create({group_id: group.id, posted_at: posted_at, message_type: message_type, text: text})
      end
    }
    head :ok
  end

  private
    def message(event)
      case event["message"]["type"]
      when "text"
        message = {
          type: 'text',
          text: pickup_random_text('positive')
        }
        client.reply_message(event['replyToken'], message)
        number = client.get_number_of_message_deliveries("20221020")
      else
        message = {
          type: "sticker",
          packageId: STICKER_PACKAGE_ID,
          stickerId: pickup_random_sticker_id
        }
        client.reply_message(event['replyToken'], message)
      end
    end
  
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
end
