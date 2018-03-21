require "helper"
require "fluent/plugin/out_azureoms.rb"
require "date"

class AzureomsOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "success" do
    
  end

  test "build_signature" do    
    json_string = '[{"DemoField1":"DemoValue1","DemoField2":"DemoValue2"},{"DemoField3":"DemoValue3","DemoField4":"DemoValue4"}]'
    workspace_id = "424b6a54-6de2-44b5-9768-04497fb2c7e6"
    test_key = "ZuvTFOSXEPUhQrB7YXh94Wm+bWP3emiTlm8symdka+u4tqF+w6tPjGe4WFrh5SN7mQly4yQhkzFha6yjr8GH1w=="
    log_name = "DemoExample";

    hashed_string = 'LAAAfweblJcSyYNM+ZoUEs1XvDPB0NTBJ1zg2b/xUGo='
    signature = 'SharedKey 424b6a54-6de2-44b5-9768-04497fb2c7e6:LAAAfweblJcSyYNM+ZoUEs1XvDPB0NTBJ1zg2b/xUGo='

    conf = %[ 
      workspace 424b6a54-6de2-44b5-9768-04497fb2c7e6
      key ZuvTFOSXEPUhQrB7YXh94Wm+bWP3emiTlm8symdka+u4tqF+w6tPjGe4WFrh5SN7mQly4yQhkzFha6yjr8GH1w==      
    ]

    d = create_driver(conf)

    STDOUT.set_encoding "UTF-8"
    
    # x-ms-date:Wed, 21 Mar 2018 00:12:10 GMT
    date = DateTime::strptime("21-03-2018 00:12:10+00:00", "%d-%m-%Y %H:%M:%S%z")

    puts "JSON string is"
    puts json_string

    puts "Reference date is "
    puts date

    content_length = json_string.length
    method = "POST"
    content_type = "application/json"
    resource = "/api/logs"
    calculated_signature = d.instance.build_signature(
      workspace_id, test_key, date, content_length, method, content_type, resource)

    assert_equal(signature, calculated_signature)
    puts calculated_signature

  end
  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::AzureomsOutput).configure(conf)
  end
end
