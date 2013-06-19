chef_gem "netrc"

# Read the netrc and find the entry for the conjur authn endpoint
require 'netrc'
netrc = Netrc.read
user, password = netrc['https://authn-ci-conjur.herokuapp.com']
host = user.split('/')[1..-1].join('/')

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

[ [ 'users', 100, 5000 ], [ 'admin', 111, 50000 ] ].each do |group|
  name, src, dest = group
  group name do
    gid dest
    action :modify
  end
  execute "change gid of #{src} to #{dest}" do
   command "find / -gid #{src} -exec chgrp #{dest} {} +"
   only_if do
     require 'etc'
     begin
       Etc.getgrnam(name).gid == src
     rescue ArgumentError
       false
     end
   end
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
	variables uri: "ldap://ec2-23-20-251-229.compute-1.amazonaws.com:1389",
	 base: "ou=user,host=#{host},account=ci,o=conjur",
	 binddn: "uid=#{host},ou=host,host=#{host},account=ci,o=conjur",
	 bindpw: password
	notifies :restart, [ "service[nscd]", "service[nslcd]" ]
end

execute "pam-auth-update" do
	command "pam-auth-update --package"
	notifies :restart, [ "service[nscd]", "service[nslcd]" ]
end
