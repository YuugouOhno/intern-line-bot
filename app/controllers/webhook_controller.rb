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
        group = Group.create(group_id: group_id)
      # グループ退会時
      when Line::Bot::Event::Leave
        group_id = event['source']['groupId']
        Group.find_by(group_id: group_id).destroy
      # メッセージ受信時
      when Line::Bot::Event::Message
        puts client
        group = Group.find_by(group_id: event['source']['groupId'])
        message_type = event["message"]["type"]
        text = event["message"]["text"]
        message = Message.create({group_id: group.id, message_type: message_type, text: text})
      end
    }
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
