package com.junkbyte.console.core
{
    import com.junkbyte.console.events.ConsoleModuleEvent;
    import com.junkbyte.console.interfaces.IConsoleModule;
    import com.junkbyte.console.vos.ConsoleModuleMatch;

    public class ModuleDependenceCallback
    {
		protected var modulesManager:ConsoleModulesManager;
		
        protected var dependencies:Vector.<DependencyCallback> = new Vector.<DependencyCallback>();

		protected var matchedModules:Vector.<MatchedModule> = new Vector.<MatchedModule>;
		
		public static function createUsingModule(module:ConsoleModule):ModuleDependenceCallback
		{
			var instance:ModuleDependenceCallback = new ModuleDependenceCallback();
			instance.initUsingModule(module);
			return instance;
		}
		
		private function initUsingModule(module:ConsoleModule):void
		{
			module.addEventListener(ConsoleModuleEvent.REGISTERED_TO_CONSOLE, onSrcModuleRegistered, false, 0, true);
			module.addEventListener(ConsoleModuleEvent.UNREGISTERED_FROM_CONSOLE, onSrcModuleUnregistered, false, 0, true);
			
			if(module.isRegisteredToConsole())
			{
				initUsingModulesManager(module.modules);
			}
		}
		
		private function onSrcModuleRegistered(event:ConsoleModuleEvent):void
		{
			var module:ConsoleModule = event.module as ConsoleModule;
			initUsingModulesManager(module.modules);
		}
		
		private function onSrcModuleUnregistered(event:ConsoleModuleEvent):void
		{
			modulesManager.removeEventListener(ConsoleModuleEvent.MODULE_REGISTERED, onAnyModuleRegistered);
			
			for (var i:int = matchedModules.length - 1; i >=0 ; i--)
			{
				var matched:MatchedModule = matchedModules[i];
				matchUnRegistered(matched);
			}
		}
		
		public static function createUsingModulesManager(modulesManager:ConsoleModulesManager):ModuleDependenceCallback
		{
			var instance:ModuleDependenceCallback = new ModuleDependenceCallback();
			instance.initUsingModulesManager(modulesManager);
			return instance;
		}
		
		private function initUsingModulesManager(modulesManager:ConsoleModulesManager):void
		{
			this.modulesManager = modulesManager;
			
			modulesManager.addEventListener(ConsoleModuleEvent.MODULE_REGISTERED, onAnyModuleRegistered);
			
			var len:uint = dependencies.length;
			for (var i:int = 0; i < len; i++)
			{
				var cb:DependencyCallback = dependencies[i];
				findAndRegisterMatchesOf(cb);
			}
		}
		
		private function onAnyModuleRegistered(event:ConsoleModuleEvent):void
		{
			for each (var cb:DependencyCallback in dependencies)
			{
				if (cb.moduleMatch.matches(event.module))
				{
					matchRegistered(cb, event.module);
				}
			}
		}

        public function addCallback(matcher:ConsoleModuleMatch, registerCallback:Function, unregisterCallback:Function):void
        {
            var cb:DependencyCallback = new DependencyCallback(matcher, registerCallback, unregisterCallback);
			
			dependencies.push(cb);
			
			if (modulesManager != null)
			{
				findAndRegisterMatchesOf(cb);
			}
        }
		
		public function removeAllCallbacks():void
		{
			dependencies.splice(0, dependencies.length);
			matchedModules.splice(0, matchedModules.length);
		}
		
		private function findAndRegisterMatchesOf(cb:DependencyCallback):void
		{
			var matches:Vector.<IConsoleModule> = modulesManager.findModulesByMatcher(cb.moduleMatch);
			for each(var matchingModule:IConsoleModule in matches)
			{
				matchRegistered(cb, matchingModule);
			}
		}

        private function matchRegistered(cb:DependencyCallback, module:IConsoleModule):void
        {
			var matchedModule:MatchedModule = new MatchedModule(module, cb);
			
			matchedModules.push(matchedModule);
			
            module.addEventListener(ConsoleModuleEvent.UNREGISTERED_FROM_CONSOLE, onMatchedModuleUnregistered);
			
			cb.registered(module);
        }
		
		private function onMatchedModuleUnregistered(event:ConsoleModuleEvent):void
		{
			for (var i:int = matchedModules.length - 1; i >=0 ; i--)
			{
				var matched:MatchedModule = matchedModules[i];
				if(matched.module == event.module)
				{
					matchUnRegistered(matched);
				}
			}
		}

        private function matchUnRegistered(matchedModule:MatchedModule):void
        {
			var index:int = matchedModules.indexOf(matchedModule);
			if(index >= 0)
			{
				matchedModules.splice(index, 1);
			}
			
			matchedModule.module.removeEventListener(ConsoleModuleEvent.UNREGISTERED_FROM_CONSOLE, onMatchedModuleUnregistered);
			
			matchedModule.unregistered();
        }
    }
}

import com.junkbyte.console.interfaces.IConsoleModule;
import com.junkbyte.console.vos.ConsoleModuleMatch;

class DependencyCallback
{
    public var moduleMatch:ConsoleModuleMatch;

    public var registerCallback:Function;

    public var unregisterCallback:Function;

    public function DependencyCallback(interestedModule:ConsoleModuleMatch, registerCallback:Function, unregisterCallback:Function):void
    {
        this.moduleMatch = interestedModule;
        this.registerCallback = registerCallback;
        this.unregisterCallback = unregisterCallback;
    }
	
	public function registered(module:IConsoleModule):void
	{
		if (registerCallback != null)
		{
			registerCallback(module);
		}
	}
	
	public function unregistered(module:IConsoleModule):void
	{
		if (unregisterCallback != null)
		{
			unregisterCallback(module);
		}
	}
}

import com.junkbyte.console.interfaces.IConsoleModule;
import com.junkbyte.console.vos.ConsoleModuleMatch;

class MatchedModule
{
	public var module:IConsoleModule;
	
	public var dependency:DependencyCallback;
	
	public function MatchedModule(module:IConsoleModule, dependency:DependencyCallback):void
	{
		this.module = module;
		this.dependency = dependency;
	}
	
	public function unregistered():void
	{
		dependency.unregistered(module);
	}
}