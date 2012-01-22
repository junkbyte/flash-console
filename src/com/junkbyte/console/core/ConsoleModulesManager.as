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

	import com.junkbyte.console.Console;
	import com.junkbyte.console.events.ConsoleModuleEvent;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.interfaces.IConsoleModuleMatcher;
	
	import flash.events.EventDispatcher;

	[Event(name = "moduleRegistered", type = "com.junkbyte.console.events.ConsoleModuleEvent")]
	[Event(name = "moduleUnregistered", type = "com.junkbyte.console.events.ConsoleModuleEvent")]
	public class ConsoleModulesManager extends EventDispatcher
	{
		protected var _modules:Vector.<IConsoleModule> = new Vector.<IConsoleModule>();

		protected var _modulesByName:Object = new Object();

		protected var _console:Console;

		public function ConsoleModulesManager(console:Console)
		{
			_console = console;

			super();
		}

		public function getAllModules():Vector.<IConsoleModule>
		{
			return _modules.concat();
		}

		public function getModuleByName(moduleName:String):IConsoleModule
		{
			return _modulesByName[moduleName];
		}

		public function findModulesByMatcher(matcher:IConsoleModuleMatcher):Vector.<IConsoleModule>
		{
			var result:Vector.<IConsoleModule> = new Vector.<IConsoleModule>();

			var len:uint = _modules.length;
			for (var i:int = 0; i < len; i++)
			{
				var module:IConsoleModule = _modules[i];
				if (matcher.matches(module))
				{
					result.push(module);
				}
			}

			return result;
		}

		public function getFirstMatchingModule(matcher:IConsoleModuleMatcher):IConsoleModule
		{
			var result:Vector.<IConsoleModule> = findModulesByMatcher(matcher);
			return result.length > 0 ? result[0] : null;
		}
		
		public function findFirstModuleByClass(modClass:Class):IConsoleModule
		{
			return getFirstMatchingModule(new ModuleTypeMatcher(modClass));
		}

		public function isModuleRegistered(module:IConsoleModule):Boolean
		{
			return _modules.indexOf(module) >= 0;
		}

		public function registerModules(modules:Vector.<IConsoleModule>):void
		{
			for (var i:int = 0; i < modules.length; i++)
			{
				var module:IConsoleModule = modules[i];
				if (module != null)
				{
					registerModule(module);
				}
			}
		}

		public function registerModule(module:IConsoleModule):void
		{
			if (isModuleRegistered(module))
			{
				return;
			}
			registerNamedModule(module);
			_modules.push(module);
			module.setConsole(_console);
			// this is incase module unregister it self straight away
			if (isModuleRegistered(module))
			{
				dispatchEvent(new ConsoleModuleEvent(ConsoleModuleEvent.MODULE_REGISTERED, module));
			}
		}

		protected function registerNamedModule(module:IConsoleModule):void
		{
			var moduleName:String = module.getModuleName();
			if (moduleName != null)
			{
				validateNamedModule(module, moduleName);
				var currentModule:IConsoleModule = _modulesByName[moduleName];
				if (currentModule != null)
				{
					unregisterModule(currentModule);
				}
				_modulesByName[moduleName] = module;
			}
		}

		protected function validateNamedModule(module:IConsoleModule, name:String):void
		{
			if (ConsoleCoreModulesMap.isModuleWithNameValid(module, name) == false)
			{
				throw new ArgumentError();
			}
		}

		public function unregisterModule(module:IConsoleModule):void
		{
			var index:int = _modules.indexOf(module);
			if (index >= 0)
			{
				unregisterNamedModule(module);
				_modules.splice(index, 1);
				module.setConsole(null);
				dispatchEvent(new ConsoleModuleEvent(ConsoleModuleEvent.MODULE_UNREGISTERED, module));
			}
		}

		protected function unregisterNamedModule(module:IConsoleModule):void
		{
			var moduleName:String = module.getModuleName();
			if (moduleName != null)
			{
				if (_modulesByName[moduleName] == module)
				{
					delete _modulesByName[moduleName];
				}
			}
		}
	}
}
