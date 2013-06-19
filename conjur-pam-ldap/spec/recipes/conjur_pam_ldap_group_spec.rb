require 'spec_helper'

require 'chefspec/matchers/shared'

module ChefSpec
  module Matchers
    define_resource_matchers([:modify], [:group], :group_name)
  end
end

describe 'test-conjur-pam-ldap-group::default' do
  let(:chef_run) { 
    ChefSpec::ChefRunner.new(:step_into => ['conjur-pam-ldap_group'], 
      cookbook_path: [ File.expand_path('../cookbooks', File.dirname(__FILE__)), File.expand_path('../../../', File.dirname(__FILE__)) ]) 
  }
  let(:converge) { chef_run.converge 'test-conjur-pam-ldap-group::default' }
  
  context "when a group doesn't exist" do
    before {
      require 'etc'
      Etc.should_receive(:getgrnam).with('admin').and_raise ArgumentError
    }
    it 'creates the group' do
      converge
      
      expect(converge).to create_group('admin')
      expect(converge).to_not modify_group('admin')
    end
  end
  context "when a group exists" do
    before {
      require 'etc'
      Etc.should_receive(:getgrnam).with('admin').and_return double(:group, gid: 101)
    }
    it 'updates the group' do
      converge
      
      expect(converge).to_not create_group('admin')
      expect(converge).to modify_group('admin')
      expect(converge).to execute_command("find / -gid 101 -exec chgrp 50000 {} +")
    end
  end
end