require "helper"
require "fluent/plugin/out_azureoms.rb"

class AzureomsOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "success" do
    
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::AzureomsOutput).configure(conf)
  end
end
