require_relative '../../spec/helpers/sensitive_data_scrubber'

namespace :vcr do
  desc "scrub a file"
  task :scrub, [:file_path] => [:environment] do |t, args|
    text = File.read(args.file_path)
    scrubber = SensitiveDataScrubber.new
    scrubber.setup(text, text)
    puts scrubber.scrub!(text)
  end
end
