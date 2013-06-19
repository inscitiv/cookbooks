include_recipe "conjur"

ldap_uri = node['conjur']['ldap']['uri'][conjur_stack]
raise "No conjur.ldap.uri configured, and no default available for stack #{conjur_stack}" unless ldap_uri

require 'conjur/authn'
host, password = Conjur::Authn.read_credentials
raise "No Conjur credentials on this host" unless host && password
if host.index('host/') == 0
  host = host.split('/')[1..-1].join('/')
else
  raise "Conjur current user must be a host; got #{host}"
end

# Answer the installer questions about LDAP server location, root name, etc
template "/tmp/ldap.seed" do
  source "ldap.seed.erb"
end

# Answer the installer questions about LDAP server location, root name, etc
template "/usr/share/pam-configs/my_mkhomedir" do
  source "my_mkhomedir.erb"
end

execute "debconf-set-selections /tmp/ldap.seed"

for pkg in %w(debconf nss-updatedb nscd libpam-mkhomedir auth-client-config ldap-utils ldap-client libpam-ldapd libnss-ldapd)
  package pkg do
    options "-qq"
  end
end

for s in %w(nscd nslcd ssh)
  service s do
    supports :restart => true
  end
end

ruby_block "Enable ssh password authentication" do
  block do
    file = Chef::Util::FileEdit.new("/etc/ssh/sshd_config")
    file.search_file_replace_line(/PasswordAuthentication\s+no/, "PasswordAuthentication yes")
    file.write_file    
  end
  notifies :restart, [ "service[ssh]" ]
end

template "/etc/nslcd.conf" do
  source "nslcd.conf.erb"
  variables uri: ldap_uri,
   base: "ou=user,host=#{host},account=ci,o=conjur",
   binddn: "uid=#{host},ou=host,host=#{host},account=ci,o=conjur",
   bindpw: password
  notifies :restart, [ "service[nscd]", "service[nslcd]" ]
end

execute "pam-auth-update" do
  command "pam-auth-update --package"
  notifies :restart, [ "service[nscd]", "service[nslcd]" ]
end
