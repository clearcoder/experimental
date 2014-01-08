require "net/http"
require "uri"

module Utils
    @@AWS_IPV4_URL = 'http://169.254.169.254/latest/meta-data/public-ipv4'

    def get_public_ip()
        ip = nil ;
        begin
            if defined?(OpsWorks) 
                ip = eat(@@AWS_IPV4_URL)
            else # a bogus IP for debugging
                ip = "10.60.2.33"
            end
            return ip
        rescue => err
            puts "Exception: #{err}"
            err
        end
    end
    def get_hostname()
        ip = nil ;
        begin
            hostname = File.read('/etc/hostname').delete("\n") 
            return hostname
        rescue => err
            puts "Exception: #{err}"
            err
        end
    end

    def eat(url)
        begin
            uri = URI.parse(url)
            http = Net::HTTP.new(uri.host, uri.port)
            request = Net::HTTP::Get.new(uri.request_uri)
            response = http.request(request)
            return response.body
        rescue => err
            print "Exception: #{err}"
            err
        end 
    end

    module_function :get_public_ip
    module_function :get_hostname
end
 
