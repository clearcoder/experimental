require 'aws-sdk'
require "net/http"
require "uri"


module Utils
    @@AWS_IPV4_URL = 'http://169.254.169.254/latest/meta-data/public-ipv4'
    @@ZONE_ID = '/hostedzone/Z98DD1X7I9M6Z'
    @@TTL_DEFAULT = 300

    def get_public_ip()
        ip = nil ;
        begin
            ip = eat(@@AWS_IPV4_URL)
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
    module_function :get_public_ip
    module_function :get_hostname

end

class DnsActions
    include Utils
    def initialize()
        @dnsClient = AWS::Route53.new()
        @rrsets = AWS::Route53::HostedZone.new(@@ZONE_ID).resource_record_sets
    end 

    def add_hostname()
        begin
            fqdn = get_fqdn
            if(fqdn.nil?)
                raise "No valid FQDN found."	
            end
            puts "Adding " + fqdn + " to DNS." 	
            rrset = @rrsets.create(fqdn, 'A', :ttl => @@TTL_DEFAULT, :resource_records => [{:value => get_public_ip}])
        rescue => err
            puts "Exception: #{err}"
            err
        end
    end

    def remove_hostname()
        begin
            fqdn = get_fqdn
            if(fqdn.nil?)
                raise "No valid FQDN found."	
            end
            puts "Removing " + fqdn + " from DNS."
            rrset = @rrsets[fqdn, 'A']
            if(rrset.exists?)
                rrset.delete
            end
        rescue => err
            puts "Exception: #{err}"
            err
        end
    end 

    private

    def get_zonename()
        begin
            zone_name = nil
            resp = @dnsClient.client.list_hosted_zones
            resp[:hosted_zones].each do |zone|
                print "Zone: " + zone.inspect + "\n"
                if( zone[:id] == @@ZONE_ID )
                    zone_name = zone[:name]
                end
            end
            return zone_name
        rescue => err
            print "Exception: #{err}"
            err
        end 
    end

    def get_fqdn()
        begin
            fqdn = nil
            return get_hostname + "." + get_zonename
        rescue => err
            print "Exception: #{err}"
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
end 
