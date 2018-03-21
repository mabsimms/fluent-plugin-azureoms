require "helper"
require "fluent/plugin/out_azureoms.rb"
require "date"

class AzureomsOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  json_string = '[{"DemoField1":"DemoValue1","DemoField2":"DemoValue2"},{"DemoField3":"DemoValue3","DemoField4":"DemoValue4"}]'
  workspace_id = "424b6a54-6de2-44b5-9768-04497fb1c7e6"
  test_key = "ZuvTFOSXEPUhQrB7YXh94Wm+bWP3emiTlm8symdka+u4tQF+w6tPjGe4WFrh5SN7mQly4yQhkzFha6yjr8GH1w=="
  log_name = "DemoExample";

  hashed_string = '3oXy0IjaKA/V2/Kx+/BlXx7y6tvLYMM8/jwpWBO3c+c='
  signature = 'SharedKey 424b6a54-6de2-44b5-9768-04497fb2c7e6:3oXy0IjaKA/V2/Kx+/BlXx7y6tvLYMM8/jwpWBO3c+c='
  time = Time::strptime("21-03-2018 00:12:10+00:00", "%d-%m-%Y %H:%M:%S%z")

  content_length = json_string.length
  method = "POST"
  content_type = "application/json"
  resource = "/api/logs"

  conf = %[ 
    workspace 424b6a54-6de2-44b5-9768-04497fb1c7e6
    key ZuvTFOSXEPUhQrB7YXh94Wm+bWP3emiTlm8symdka+u4tQF+w6tPjGe4WFrh5SN7mQly4yQhkzFha6yjr8GH1w==
  ]

  test "build_signature" do    
 
    d = create_driver(conf)
      
    calculated_signature = d.instance.build_signature(
      test_key, time, content_length, method, content_type, resource)

    #assert_equal(signature, calculated_signature)
    
  end

  test "send_data" do
    d = create_driver(conf)

    request_date = Time.now()

    calculated_signature = d.instance.build_signature(
      test_key, request_date, content_length, method, content_type, resource)

    response = d.instance.send_data(log_name, calculated_signature, request_date, json_string)

  end
  
  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::AzureomsOutput).configure(conf)
  end
end
