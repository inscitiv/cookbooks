require 'spec_helper'

describe 'conjur::default' do
  let(:chef_run) { ChefSpec::ChefRunner.new(cookbook_path: File.expand_path('../../../', File.dirname(__FILE__))) }
  
  it 'should load Conjur' do
    Chef::Recipe.any_instance.stub(:init_conjur)

    chef_run.converge subject
    
    expect(chef_run).to install_chef_gem('conjur-cli')
  end
end