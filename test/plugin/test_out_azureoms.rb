require "helper"
require "fluent/test"
require "fluent/test/driver/output"
require "fluent/test/helpers"
require "fluent/plugin/out_azureoms.rb"
require "date"
require "pp"

class AzureomsOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers
  
  json_string = '[{"DemoField1":"DemoValue1","DemoField2":"DemoValue2"},{"DemoField3":"DemoValue3","DemoField4":"DemoValue4"}]'
  log_name = "DemoExample";

  content_length = json_string.length
  method = "POST"
  content_type = "application/json"
  resource = "/api/logs"

  # This conf can be used with the full fluent driver (aka when initializing)
  conf = %[ 
    workspace "#{ENV['OMS_WORKSPACE']}"
    key "#{ENV['OMS_KEY']}"
  ]

  # This conf can be used when working with methods directly
  direct_conf = { 
    "workspace" => ENV['OMS_WORKSPACE'],
    "key"       => ENV['OMS_KEY']
  }

  setup do
    Fluent::Test.setup        
  end

  # TODO - plug in some fake deterministic values
  # test "build_signature" do     
  #   d = create_driver(conf)      
  #   calculated_signature = d.instance.build_signature(
  #     direct_conf['key'], time, content_length, method, content_type, resource)
  #   assert_equal(signature, calculated_signature)    
  # end

  test "send_data" do
    d = create_driver(conf)
    response = d.instance.send_data(log_name, direct_conf['key'], json_string, log_name)
  end

  test "emit" do
    d = create_driver(conf)
    time = event_time
    msg = "Todo"
    d.run do
      d.feed("test", time, { 'key1' => 'value1', 'key2' => 'value2', 'message' => msg})
    end 

    #assert_equal(1, d.events.size)
  end 
  
  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::AzureomsOutput).configure(conf)
  end
end
