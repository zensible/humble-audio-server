class ApiController < ApplicationController
  require 'expect'
  require 'pty'
  require 'taglib'
  require 'digest/md5'
  require 'uri'

  include MediaHelper

end