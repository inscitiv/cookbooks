chef_gem "netrc"

# Read the netrc and find the entry for the conjur authn endpoint
netrc = Netrc.read


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
end

template "/etc/nslcd.conf" do
	source "nslcd.conf.erb"
	variables uri: "",
	 base: "",
	 binddn: "",
	 bindpw: ""
	notifies :restart, [ "service[nscd]", "service[nslcd]" ]
end

execute "pam-auth-update" do
	command "pam-auth-update --package"
	notifies :restart, [ "service[nscd]", "service[nslcd]" ]
end
