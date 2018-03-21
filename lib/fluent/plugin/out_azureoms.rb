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
require "date"
require "base64"

module Fluent
  module Plugin
    class AzureomsOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output("azureoms", self)

      helpers :thread # for try_write

      config_param :workspace, :string
      config_param :signature, :string

      def configure(conf)
        auth_string = "Authorization: SharedKey #{workspace}:#{signature}"
        logger.debug("Authorization string is #{auth_string}")

        super
      end

      # This output plugin uses the raw HTTP data collector
      # API per https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-data-collector-api

      def prefer_buffered_processing 
        true
      end



      def process(tag, es)
        print "Writing single record set (synchronous)"
        es.each do | time, record| 
          log.debug "Writing record #{record.inspect}"          
          # TODO - publish events
        end 
      end 

      # Synchronous buffered output
      def write(chunk) 
        log.debug "Writing buffered record set (synchronous)"
        log.debug "writing data to file", chunk_id: dump_unique_id_hex(chunk.unique_id)

        chunk.each do |time, record|
          log.debug "Writing record #{record.inspect}"    
        end
      end

      def format(tag, record, time)
        [tag, time, record].to_json
      end

      def send_data(json_str)

        # Signature and headers
        rfc1123date = DateTime.now().strftime("%a, %d %b %Y %H:%M:%S GMT")

      end

      def build_signature(customer_id, shared_key, date, content_length, method, content_type, resource)
        string_to_hash = "#{method}\n#{content_length}\n#{content_type}\nx-ms-date: #{date}\n#{resource}"
        decoded_key = Base64.decode(shared_key)
        secure_hash = OpenSSL::HMAC.hexdigest('SHA256', decoded_key, string_to_hash)
        encoded_hash = Base64.encode(secure_hash)
        authorization = "SharedKey #{customer_id}:#{encoded_hash}"
        return authorization
      end

      # def build_signature(customer_id, shared_key, date, content_length, method, content_type, resource):
      #   x_headers = 'x-ms-date:' + date
      #   string_to_hash = method + "\n" + str(content_length) + "\n" + content_type + "\n" + x_headers + "\n" + resource
      #   bytes_to_hash = bytes(string_to_hash).encode('utf-8')  
      #   decoded_key = base64.b64decode(shared_key)
      #   encoded_hash = base64.b64encode(hmac.new(decoded_key, bytes_to_hash, digestmod=hashlib.sha256).digest())
      #   authorization = "SharedKey {}:{}".format(customer_id,encoded_hash)
      #   return authorization
      # end
    end
  end
end
