require 'digest'
require 'zlib'
require 'packfile_reader/packfile_hunk'

module PackfileReader
  class PackfileEntry
    attr_reader :type
    attr_reader :size
    attr_reader :id

    # ZLIB RFC: https://tools.ietf.org/html/rfc1950
    ZLIB_HEADERS = [
      0b0111100000000001, #0x78 0x01
      0b0111100010011100, #0x78 0x9c
      0b0111100011011010, #0x78 0xda
    ]

    # Accepts a block that will receive the compressed data, uncompressed data and
    # the computed object id. Window size is the amount of bytes to read at once
    # while searching for the compressed data
    def self.next_entry(packfile_io, objects_to_find=:any, log_verbose=false, window_size=10_000)
      raise 'Object id must be a valid sha1' unless objects_to_find == :any || objects_to_find.all? {|id| /^[0-9a-f]{40}$/.match? id }

      loop do
        return nil if packfile_io.eof?

        hunk = PackfileReader::Hunk.new_with_type(packfile_io)

        type = hunk.type
        size = hunk.size
        offset = hunk.offset_size

        # Clean the current line before printing the message
        $stderr.puts "\u001b[0K>>>> Processing new entry [#{type}]" if log_verbose
        while hunk.continuation?
          hunk = PackfileReader::Hunk.new_without_type(packfile_io)
          size = (hunk.size << offset) | size # Data size is a combination of all hunk sizes
          offset += hunk.offset_size
        end

        compressed_data, uncompressed_data = find_data(packfile_io, log_verbose, window_size)
        object_id = compute_id(type, size, uncompressed_data)

        type = "#{type} [CORRUPTED] " if uncompressed_data.nil?

        if objects_to_find == :any || objects_to_find.member?(object_id)
          yield compressed_data, uncompressed_data, object_id if block_given?
          return PackfileEntry.new(type, size, object_id)
        end
      end
    end

    private
    def self.find_data(packfile_io, log_verbose, window_size)
      data_header = find_zlib_data_header(packfile_io)

      # since we don't have the index file that accompanies pack files
      # we need to use brute force to find where the compressed data ends
      # to do that, we go <window_size> bytes by <window_size> bytes and try to deflate the data, when
      # that succeedes, we know we go it all
      compressed_data = data_header
      compressed_data += packfile_io.read(window_size)

      bytes_read = compressed_data.size
      begin
        uncompressed_data = Zlib.inflate(compressed_data)
      rescue Zlib::BufError
        compressed_data += packfile_io.read(window_size)
        bytes_read = compressed_data.size
        $stderr.print " .... retrying on data gathering [#{bytes_read}] bytes read\r" if log_verbose
        retry
      rescue Zlib::DataError
        uncompressed_data = nil
      end

      $stderr.puts " .... data read [#{bytes_read}] bytes" if log_verbose
      $stderr.print " .... repositioning file pointer to the end of current compressed data\r" if log_verbose
      compressed_data = Zlib.deflate(uncompressed_data) if uncompressed_data

      # reposition the file pointer to end of compressed data
      packfile_io.seek(packfile_io.pos - (bytes_read - compressed_data.size))

      [compressed_data, uncompressed_data]
    end

    def self.find_zlib_data_header(packfile_io)
      # If type is OBJ, TREE or COMMIT, data is a zlib stream data
      # ref-delta uses a 20 byte hash of the base object at the beginning of data
      # ofs-delta stores an offset within the same packfile to identify the base object
      #
      # Need to skip until we find a compressed data
      # We really don't care about the delta objects

      data_header = packfile_io.read(2) # 2 bytes to find the zlib header

      while (not ZLIB_HEADERS.member?(data_header.unpack('n')[0]))
        packfile_io.seek(packfile_io.pos - 1) # need to walk 2 by 2 bytes
        data_header = packfile_io.read(2)
      end

      data_header
    end

    def self.compute_id(type, size, uncompressed_data)
      header_type = case type
                    when :OBJ_COMMIT then 'commit'
                    when :OBJ_TREE then 'tree'
                    when :OBJ_BLOB then 'blob'
                    when :OBJ_TAG then 'tag'
                    else ''
      end

      return '000' if header_type.empty?

      header = "#{header_type} #{size}\0"
      store = "#{header}#{uncompressed_data}"
      Digest::SHA1.hexdigest(store)
    end

    def initialize(type, size, id)
      @type = type
      @size = size
      @id = id
    end
  end
end
