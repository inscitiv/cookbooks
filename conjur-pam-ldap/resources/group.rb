actions :create

default_action :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :gid,  :kind_of => Fixnum, :required => true
