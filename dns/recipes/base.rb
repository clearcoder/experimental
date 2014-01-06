#!/usr/local/bin/ruby

require 'cgi'
require 'logger'
require '../libraries/utils'

AWS_CREDENTIALS_FILE = "/opt/.creds"

#AWS.config(YAML.load(File.read(AWS_CREDENTIALS_FILE)))
AWS.config(:access_key_id => node[:dns][:access_key_id], :secret_access_key => node[:dns][:secret_access_key])
AWS.config(:logger => Logger.new($stdout))
AWS.config(:log_level => :debug)
AWS.config(:log_formatter => AWS::Core::LogFormatter.colored)
