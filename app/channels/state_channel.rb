class StateChannel < ApplicationCable::Channel
  # Called when the consumer has successfully
  # become a subscriber of this channel.
  def subscribed
    stream_from "state"
    sleep 0.1 # Seems to be necessary to make the following work reliably
    Rails.logger.info("==== SUBSCRIBED STATE")
    ActionCable.server.broadcast "state", $redis.get("state_shared")
  end

  def connect
  end

  #def disconnect
  #  # Any cleanup work needed when the cable connection is cut.
  #end

end

