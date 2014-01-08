require 'aws-sdk'
require 'logger'
require File.join(File.dirname(__FILE__), 'utils')

class DnsActions
    include Utils
    def initialize()

        dns = {}
        if defined?(node) #is defined by chef and we need these lines below for debugging outside chef
            dns = node[:dns]
        else
            dns[:balancer_hostname] = 'balancer1'
            dns[:balancer_ttl] = 300
            dns[:node_ttl] = 60 
            dns[:zone_id] = '/hostedzone/Z98DD1X7I9M6Z'
        end

        @zone_id = dns[:zone_id]
        @balancer_hostname = dns[:balancer_hostname]
        @balancer_ttl = dns[:balancer_ttl] 
        @node_ttl = dns[:node_ttl]

        @r53 = AWS::Route53.new()
        @rrsets = AWS::Route53::HostedZone.new(@zone_id).resource_record_sets
        
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        #@logger.formatter = AWS::Core::LogFormatter.colored
    end 

    def add_hostname()
        begin
            fqdn = get_fqdn
            if(fqdn.nil?)
                raise "No valid FQDN found."	
            end

            balancer_fqdn = @balancer_hostname + '.' + get_zonename
            ip_address = get_public_ip
            @logger.debug("Adding " + fqdn + " to DNS.")
            add_or_update( fqdn, @node_ttl, ip_address )
            @logger.debug("Adding " + balancer_fqdn + " to DNS.")
            add_or_update( balancer_fqdn, @balancer_ttl, ip_address )
        rescue => err
            @logger.error("Exception: #{err}")
            err
        end
    end

    def remove_hostname()
        begin
            fqdn = get_fqdn
            if(fqdn.nil?)
                raise "No valid FQDN found."
            end
            @logger.debug("Removing " + fqdn + " from DNS.")
            remove_or_update( fqdn, nil ) 

            balancer_fqdn = @balancer_hostname + '.' + get_zonename
            @logger.debug("Removing " + balancer_fqdn + " from DNS.")
            remove_or_update( balancer_fqdn, get_public_ip ) 
        rescue => err
            @logger.error("Exception: #{err}")
            err
        end
    end 

    private

    def add_or_update(hostname, ttl, ip_address)
        begin

            rrset = @rrsets[hostname, 'A']
            found_record = false
            found_record_value = false
            if(rrset.exists?)
                found_record = true
                #check to see if the target IP address exists in record.
                rrset.resource_records.each do |record| 
                    @logger.debug("Found record value: " + record.inspect)
                    if(ip_address.eql? record[:value])
                        found_record_value = true 
                    end
                end 
            end

            if found_record && found_record_value
                @logger.debug("Found record for "+ hostname + ":" + ip_address)
                @logger.debug("Do nothing.")
                return
            end

            @logger.debug("Adding " + hostname + ":" + ip_address + " to DNS.")

            if found_record
                @logger.debug("Adding value: "+ip_address)

                values = []
                rrset.resource_records.each do |record| 
                    values << {:value => record[:value]}
                end
                values << {:value => ip_address}
                deleteRequest = AWS::Route53::DeleteRequest.new(hostname,'A', :ttl => ttl, :resource_records => rrset.resource_records )
                createRequest = AWS::Route53::CreateRequest.new(hostname,'A', :ttl => ttl, :resource_records => values)

                @r53.client.change_resource_record_sets(:hosted_zone_id => @zone_id, :change_batch => {
                    :comment => "Replacing old dns record",
                    :changes => [deleteRequest, createRequest] })
                return
            else
                @rrsets.create(hostname, 'A', :ttl => ttl, :resource_records => [{:value => ip_address}])
            end

        rescue => err
            @logger.debug("Exception: #{err}")
            err
        end 
    end

    def remove_or_update(hostname, ip_address)
        begin

            rrset = @rrsets[hostname, 'A']
            if(ip_address.nil?)
                #delete entire record for hostname
                @logger.debug("No IP address was supplied. Deleting entire record.")
                if(rrset.exists?)
                    rrset.delete
                end
            else
                #Check first what do we have to to do
                found_record = false
                found_record_value = false
                if(rrset.exists?)
                    found_record = true
                    #check to see if the target IP address exists in record.
                    rrset.resource_records.each do |record| 
                        if(ip_address.eql? record[:value])
                            found_record_value = true 
                        end
                    end
                end

                # .. then do it
                if found_record && found_record_value && rrset.resource_records.length > 1  
                    puts "Found record for "+ hostname + ":" + ip_address
                    # remove IP and update
                    resource_records = []
                    rrset.resource_records.each do |record| 
                        if(ip_address != record[:value])
                            resource_records << record
                        end
                    end

                    @logger.debug("Selectively deleting record value for: " + ip_address)
                    deleteRequest = AWS::Route53::DeleteRequest.new(hostname,'A', :ttl => rrset.ttl, :resource_records => rrset.resource_records )
                    createRequest = AWS::Route53::CreateRequest.new(hostname,'A', :ttl => rrset.ttl, :resource_records => resource_records)

                    @r53.client.change_resource_record_sets(:hosted_zone_id => @zone_id, :change_batch => {
                        :comment => "Removing ip from dns record",
                        :changes => [deleteRequest, createRequest] })    
                        return
                elsif found_record && found_record_value
                    # record contains one value
                    @logger.debug("Deleting entire record since it only contains a single value: " + ip_address)
                    rrset.delete
                else
                    puts "Did not find record for "+ hostname + ":" + ip_address
                    puts "Do nothing."
                    return
                end

            end
        rescue => err
            print "Exception: #{err}"
            err
        end 

    end

    def get_zonename()
        begin
            zone_name = nil
            resp = @r53.client.list_hosted_zones
            resp[:hosted_zones].each do |zone|
                print "Zone: " + zone.inspect + "\n"
                if( zone[:id] == @zone_id )
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
            return get_hostname + "." + get_zonename
        rescue => err
            print "Exception: #{err}"
            err
        end 
    end
end
