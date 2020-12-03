# Was used to rename Alolan Battler Graphics

=begin

ALOLAMAP = [19, 20, 26, 27, 28, 37, 38, 50, 51, 52, 53, 74, 75, 76, 88, 89, 105, 103]

DIR_NAME = "Alolan Graphics"

Dir.foreach(DIR_NAME) do |filename|
  next if filename == '.' or filename == '..'
  newfilename = sprintf("%03d", ALOLAMAP[filename[0..2].to_i - 804])
  newfilename += filename[3...(filename.length-4)]
  newfilename += "_1.png"
  File.rename(DIR_NAME + "/" +filename, DIR_NAME + "/" + newfilename)
end

=end