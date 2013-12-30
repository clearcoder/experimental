require 'time'
require 'base64'
require 'net/http'
require 'net/https'
require 'openssl'
require 'uri'
 
module Route53
  
  class Client
  
    def initialize(aws_access_key_id, aws_secret_access_key)
      @endpoint = "https://route53.amazonaws.com/"
      @aws_access_key_id      = aws_access_key_id
      @aws_secret_access_key  = aws_secret_access_key
      @version = "2012-12-12"
      @hmac = Route53::HMAC.new('sha1', @aws_secret_access_key)
    end
 
    # Creates a recordset
    def create_record(name, value, type, zone_id)
      do_post("CREATE", name, value, type, zone_id)
    end
 
    # Deletes a recordset
    def delete_record(name, value, type, zone_id)
      do_post("DELETE", name, value, type, zone_id)
    end
 
    def create_or_update_record(name, value, type, zone_id)
      begin
        create_record(name, value, type, zone_id)
      rescue
        delete_record(name, value, type, zone_id)
        create_record(name, value, type, zone_id)
      end
    end
    
    private
 
    def do_post(operation, name, value, type, zone_id)
      request({
        :method => "POST",
        :path => "hostedzone/#{zone_id}/rrset",
        :body => 
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<ChangeResourceRecordSetsRequest xmlns=\"https://route53.amazonaws.com/doc/#{@version}/\">
   <ChangeBatch>
      <Comment></Comment>
      <Changes>
         <Change>
            <Action>#{operation}</Action>
            <ResourceRecordSet>
               <Name>#{name}</Name>
               <Type>#{type}</Type>
               <TTL>3600</TTL>
               <ResourceRecords>
               #{to_resource_value(value)}
               </ResourceRecords>
            </ResourceRecordSet>
         </Change>
      </Changes>
   </ChangeBatch>
</ChangeResourceRecordSetsRequest>"
      }) do |response|
        raise response.body unless response.kind_of? Net::HTTPSuccess
      end
    end
    
    def to_resource_value(value)
      return "<ResourceRecord><Value>#{value}</Value></ResourceRecord>" unless value.kind_of?(Array)
      value.map { |e| "<ResourceRecord><Value>#{e}</Value></ResourceRecord>" }.join
    end
 
    def request(params, &block)
      params[:headers] ||= {}
      params[:headers]['Content-Type'] = "application/xml"
      params[:headers]['Date'] = Time.new.httpdate
      params[:headers]['X-Amzn-Authorization'] = "AWS3-HTTPS AWSAccessKeyId=#{@aws_access_key_id},Algorithm=HmacSHA1,Signature=#{signature(params)}"
      params[:path] = "#{@version}/#{params[:path]}"
      uri = URI.parse("#{@endpoint}#{params[:path]}")
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.start do |http|
        case params[:method]
        when "GET"
          response = https.get(uri.path, params[:headers])
        else
          response = https.post(uri.path, params[:body], params[:headers])
        end
        yield response
      end
    end
  
    def signature(params)
      string_to_sign = params[:headers]['Date']
      signed_string = @hmac.sign(string_to_sign)
      Base64.encode64(signed_string).chomp!
    end
  end
 
  # imported from fog
  class HMAC
 
    def initialize(type, key)
      @key = key
      case type
      when 'sha1'
        setup_sha1
      when 'sha256'
        setup_sha256
      end
    end
 
    def sign(data)
      @signer.call(data)
    end
 
    private
 
    def setup_sha1
      @digest = OpenSSL::Digest::Digest.new('sha1')
      @signer = lambda do |data|
        OpenSSL::HMAC.digest(@digest, @key, data)
      end
    end
 
    def setup_sha256
      begin
        @digest = OpenSSL::Digest::Digest.new('sha256')
        @signer = lambda do |data|
          OpenSSL::HMAC.digest(@digest, @key, data)
        end
      rescue RuntimeError => error
        unless error.message == 'Unsupported digest algorithm (sha256).'
          raise error
        else
          require 'hmac-sha2'
          @hmac = ::HMAC::SHA256.new(@key)
          @signer = lambda do |data|
            @hmac.update(data)
            @hmac.digest
          end
        end
      end
    end
 
  end
end
