require 'aws-sdk'
require File.join(File.dirname(__FILE__), 'utils')

class DnsActions
    include Utils
    def initialize()

        dns = {}
        if defined? (node) #is defined by chef and we need these lines below for debugging outside chef
            dns = node[:dns]
        else
            dns[:balancer_hostname] = 'balancer1'
            dns[:balancer_ttl] = 60 
            dns[:node_ttl] = 300 
            dns[:zone_id] = '/hostedzone/Z98DD1X7I9M6Z'
        end

        @zone_id = dns[:zone_id]
        @balancer_hostname = dns[:balancer_hostname]
        @balancer_ttl = dns[:balancer_ttl] 
        @node_ttl = dns[:node_ttl]

        @dnsClient = AWS::Route53.new()
        @rrsets = AWS::Route53::HostedZone.new(@zone_id).resource_record_sets
    end 

    def add_hostname()
        begin
            fqdn = get_fqdn
            if(fqdn.nil?)
                raise "No valid FQDN found."	
            end

            balancer_fqdn = @balancer_hostname + '.' + get_zonename
            ip_address = get_public_ip
            puts "Adding " + fqdn + " to DNS." 	
            add_or_update( fqdn, @node_ttl, ip_address )
            puts "Adding " + balancer_fqdn + " to DNS." 	
            add_or_update( balancer_fqdn, @balancer_ttl, ip_address )
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
            remove_or_update( fqdn, nil ) 

            balancer_fqdn = @balancer_hostname + '.' + get_zonename
            puts "Removing " + balancer_fqdn + " from DNS."
            remove_or_update( balancer_fqdn, get_public_ip ) 
        rescue => err
            puts "Exception: #{err}"
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
                    puts record 
                    if(ip_address.eql? record[:value])
                        found_record_value = true 
                    end
                end 
            end

            if found_record && found_record_value
                puts "Found record for "+ hostname + ":" + ip_address
                puts "Do nothing."
                return
            end

            puts "Adding " + hostname + ":" + ip_address + " to DNS." 	

            if found_record
                rrset.resource_records.push({:value => ip_address})
                rrset.update
                return
            else
                rrset = @rrsets.create(hostname, 'A', :ttl => ttl, :resource_records => [{:value => ip_address}])
            end

        rescue => err
            print "Exception: #{err}"
            err
        end 
    end

    def remove_or_update(hostname, ip_address)
        begin

            rrset = @rrsets[hostname, 'A']
            if(ip_address.nil?)
                #delete entire record for hostname
                if(rrset.exists?)
                    rrset.delete
                end
            else
                #update record removing IP address
                found_record = false
                found_record_value = false
                if(rrset.exists?)
                    found_record = true
                    if(rrset.resource_records.length > 1)
                        #check to see if the target IP address exists in record.
                        rrset.resource_records.each do |record| 
                            if(ip_address.eql? record[:value])
                                found_record_value = true 
                            end
                        end 
                    end
                end

                if found_record && found_record_value
                    puts "Found record for "+ hostname + ":" + ip_address
                    # remove IP and update
                    resource_records = []
                    rrset.resource_records.each do |record| 
                        if(ip_address != record[:value])
                            resource_records.add(record)
                        end
                    end
                    rrset.resource_records = resource_records 
                    rrset.update
                    return
                elsif found_record
                    # record contains one value
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
            resp = @dnsClient.client.list_hosted_zones
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
