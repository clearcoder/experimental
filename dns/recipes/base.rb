#!/usr/local/bin/ruby

require 'cgi'
require 'logger'

#TODO: Fix for ruby > 1.9.1
#http://stackoverflow.com/questions/4333286/ruby-require-vs-require-relative-best-practice-to-workaround-running-in-both
require File.join(File.dirname(__FILE__), '../libraries/dns_actions')

dns = {}
if defined?(node) #is defined by chef and we need these lines below for debugging outside chef
    dns = node[:dns]
else
    AWS_CREDENTIALS_FILE = "/opt/.creds"
    tmp_creds = YAML.load(File.read(AWS_CREDENTIALS_FILE))
    dns[:access_key_id] = tmp_creds["access_key_id"]
    dns[:secret_access_key] = tmp_creds["secret_access_key"]
end

AWS.config(:access_key_id => dns[:access_key_id], :secret_access_key => dns[:secret_access_key])

AWS.config(:logger => Logger.new($stdout))
AWS.config(:log_level => :debug)
AWS.config(:log_formatter => AWS::Core::LogFormatter.colored)

