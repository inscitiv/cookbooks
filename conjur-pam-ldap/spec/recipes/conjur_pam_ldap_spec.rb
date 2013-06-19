require 'spec_helper'

describe 'conjur-pam-ldap::default' do
  let(:chef_run) { ChefSpec::ChefRunner.new(cookbook_path: File.expand_path('../../../', File.dirname(__FILE__))) }
  let(:converge) { chef_run.converge 'conjur-pam-ldap::default' }
  let(:password) { 'the-password' }
  let(:stack) { 'ci' }
  before {
    Chef::Recipe.any_instance.stub(:conjur_stack).and_return stack
    Chef::Recipe.any_instance.stub(:init_conjur)
    require 'conjur/authn'
    Conjur::Authn.stub(:read_credentials).and_return [ host, password ]
  }
  shared_examples_for "creates /etc/nslcd.conf with expected content" do
    specify {
      lines = [
        "uri #{ldap_uri}",
        "binddn uid=the-host,ou=host,host=the-host,account=ci,o=conjur",
        "bindpw the-password"
      ]
      lines.each do |line|
        expect(chef_run).to create_file_with_content('/etc/nslcd.conf', line)
      end
    }
  end
  context "logged in as user" do
    let(:host) { 'the-user' }
    it "refuses to run" do
      lambda { converge }.should raise_error("Conjur current user must be a host; got the-user")
    end
  end
  context "logged in as host" do
    let(:host) { 'host/the-host' }
    let(:ldap_uri) { nil }
    before {
      Chef::Recipe.any_instance.stub(:conjur_stack).and_return stack
      chef_run.node.set['conjur']['ldap']['uri']['v3'] = ldap_uri if ldap_uri
      converge
    }
    context "on ci stack" do
      it_should_behave_like "creates /etc/nslcd.conf with expected content"
    end
    context "on default stack" do
      let(:stack) { 'v3' }
      let(:ldap_uri) { 'ldap://ldap.example.com' }
      it_should_behave_like "creates /etc/nslcd.conf with expected content"
    end
  end
end