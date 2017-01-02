class HomeController < ApplicationController
  require 'expect'
  require 'pty'
  require 'taglib'
  require 'digest/md5'
  require 'uri'

  include PythonHelper
  include MediaHelper

  skip_before_filter :verify_authenticity_token, :only => [:play_media]

  def index

  end

  def refresh_devices
    # Wait until terminal is ready

    @devices = JSON.parse(run_py($get_devices))
  end

  def get_devices
    devices = $redis.get("devices")
    if devices.blank?
      refresh_devices()
      devices = $redis.get("devices")
    end
    render :json => devices
  end

  def template
    template_name = params[:template_name]

    render "templates/#{template_name}", locals: {  }, :layout => nil
  end

  def get_media
    mode = params[:mode]
    mp3s = get_media_by_mode(mode)
    render :json => mp3s
  end

  def cur_cast
    $redis.get("cur_cast")
  end

  def play_media
    id = params[:id]
    url = params[:url]
    select_cast(cur_cast())
    play_url(url)
  end

  def stop_media
    select_cast(cur_cast())
    cast_stop()
    render :json => { success: true }
  end

  def pause_media
    select_cast(cur_cast())
    cast_pause()    
    render :json => { success: true }
  end

  def sel_cast
    friendly_name = params[:friendly_name]
    select_cast(friendly_name)
    render :json => { success: true }
  end


  # SYNC STUFF
  # SYNC STUFF
  # SYNC STUFF
  # SYNC STUFF
  # SYNC STUFF
  def get_attributes(mode, path, md5)
    TagLib::FileRef.open(path) do |fileref|
      if fileref.null?
        return nil
      else
        tag = fileref.tag

        return {
          :mode => mode,
          :rank => 0,
          :title => tag.title,
          :album => tag.album,
          :track_nr => tag.track,
          :artist => tag.artist,
          :year => tag.year,
          :genre => tag.genre,
          :length_seconds => fileref.audio_properties.length,
          :path => path,
          :filename => File.basename(path),
          :md5 => md5
        }
      end
    end  # File is automatically closed at block end
  end

  def refresh_media
    audio_dir = "/Users/eightfold/multiroom/public/audio/"
    audio_dir = audio_dir.gsub(/\/$/, '') # Strip trailing /

    stats = {
      :added => 0,
      :existing => 0,
      :moved => 0,
      :error => 0,
      :removed => 0,
      :total => 0
    }

    mode = params[:mode]
    case mode
    when "white-noise"
      existing = Mp3.where("mode = 'white-noise'")
      hsh_existing_path = {}
      hsh_existing_md5 = {}
      to_delete = []
      existing.each do |mp3|
        hsh_existing_path[mp3.path] = mp3
        hsh_existing_md5[mp3.md5] = mp3
        if !File.exist?(mp3.path)
          to_delete.push(mp3)
        end
      end
      Dir.glob("#{audio_dir}/white-noise/*.mp3").each do |dir|
        if hsh_existing_path[dir]
          stats[:existing] += 1
          puts "Already in DB: #{dir}"
        else
          md5 = Digest::MD5.hexdigest(File.read(dir))
          attrs = get_attributes(mode, dir, md5)
          if attrs.nil?
            stats[:error] += 1
            Rails.logger.warn("== Could not read file information: #{dir}. Not an MP3?")
          else
            if mp3 = hsh_existing_md5[md5]
              stats[:moved] += 1
              puts "Mp3 has been moved or renamed, updating record #{mp3.id} for new location"
              mp3.update_attributes(attrs)
              to_delete.delete(mp3) # Since the file was only moved, don't removed its record
            else
              stats[:added] += 1
              puts "Adding new mp3 to DB: #{dir}"
              Mp3.create(attrs)
            end
          end
        end
      end

      # File doesn't exist on disk or elsewhere in DB, delete its record
      to_delete.each do |mp3|
        mp3.destroy()
      end
      stats[:removed] = to_delete.length
      Rails.logger.warn("WE NEED TO DELETE: #{to_delete}")
    end

    stats[:total] = stats[:existing] + stats[:added]

    render :json => stats
  end



end
