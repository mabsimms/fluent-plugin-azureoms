require "helper"
require "fluent/plugin/out_azureoms.rb"

class AzureomsOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "success" do
    
  end

  test "build_signature" do    
    json_string = '[{""DemoField1"":""DemoValue1"",""DemoField2"":""DemoValue2""},{""DemoField3"":""DemoValue3"",""DemoField4"":""DemoValue4""}]'
    workspace_id = "424b6a54-6de2-44b5-9768-04497fb2c7e6"
    test_key = "ZuvTFOSXEPUhQrB7YXh94Wm+bWP3emiTlm8symdka+u4tqF+w6tPjGe4WFrh5SN7mQly4yQhkzFha6yjr8GH1w=="
    log_name = "DemoExample";

    hashed_string = 'LAAAfweblJcSyYNM+ZoUEs1XvDPB0NTBJ1zg2b/xUGo='
    signature = 'SharedKey 424b6a54-6de2-44b5-9768-04497fb2c7e6:LAAAfweblJcSyYNM+ZoUEs1XvDPB0NTBJ1zg2b/xUGo='


  end
  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::AzureomsOutput).configure(conf)
  end
end
