notifying_action :create do
  src = begin
    require 'etc'
    Etc.getgrnam(new_resource.name).gid
  rescue ArgumentError
    nil
  end
  
  # If the group exists, modify the gid and change the gid of existing files
  # If the group does not exist, create it
  if src
    if src != new_resource.gid
      group new_resource.name do
        gid new_resource.gid
        action :modify
      end
      execute "find / -gid #{src} -exec chgrp #{new_resource.gid} {} + | true"
    end
  else
    group new_resource.name do
      gid new_resource.gid
    end
  end
end
