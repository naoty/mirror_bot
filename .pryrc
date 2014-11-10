lib_path = File.expand_path("./lib")
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

require "dotenv"
Dotenv.load

require "sequel"
Sequel.connect(ENV["DATABASE_URL"])

require "mirror_bot"
