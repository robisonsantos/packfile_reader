module PackfileReader

  # Defines a class for the HEADER portion of a git packfile
  # From: https://git-scm.com/docs/pack-format
  #
  # A header appears at the beginning and consists of the following:
  #
  # 4-byte signature:
  #     The signature is: {'P', 'A', 'C', 'K'}
  #
  # 4-byte version number (network byte order):
  #   Git currently accepts version number 2 or 3 but generates version 2 only.
  #
  # 4-byte number of objects contained in the pack (network byte order)
  #
  # Observation: we cannot have more than 4G versions ;-) and more than 4G objects in a pack.
  class PackfileHeader
    attr_reader :version   # version of the packfile
    attr_reader :sign      # signature (must be PACK)
    attr_reader :n_entries # how many objects in the packfile

    # Creates a new PackfileHeader instance reading data from the beginning
    # of a packfile. It fails if it cannot parse the data or if the signature
    # does not match the expected 'PACK' string
    #
    # Params:
    # +packfile_io+:: the opened packfile handler in binary format (usually the output of File.open('path', 'rb'))
    def initialize(packfile_io)
      begin
        go_to_start(packfile_io)
        @sign = parse_sign(packfile_io)
        @version = parse_version(packfile_io)
        @n_entries = parse_n_entries(packfile_io)
      rescue
        raise 'Invalid packfile. Cannot parse header'
      end
      raise "Invalid signature. Got '#{@sign}' expected 'PACK'" unless @sign == 'PACK'
    end

    def to_s
      <<~EOS.strip
      Packfile Headers
      - Signature: #{@sign}
      - Version: #{@version}
      - Entries: #{@n_entries}
      EOS
    end

    private
    def go_to_start(packfile_io)
      packfile_io.seek(0)
    end

    def parse_sign(packfile_io)
      packfile_io.read(4)
    end

    def parse_version(packfile_io)
      packfile_io.read(4).unpack("N")[0]
    end

    def parse_n_entries(packfile_io)
      packfile_io.read(4).unpack("N")[0]
    end
  end
end
