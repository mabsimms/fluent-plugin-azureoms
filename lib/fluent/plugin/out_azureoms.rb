#
# Copyright 2018- TODO: Write your name
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/plugin/output"
require "time"
require "base64"
require "openssl"
require "uri"
require "net/https"
require "json"

module Fluent
  module Plugin
    class AzureomsOutput < Fluent::Plugin::Output
      
      helpers :event_emitter, :compat_parameters, :record_accessor

      Fluent::Plugin.register_output("azureoms", self)

      DEFAULT_BUFFER_TYPE = "memory"

      config_param :workspace, :string
      config_param :key, :string, secret: true
      config_param :timestamp_field, :string, default: "timestamp"

      config_section :buffer do
        config_set_default :@type, DEFAULT_BUFFER_TYPE
        config_set_default :chunk_keys, ['tag']
        config_set_default :timekey_use_utc, true
      end

      def configure(conf)
        # This also calls config_param (don't access configuration parameters before
        # calling super)
        super       

        # Require chunking by tag keys
        raise Fluent::ConfigError, "'tag' in chunk_keys is required." if not @chunk_key_tag
      end

      # This output plugin uses the raw HTTP data collector
      # API per https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-data-collector-api

      def prefer_buffered_processing 
        true
      end

      def process(tag, es)
        print "Writing single record set (synchronous)\n"
        log_name = tag_to_log_name(chunk.metadata.tag)
        es.each do |time, record|           
          # Convert record into a JSON body payload for OMS
          record[:timestamp] = Time.at(time).iso8601          

          # Publish event
          send_data(workspace, key, record.to_json, log_name)        
        end 
      end 

      # Synchronous buffered output
      def write(chunk) 
        log.debug "Writing buffered record set (synchronous)"
        log.debug "writing data to file", chunk_id: dump_unique_id_hex(chunk.unique_id)

        log_name = tag_to_log_name(chunk.metadata.tag)
        log.debug "writing data to log type ", log_name
        elements = Array.new
        
        chunk.each do |time, record|
          log.debug "Writing record #{record.inspect}"    

          # Fold the timestamp into the record
          record[:timestamp] = Time.at(time).iso8601

          # Append the record to the content in the appropriate format
          elements.push(record)

          # TODO - check size of content buffer and flush when it approaches 
          # watermark
          if false 
            log.debug "Elements buffer approaching max send size; flushing #{elements.length} to logname #{log_name}"    
            send_data(workspace, key, elements.to_json, log_name) 
            elements.clear
          end 
        end

        if elements.length > 0
          log.debug "Flushing #{elements.length} to logname #{log_name}"
          send_data(workspace, key, elements.to_json, log_name)     
        end        
      end

      def tag_to_log_name(tag)
        if tag.include? '.' 
          tags = tag.split('.') 
          return tags[-1]
        end
        return tag
      end

      def send_data(customer_id, shared_key, content, log_name)        
          current_time = Time.now.utc
          signature = build_signature(
            shared_key, current_time, content.length, 
            "POST", "application/json", "/api/logs")
          publish_data(log_name, signature, current_time, content)
      end

      def publish_data(log_name, signature, time, json)
        url = "https://#{workspace}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
        uri = URI url

        rfc1123date = time.utc.strftime("%a, %d %b %Y %H:%M:%S GMT")

        response = Net::HTTP.start(uri.hostname, uri.port, 
          :use_ssl => uri.scheme == 'https') do |http|

          req = Net::HTTP::Post.new(uri.to_s)
          req.body = json.to_s
          
          # Signature and headers
          req['Content-Type'] = 'application/json'
          req['Log-Type'] = log_name
          req['Authorization'] = signature
          req['x-ms-date'] = rfc1123date
      
          log.debug "Publishing record of length #{req.body.length} to OMS workspace #{workspace}"    
          http.request(req)          
        end

        case response 
        when Net::HTTPSuccess
          log.debug "Successfully published record of length #{json.length} to OMS workspace #{workspace}"                 
        else
          # TODO - throw error
          log.warn "Could not publish record of length #{json.length} to OMS workspace #{workspace} because #{response.body}"
        end 
        response
      end
  
      def build_signature(shared_key, date, content_length, method, content_type, resource)
        rfc1123date = date.utc.strftime("%a, %d %b %Y %H:%M:%S GMT")
        string_to_hash = "#{method}\n#{content_length}\n#{content_type}\nx-ms-date:#{rfc1123date}\n#{resource}"        
        decoded_key = Base64.decode64(shared_key)
        secure_hash = OpenSSL::HMAC.digest('SHA256', decoded_key, string_to_hash)
              
        encoded_hash = Base64.encode64(secure_hash).strip()
        authorization = "SharedKey #{workspace}:#{encoded_hash}"
      
        return authorization
      end    
    end
  end
end