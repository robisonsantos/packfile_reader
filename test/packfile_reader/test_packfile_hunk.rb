require 'minitest/autorun'
require 'packfile_reader/packfile_hunk'

# A hunk is a byte that encodes some data
# it can encode a continuation flag, type and size
# or a continuation flag and size
# http://shafiul.github.io/gitbook/7_the_packfile.html
#
# If the byte starts with '1' then it is a continuation - meaning, 
# is more data to be processed about that hunk
# If it starts with '0' then that is the last hunk about that data
# The first byte about the data contains the type <1|0><type(3)><size(4)>
# The subsequent bytes do not contain type <1|0><size(7)>

describe PackfileReader::Hunk do
  describe "hunk starting with '1' and has type" do
    it 'is a continuation' do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b10010100].pack('C')))
      assert hunk.continuation?
    end

    it 'has a size' do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b10010100].pack('C')))
      assert_equal 4, hunk.size
    end

    it 'has a offset size equals 4 bits' do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b10010100].pack('C')))
      assert_equal 4, hunk.offset_size
    end

    it "is a commit if type portion is '001'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b10010100].pack('C')))
      assert_equal :OBJ_COMMIT, hunk.type
    end

    it "is a tree if type portion is '010'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b10100100].pack('C')))
      assert_equal :OBJ_TREE, hunk.type
    end

    it "is a blob if type portion is '011'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b10110100].pack('C')))
      assert_equal :OBJ_BLOB, hunk.type
    end

    it "is a tag if type portion is '100'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b11000100].pack('C')))
      assert_equal :OBJ_TAG, hunk.type
    end

    it "is an offset delta if type portion is '110'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b11100100].pack('C')))
      assert_equal :OBJ_OFS_DELTA, hunk.type
    end

    it "is a reference delta is type portion is '111'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b11110100].pack('C')))
      assert_equal :OBJ_REF_DELTA, hunk.type
    end
  end

  describe "hunk starting with '0' and has type" do
    it 'is not a continuation' do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b00010100].pack('C')))
      assert !hunk.continuation?
    end

    it 'has a size' do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b00010100].pack('C')))
      assert_equal 4, hunk.size
    end

    it 'has a offset size equals 4 bits' do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b00010100].pack('C')))
      assert_equal 4, hunk.offset_size
    end

    it "is a commit if type portion is '001'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b00010100].pack('C')))
      assert_equal :OBJ_COMMIT, hunk.type
    end

    it "is a tree if type portion is '010'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b00100100].pack('C')))
      assert_equal :OBJ_TREE, hunk.type
    end

    it "is a blob if type portion is '011'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b00110100].pack('C')))
      assert_equal :OBJ_BLOB, hunk.type
    end

    it "is a tag if type portion is '100'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b01000100].pack('C')))
      assert_equal :OBJ_TAG, hunk.type
    end

    it "is an offset delta if type portion is '110'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b01100100].pack('C')))
      assert_equal :OBJ_OFS_DELTA, hunk.type
    end

    it "is a reference delta is type portion is '111'" do
      hunk = PackfileReader::Hunk.new_with_type(StringIO.new([0b01110100].pack('C')))
      assert_equal :OBJ_REF_DELTA, hunk.type
    end
  end 

  describe "hunk starting with '1' and does not have type" do
    it 'is a continuation' do
      hunk = PackfileReader::Hunk.new_without_type(StringIO.new([0b10010100].pack('C')))
      assert hunk.continuation?
    end

    it 'has a size' do
      hunk = PackfileReader::Hunk.new_without_type(StringIO.new([0b10010100].pack('C')))
      assert_equal 20, hunk.size
    end

    it 'has a offset size equals 7 bits' do
      hunk = PackfileReader::Hunk.new_without_type(StringIO.new([0b10010100].pack('C')))
      assert_equal 7, hunk.offset_size
    end

    it 'is does not have a type' do
      hunk = PackfileReader::Hunk.new_without_type(StringIO.new([0b10010100].pack('C')))
      assert_nil hunk.type
    end
  end
  
  describe "hunk starting with '0' and does not have type" do
    it 'is not a continuation' do
      hunk = PackfileReader::Hunk.new_without_type(StringIO.new([0b00010100].pack('C')))
      assert !hunk.continuation?
    end

    it 'has a size' do
      hunk = PackfileReader::Hunk.new_without_type(StringIO.new([0b00010100].pack('C')))
      assert_equal 20, hunk.size
    end

    it 'has a offset size equals 7 bits' do
      hunk = PackfileReader::Hunk.new_without_type(StringIO.new([0b00010100].pack('C')))
      assert_equal 7, hunk.offset_size
    end

    it 'is does not have a type' do
      hunk = PackfileReader::Hunk.new_without_type(StringIO.new([0b00010100].pack('C')))
      assert_nil hunk.type
    end
  end
end
