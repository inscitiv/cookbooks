require 'rspec'
require 'spork'
require 'chef'
require 'chefspec'

Spork.prefork do
  require 'fakefs/spec_helpers'
  require 'fauxhai'
  
  RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.run_all_when_everything_filtered = true
    config.filter_run :focus
  end
  
  for path in Dir['*/libraries']
    $LOAD_PATH.unshift(path)
  end

  def default_json_attributes
    {
      :ipaddress => '127.0.0.1',
      :platform => "ubuntu",
      :platform_version => "12.04",
      :kernel => { 
        :machine => 'x86_64' 
      },
      :memory => {
        :total => [ 4 * 1000, 'mb' ].join
      },
      :command => {
        :ps => "ps -ef"
      }
    } 
  end
end

Spork.each_run do
end
