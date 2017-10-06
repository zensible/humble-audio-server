class SyncChannel < ApplicationCable::Channel
  # Called when the consumer has successfully
  # become a subscriber of this channel.
  def subscribed
    stream_from (Rails.env.test? ? "sync_test" : "sync")
    sleep 0.1 # Seems to be necessary to make the following work reliably
    Rails.logger.info("==== SUBSCRIBED SYNC")
    Sync.broadcast()
  end

  def connect
  end

  def disconnect
    # Any cleanup work needed when the cable connection is cut.
  end
end

