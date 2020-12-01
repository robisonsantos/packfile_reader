Gem::Specification.new do |s|
  s.name = 'packfile_reader'
  s.version = '0.0.1'
  s.executables << 'packfile_reader'
  s.date = '2020-11-30'
  s.summary = 'Parses git packfiles without the help of idx companion'
  s.description = 'A tool to parse git packfile when idx files are not present'
  s.authors = ['Robison WR Santos']
  s.email = ''
  s.files = Dir['README*.md', 'lib/**/*']
  s.test_files = s.files.select { |p| p =~ /^test\/test_*.rb/ }
  s.homepage = 'https://github.com/robisonsantos/packfile_reader'
  s.license = 'MIT'
  s.add_dependency 'optimist', '~> 3.0.1'
end
