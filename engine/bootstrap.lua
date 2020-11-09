if __ANT_RUNTIME__ then
    require "runtime.vfs"
    require "runtime.errlog"
else
    require "editor.init_cpath"
    require "common.thread"
    require "editor.vfs"
    require "editor.log"
end

require "common.init_bgfx"
require "filesystem"
require "packagemanager"

if __ANT_RUNTIME__ then
    require "runtime.debug"
end
