require 'spec_helper'

require 'conjur_chef'

describe 'conjur::default' do
  subject {
    Object.new.tap do |obj|
      class << obj
        include ConjurChef
      end
    end
  }
  
  before {
    subject.should_receive(:init_conjur).at_least(1)
  }
  
  its(:conjur_env) { should == 'production' }
  its(:conjur_stack) { should == 'v3' }
end