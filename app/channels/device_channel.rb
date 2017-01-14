class DeviceChannel < ApplicationCable::Channel
  # Called when the consumer has successfully
  # become a subscriber of this channel.
  def subscribed
    stream_from "device"
    sleep 0.1 # Seems to be necessary to make the following work reliably
    Rails.logger.info("==== SUBSCRIBED DEVICE")
    #ActionCable.server.broadcast "device", $redis.get("devices")
    Device.broadcast()
  end

  def connect
  end

  #def disconnect
  #  # Any cleanup work needed when the cable connection is cut.
  #end

end

