def compress(path)
  gem 'rubyzip'
  require 'zip/zip'
  require 'zip/zipfilesystem'

  path.sub!(%r[/$],'')
  archive = path+'.zip'
  FileUtils.rm archive, :force=>true

  Zip::ZipFile.open(archive, 'w') do |zipfile|
    Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
      zipfile.add(file.sub(path+'/',''),file)
    end
  end
end
