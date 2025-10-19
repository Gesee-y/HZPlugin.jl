#######################################################################################################################
################################################ HORIZONS PLUGIN ######################################################
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

	HorizonManager() = new(Dict{Type, HZRegistration}(), Dict{HRenderer, WeakRef}())
end

const HZPLUGIN = CRPlugin()
const MANAGER = HorizonManager()
PHASE = :postupdate

const ID = add_system!(HZPLUGIN, MANAGER)

Horizons.connect(HORIZON_ERROR) do msg,err
	node = HZPLUGIN.idtonode[ID]
	setstatus(node, PLUGIN_ERR)
	setlasterr(node, msg*err)
end

################################################# PLUGIN LIFECYCLE ####################################################

function Cruise.awake!(n::CRPluginNode{HorizonManager})
	for (R, data) in MANAGER.data
		win = data.win
		backend = InitBackend(R, win, data.args...)
		MANAGER.backends[backend] = WeakRef(win)
	end

	empty!(MANAGER.data)
	setstatus(n, PLUGIN_OK)
end

function Cruise.update!(n::CRPluginNode{HorizonManager})
	manager = n.obj
	backends = keys(manager.backends)
	for backend in backends
        SetDrawColor(backend,WHITE)
        ClearViewport(backend)
        UpdateRender(backend)
    end
end

function Cruise.shutdown!(n::CRPluginNode{HorizonManager})
	setstatus(n, PLUGIN_OFF)
end

################################################## OTHER FUNCTIONS #####################################################

function RegisterBackend(R::Type, win, args...)
	MANAGER.data[R] = HZRegistration(win,args)
end
