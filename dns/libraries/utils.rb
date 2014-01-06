
OpsWorks::InternalGems.internal_gem_package('eat', '0.1.8')
#if defined?(OpsWorks) && defined?(OpsWorks::InternalGems)
#    OpsWorks::InternalGems.internal_gem_package('eat', '0.1.8')
#else
#    chef_gem 'eat' do
#        action :install
#        version '>= 0.1.8'
#    end
#end

require 'eat'

#if defined?(OpsWorks) && defined?(OpsWorks::InternalGems)
#    OpsWorks::InternalGems.internal_gem_package('aws-sdk', '1.31.3')
#else
#    chef_gem 'aws-sdk' do
#        action :install
#        version '>= 1.31.3'
#    end
#end

require 'aws-sdk'

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
end 
