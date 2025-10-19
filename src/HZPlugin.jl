#######################################################################################################################
################################################ OUTDOORS PLUGIN ######################################################
#######################################################################################################################

module HZPlugin

export HZPLUGIN, RegisterBackend

using Reexport
using Cruise
@reexport using Horizons

struct HZRegistration
	win::Any
	args::Tuple
end

mutable struct HorizonManager
	data::Dict{Type, HZRegistration}
	backends::Dict{HRenderer, WeakRef}

	## Constructor

	HorizonManager() = new(Dict{Type, Tuple{WeakRef, HZRegistration}}(), Dict{HRenderer, WeakRef}())
end

const HZPLUGIN = CRPlugin()
const MANAGER = HorizonManager()
PHASE = :postupdate

const ID = add_system!(HZPlugin, MANAGER)

Horizons.connect(HORIZON_ERROR) do msg,err
	node = ODPLUGIN.idtonode[ID]
	setstatus(node, PLUGIN_ERR)
	setlasterr(node, msg*err)
end

################################################# PLUGIN LIFECYCLE ####################################################

function Cruise.awake!(n::CRPluginNode{ODApp})
	for (R, data) in MANAGER.data
		win = data.win
		backend = InitBackend(R, win, data.args...)
		MANAGER.backends[backend] = WeakRef(win)
	end

	empty!(MANAGER.data)
	setstatus(n, PLUGIN_OK)
end

function Cruise.update!(n::CRPluginNode{ODApp})
	manager = n.obj
	backends = keys(manager.backends)
	for backend in backends
		SetDrawColor(backend,WHITE)
        ClearViewport(backend)
        UpdateRender(backend)
    end
end

function Cruise.shutdown!(n::CRPluginNode{ODApp})
	setstatus(n, PLUGIN_OFF)
end

################################################## OTHER FUNCTIONS #####################################################

function RegisterBackend(R::Type, win, args...)
	MANAGER.windows[R] = HZRegistration(win,args)
end
