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
      expect(converge).to create_group('admin')
      expect(converge).to_not modify_group('admin')
    end
  end
  context "when a group exists" do
    before {
      require 'etc'
      Etc.should_receive(:getgrnam).with('admin').and_return double(:group, gid: gid)
    }
    context "with the same gid" do
      let(:gid) { 50000 }
      it 'does nothing' do
        converge
        
        # The LWRP resource should be the only one
        chef_run.resources.map{|c| [ c.resource_name, c.name ]}.should == [ [:"conjur-pam-ldap_group", "admin"] ]
      end
    end
    context "with a different gid" do
      let(:gid) { 101 }
      it 'updates the group' do
        expect(converge).to_not create_group('admin')
        expect(converge).to modify_group('admin')
        expect(converge).to execute_command("find / -gid 101 -exec chgrp 50000 {} + | true")
      end
    end
  end
end