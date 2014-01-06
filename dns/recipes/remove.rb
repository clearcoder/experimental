#!/usr/local/bin/ruby

require File.join(File.dirname(__FILE__), 'base')

DnsActions.new().remove_hostname()
