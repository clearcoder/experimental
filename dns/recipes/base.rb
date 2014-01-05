#!/usr/local/bin/ruby

require 'cgi'
require 'logger'
require '../libraries/utils'

AWS_CREDENTIALS_FILE = "/opt/.creds"

AWS.config(YAML.load(File.read(AWS_CREDENTIALS_FILE)))
AWS.config(:logger => Logger.new($stdout))
AWS.config(:log_level => :debug)
AWS.config(:log_formatter => AWS::Core::LogFormatter.colored)
