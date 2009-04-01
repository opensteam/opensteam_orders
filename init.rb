# Include hook code here

require File.join( File.dirname(__FILE__), "lib", "states", "finished")
require File.join( File.dirname(__FILE__), "lib", "states", "processing")
require File.join( File.dirname(__FILE__), "lib", "states", "pending")


Opensteam::Extension.register :orders do
  backend :sales
end
  
config.to_prepare do
  require_dependency 'order'
end
  