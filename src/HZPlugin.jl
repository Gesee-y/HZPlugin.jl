#######################################################################################################################
################################################ OUTDOORS PLUGIN ######################################################
#######################################################################################################################

module HZPlugin

export HZPLUGIN, RegisterBackend

using Reexport
using Cruise
@reexport using Horizons

mutable struct HorizonManager
	windows::Dict{HRenderer, WeakRef}

	## Constructor

	HorizonManager() = new(Dict{HRenderer, WeakRef}())
end

const HZPLUGIN = CRPlugin()
const MANAGER = HorizonManager()
PHASE = :postupdate

add_system!(HZPlugin, MANAGER)

################################################# PLUGIN LIFECYCLE ####################################################

function Cruise.awake!(n::CRPluginNode{ODApp})
	InitHorizons()
	setstatus(n, PLUGIN_OK)
end

function Cruise.update!(n::CRPluginNode{ODApp})
	manager = n.obj
	backends = keys(manager.windows)
	for backend in backends
		SetDrawColor(backend,WHITE)
        ClearViewport(backend)
        UpdateRender(backend)
    end
end

function Cruise.shutdown!(n::CRPluginNode{ODApp})
	QuitHorizons()
	setstatus(n, PLUGIN_OFF)
end

################################################## OTHER FUNCTIONS #####################################################

function RegisterBackend(R::Type, win, args...)
	backend = InitBackend(R, win, args...)
	MANAGER.windows[backend] = WeakRef(win)
end

function QuitHorizons()
	## Don't Know yet
end