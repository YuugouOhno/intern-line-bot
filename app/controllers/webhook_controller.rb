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

    events.each do |event|
      case event
      # グループ参加時
      when Line::Bot::Event::Join
        group_id = event['source']['groupId']
        group = Group.create(group_id: group_id)
      # グループ退会時
      when Line::Bot::Event::Leave
        group_id = event['source']['groupId']
        Group.find_by(group_id: group_id).destroy
      # メッセージ受信時
      when Line::Bot::Event::Message
        if event['source']['type'] == 'group'
          group = Group.find_by(group_id: event['source']['groupId'])
          message_type = event["message"]["type"]
          user_id = event['source']['userId']
          text = event["message"]["text"]
          message = Message.create(group_id: group.id, message_type: message_type, user_id: user_id, text: text)
        else
          message = {
            type: 'text',
            text: 'グループに招待してご利用ください'
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    end
    head :ok
  end

  private
    def client
      @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
    end
end
