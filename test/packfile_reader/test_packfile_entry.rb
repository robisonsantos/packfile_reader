require 'minitest/autorun'
require 'packfile_reader/packfile_entry'
require 'packfile_reader/packfile_header'

describe PackfileReader::PackfileEntry do
  before do
    # There are 3 objects embedded in the pack.sampe file
    @packfile = File.open("#{__dir__}/../resources/pack.sample", 'rb')
    PackfileReader::PackfileHeader.new @packfile # skip the header
  end

  after do
    @packfile.close
  end

  describe 'can get any object' do
    it 'returns objects in order' do
      entry1 = PackfileReader::PackfileEntry.next_entry(@packfile)
      assert_equal :OBJ_COMMIT, entry1.type
      assert_equal '96438dd1e26e6963fa65be0012e8f6e84209bc5d', entry1.id
      assert_equal 653, entry1.size

      entry2 = PackfileReader::PackfileEntry.next_entry(@packfile)
      assert_equal :OBJ_BLOB, entry2.type
      assert_equal '5297f8f21ad868d9eb6a9c01ad09a9d186177047', entry2.id
      assert_equal 10, entry2.size

      entry3 = PackfileReader::PackfileEntry.next_entry(@packfile)
      assert_equal :OBJ_TREE, entry3.type
      assert_equal 'bf195faf9d23ce0615cdefd2b746a077ef82f03f', entry3.id
      assert_equal 37, entry3.size
    end
  end

  it 'can get specific object' do
    entry = PackfileReader::PackfileEntry.next_entry(@packfile, ['bf195faf9d23ce0615cdefd2b746a077ef82f03f'])
    assert_equal :OBJ_TREE, entry.type
    assert_equal 'bf195faf9d23ce0615cdefd2b746a077ef82f03f', entry.id
    assert_equal 37, entry.size
  end

  it 'passes data to block' do
    PackfileReader::PackfileEntry.next_entry(@packfile, 
                                            ['5297f8f21ad868d9eb6a9c01ad09a9d186177047']) do |compressed, uncompressed, id|
      assert_equal '5297f8f21ad868d9eb6a9c01ad09a9d186177047', id
      assert_equal '# test-git', uncompressed
      assert_equal [120, 156, 83, 86, 40, 73, 45, 46, 209, 77, 207, 44, 1, 0, 17, 16, 3, 117], compressed.bytes
    end
  end
end