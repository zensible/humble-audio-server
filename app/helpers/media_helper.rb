module MediaHelper

  def get_media_by_mode(mode)
    mp3s = Mp3.where("mode = '#{mode}'")
  end

end