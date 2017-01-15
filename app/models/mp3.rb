class Mp3 < ApplicationRecord
  def to_h
    return {
      mode: self.mode,
      title: self.title,
      filename: self.filename,
      length_seconds: self.length_seconds,
      artist: self.artist,
      album: self.album
    }
  end
end
