#!/usr/bin/ruby

require 'optparse'

class PhotoStreamBackUpper
  require 'fileutils'
  require 'rsync'
  require 'shellwords'
  require 'sqlite3'

  PHOTO_STREAM_DIR="#{ENV['HOME']}/Library/Containers/com.apple.cloudphotosd/Data/Library/Application Support/com.apple.cloudphotosd/services/com.apple.photo.icloud.sharedstreams"

  def initialize(streams, destination, verbose = false)
    raise ArgumentError, "Unable to read destination directory" unless File.readable? File.expand_path(destination)
    @destination = File.expand_path(destination)

    if streams.nil? 
      @streams = get_all_ps_names
      puts "No streams selected, defaulting to all: '#{@streams.join("', '")}'"
    elsif streams == ['all']
      @streams = get_all_ps_names
    else
      @streams = streams
    end

    @verbose = verbose
  end

  # Grabs the filename for the Photo Stream tracking SQLITE database
  def get_ps_db_file
    return @ps_sql_file if @ps_sql_file

    share_dir = "#{PHOTO_STREAM_DIR}/coremediastream-state/"

    # Probably a lazy way to do this with the .last method, but all 
    # you should ever get out of this query is ['.', '..', interesting_dir]
    sqlite_dir = Dir.entries(share_dir).select do |entry| 
      File.directory? File.join(share_dir, entry) 
    end.last

    @ps_sql_file = "#{share_dir}#{sqlite_dir}/Model.sqlite"
  end

  # Returns a SQLite DB object if one hasn't already been created
  def get_db_conn
    return @db if @db
    @db = SQLite3::Database.open get_ps_db_file
  end

  # Returns an array of Strings of the shared photo stream names synced to this computer
  def get_all_ps_names
    sql = "SELECT name FROM Albums;"

    get_db_conn.execute(sql).flatten
  end

  # Returns a hash of Photo Stream names to arrays of image UUIDs 
  def get_all_ps_img_uuids
    # Returns a hash of arrays, keys being the names of the shared photostreams
    # and the keys being an array of the UUIDs for each photo
    @streams.reduce( Hash.new { |h,k| h[k] = [] } ) do |acc, stream|
      acc[stream] = get_ps_img_uuids(stream)
    end
  end

  def get_ps_img_uuids(stream_name)
    sql ="SELECT ac.GUID AS 'uuid', ac.photoDate AS 'date'
              FROM AssetCollections AS ac
                JOIN Albums AS a ON a.GUID = ac.albumGUID
              WHERE a.name = \"#{stream_name}\";"

    get_db_conn
    results = @db.execute(sql)
  end

  def get_ps_album_uuid(stream_name)
    sql ="SELECT a.GUID AS 'uuid'
              FROM Albums AS a
              WHERE a.name = \"#{stream_name}\";"

    get_db_conn
    results = @db.execute(sql).flatten.at(0)
  end

  def backup_image(source, dest)
    # Pretty vanilla rsync here, additional --update option added to only copy
    # over files that have changes/are new
    Rsync.run(source, dest, ['--update']) do |result|
      if result.success?
        result.changes.each do |change|
          puts "#{change.filename} (#{change.summary})"
        end
      else
        puts result.error
        puts result.inspect
      end
    end
  end

  # All together now... Main execution for the script that takes in the list
  # of photo streams and copies the images within them to the specified directory
  def run
    @streams.each do |stream|
      puts "Backing up stream '#{stream}'"

      FileUtils::mkdir_p "#{@destination}/#{stream}"

      stream_id = get_ps_album_uuid(stream)

      ids = get_ps_img_uuids(stream)

      puts "Backing up #{ids.size} images..."
      # here we go!  each folder contains 1 or 2 files, either a image, and movie, or both
      # in the case of the live images (which are actually just a two second movie and a picture)
      ids.each do |id|
        # Going to start with looking for jpg images.  If there is a jpg in there, then it will be moved as a jpg
        source_file_jpg = Shellwords.escape("#{PHOTO_STREAM_DIR}/assets/#{stream_id}/#{id[0]}/IMG_") + '*.JPG'
        dest_file_jpg = Shellwords.escape("#{@destination}/#{stream}/#{id[1]}.jpg")
        # look for a jpg, back it up if need be
        if !Dir.glob(source_file_jpg).empty?
          puts "Backing up source file #{source_file_jpg} to #{dest_file_jpg}" if @verbose
          backup_image(source_file_jpg, dest_file_jpg)
        end
        # now we look for movies in the same folder. 
        source_file_mov = Shellwords.escape("#{PHOTO_STREAM_DIR}/assets/#{stream_id}/#{id[0]}/IMG_") + '*.mov'
        dest_file_mov = Shellwords.escape("#{@destination}/#{stream}/#{id[1]}.mov")   
        # look for a .mov, and sync if it exists
        if !Dir.glob(source_file_mov).empty?	
          puts "Backing up source file #{source_file_mov} to #{dest_file_mov}" if @verbose
          backup_image(source_file_mov, dest_file_mov)
        end
        # look for an mp4 and sync if it exists
        source_file_mp4 = Shellwords.escape("#{PHOTO_STREAM_DIR}/assets/#{stream_id}/#{id[0]}/IMG_") + '*.mp4'
        dest_file_mp4 = Shellwords.escape("#{@destination}/#{stream}/#{id[1]}.mp4")
        if !Dir.glob(source_file_mp4).empty?	
          puts "Backing up source file #{source_file_mp4} to #{dest_file_mp4}" if @verbose
          backup_image(source_file_mp4, dest_file_mp4)
        end
      end
    end
  end
end

if __FILE__ == $0
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options]"

    opts.on('-s', '--streams X,Y,Z', Array, 'The name of one or more streams that will be backed up, use "all" to back all of them up') do |streams|
      options[:streams] = streams.map(&:strip)
    end

    opts.on('-d', '--destination DEST', 'The destination folder for the images found, ie ~/Dropbox, etc') do |destination|
      options[:destination] = destination
    end

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:verbose] = v
    end

    opts.on( '-h', '--help', 'Display this screen' ) do
      puts opts
      exit
    end
  end.parse!

   # Validate the options
   required_opts = [:destination]
   missing_opts = required_opts.select { |opt| options[opt].nil? }

   unless missing_opts.empty?
     raise ArgumentError, "Missing required options, please specify the following required options: #{missing_opts.join(',')}"
     puts opts
     exit 1
   end

  # Run all the things!!
  psb = PhotoStreamBackUpper.new(
          options[:streams], 
          options[:destination], 
          options[:verbose]
       )
  psb.run
end
