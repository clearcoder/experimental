#!/usr/local/bin/ruby

require 'cgi'
require 'logger'

#TODO: Fix for ruby > 1.9.1
#http://stackoverflow.com/questions/4333286/ruby-require-vs-require-relative-best-practice-to-workaround-running-in-both
require File.join(File.dirname(__FILE__), '../libraries/utils')

AWS.config(:access_key_id => node[:dns][:access_key_id], :secret_access_key => node[:dns][:secret_access_key])
AWS.config(:logger => Logger.new($stdout))
AWS.config(:log_level => :debug)
AWS.config(:log_formatter => AWS::Core::LogFormatter.colored)

