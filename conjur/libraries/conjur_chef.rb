require 'conjur/config'

module ConjurChef
  def conjur_env
    init_conjur

    Conjur::Config[:env] || 'production'
  end
  
  def conjur_stack
    init_conjur
    
    stack = Conjur::Config[:stack]
    stack ||= "v3" if conjur_env == 'production'
    raise "No Conjur stack defined" unless stack
    stack
  end
  
  private
  
  def init_conjur
    require 'conjur/cli'
  end
end

class Chef::Recipe
  include ConjurChef
end