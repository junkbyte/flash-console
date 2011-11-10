/*
*
* Copyright (c) 2008-2011 Lu Aye Oo
*
* @author 		Lu Aye Oo
*
* http://code.google.com/p/flash-console/
* http://junkbyte.com
*
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
*
*/
package com.junkbyte.console.core
{
    import com.junkbyte.console.events.ConsoleModuleEvent;
    import com.junkbyte.console.interfaces.IConsoleModule;

    public class ModuleRegisteryWatcher
    {
		protected var modulesManager:ConsoleModulesManager;
		
        protected var dependencies:Vector.<DependencyCallback> = new Vector.<DependencyCallback>();

		protected var matchedModules:Vector.<MatchedModule> = new Vector.<MatchedModule>;
		
		public static function createUsingModule(module:ConsoleModule):ModuleRegisteryWatcher
		{
			var instance:ModuleRegisteryWatcher = new ModuleRegisteryWatcher();
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
			unregisterFromModulesManager();
			
			while(matchedModules.length)
			{
				var matched:MatchedModule = matchedModules[0];
				matchUnRegistered(matched);
			}
		}
		
		public static function createUsingModulesManager(modulesManager:ConsoleModulesManager):ModuleRegisteryWatcher
		{
			var instance:ModuleRegisteryWatcher = new ModuleRegisteryWatcher();
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

        public function addCallback(matcher:ModuleTypeMatcher, registerCallback:Function, unregisterCallback:Function = null):void
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
		
		public function unregisterFromModulesManager():void
		{
			if(modulesManager != null)
			{
				modulesManager.removeEventListener(ConsoleModuleEvent.MODULE_REGISTERED, onAnyModuleRegistered);
			}
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
import com.junkbyte.console.core.ModuleTypeMatcher;

class DependencyCallback
{
    public var moduleMatch:ModuleTypeMatcher;

    public var registerCallback:Function;

    public var unregisterCallback:Function;

    public function DependencyCallback(interestedModule:ModuleTypeMatcher, registerCallback:Function, unregisterCallback:Function):void
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
import com.junkbyte.console.core.ModuleTypeMatcher;

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