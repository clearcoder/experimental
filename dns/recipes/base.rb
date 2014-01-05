#!/usr/local/bin/ruby

require 'cgi'
require 'logger'
require '../libraries/utils'

AWS.config(YAML.load(File.read("/opt/.mycreds")))
AWS.config(:logger => Logger.new($stdout))
AWS.config(:log_level => :debug)
AWS.config(:log_formatter => AWS::Core::LogFormatter.colored)
