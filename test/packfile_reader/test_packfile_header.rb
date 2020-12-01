require 'minitest/autorun'
require 'packfile_reader/packfile_header'

class PackfileHeaderTest < Minitest::Test
  def setup
    packfile = File.open("#{__dir__}/../resources/pack.sample", 'rb')
    @packfile_header = PackfileReader::PackfileHeader.new packfile
    packfile.close
  end

  def test_signature
    assert_equal 'PACK', @packfile_header.sign
  end

  def test_version
    assert_equal 2, @packfile_header.version
  end

  def test_n_entries
    assert_equal 3, @packfile_header.n_entries
  end

  def test_to_string_representation
    assert_equal "Packfile Headers\n- Signature: PACK\n- Version: 2\n- Entries: 3",
                  @packfile_header.to_s
  end

  def test_validates_signature
    err = assert_raises RuntimeError do
      File.open("#{__dir__}/../resources/pack.invalid_sign", 'rb') do |f|
        PackfileReader::PackfileHeader.new f
      end
    end
    assert_match "Invalid signature. Got 'SACK' expected 'PACK'", err.message
  end

  def test_invalid_file
    err = assert_raises RuntimeError do
      File.open("#{__dir__}/../resources/pack.invalid_file", 'rb') do |f|
        PackfileReader::PackfileHeader.new f
      end
    end
    assert_match 'Invalid packfile. Cannot parse header', err.message
  end
end