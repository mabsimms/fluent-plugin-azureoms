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

  hashed_string = '3oXy0IjaKA/V2/Kx+/BlXx7y6tvLYMM8/jwpWBO3c+c='
  signature = 'SharedKey 424b6a54-6de2-44b5-9768-04497fb2c7e6:1aHwzUHSJ6Ok4ExaKG3i7Opgzy/YqxcjqXH58rssu+I='
  time = Time::strptime("21-03-2018 00:12:10+00:00", "%d-%m-%Y %H:%M:%S%z")

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
    pp response
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
