class Folder < ApplicationRecord
  def to_h
  	hsh = self.attributes
  	hsh["bookmark"] = JSON.load(hsh["bookmark"] || "{}")
  	hsh
  end
end
