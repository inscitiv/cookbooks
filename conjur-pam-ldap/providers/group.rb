notifying_action :create do
  src = begin
    Etc.getgrnam(new_resource.name).gid
  rescue ArgumentError
    nil
  end
  
  # If the group exists, modify the gid and change the gid of existing files
  # If the group does not exist, create it
  if src
    group new_resource.name do
      gid new_resource.gid
      action :modify
    end
    execute "change gid of #{src} to #{new_resource.gid}" do
      command "find / -gid #{src} -exec chgrp #{new_resource.gid} {} +"
    end
  else
    group new_resource.name do
      gid new_resource.gid
    end
  end
end
