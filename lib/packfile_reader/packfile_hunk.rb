module PackfileReader
  class Hunk
    attr_reader :size
    attr_reader :type
    attr_reader :offset_size

    TYPE_MAP = {
      1 => :OBJ_COMMIT,
      2 => :OBJ_TREE,
      3 => :OBJ_BLOB,
      4 => :OBJ_TAG,
      6 => :OBJ_OFS_DELTA,
      7 => :OBJ_REF_DELTA,
    }

    HUNK_TYPE_MASK = 0b01110000
    HUNK_SIZE_4_MASK = 0b00001111
    HUNK_SIZE_7_MASK = 0b01111111
  
    def self.new_with_type(packfile_io)
      hunk_bytes = packfile_io.read(1).unpack('C')[0]
      continuation = hunk_bytes[7] # First representative bit of the byte
      type = (hunk_bytes & HUNK_TYPE_MASK) >> 4 # Adjust type position (remove the extra 4 bits at the end)
      size = (hunk_bytes & HUNK_SIZE_4_MASK) # We only have 4 bits in a hunk with type for size

      Hunk.new(continuation == 1, size, 4, TYPE_MAP[type])
    end

    def self.new_without_type(packfile_io)
      hunk_bytes = packfile_io.read(1).unpack('C')[0]
      continuation = hunk_bytes[7] # First representative bit of the byte
      size = (hunk_bytes & HUNK_SIZE_7_MASK) # We only have 7 bits in a hunk with type for size

      Hunk.new(continuation == 1, size, 7)
    end

    def continuation?
      @continuation
    end

    private
    def initialize(continuation, size, offset_size, type=nil)
      @continuation = continuation
      @size = size
      @offset_size = offset_size
      @type = type
    end

  end
end