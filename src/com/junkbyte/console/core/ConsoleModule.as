/*
*
* Copyright (c) 2008-2010 Lu Aye Oo
*
* @author 		Lu Aye Oo
*
* http://code.google.com/p/flash-console/
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
    import com.junkbyte.console.ConsoleConfig;
    import com.junkbyte.console.ConsoleStyle;
    import com.junkbyte.console.events.ConsoleModuleEvent;
    import com.junkbyte.console.interfaces.IConsoleModule;
    import com.junkbyte.console.interfaces.IRemoter;
    import com.junkbyte.console.logging.ConsoleLogger;
    import com.junkbyte.console.view.ConsoleLayer;
    
    import flash.events.EventDispatcher;

    [Event(name = "registeredToConsole", type = "com.junkbyte.console.events.ConsoleModuleEvent")]
    [Event(name = "unregisteredToConsole", type = "com.junkbyte.console.events.ConsoleModuleEvent")]
    public class ConsoleModule extends EventDispatcher implements IConsoleModule
    {
        protected var _console:Console;
		
		protected var _moduleDependences:ModuleRegisteryWatcher;

        public function ConsoleModule()
        {
			
        }

        public function getModuleName():String
        {
            return null;
        }

        public function setConsole(newConsole:Console):void
        {
			if(newConsole == _console)
			{
				return;
			}
            if (_console != null)
            {
				unregisteredFromConsole();
            }
			_console = newConsole;
            if (newConsole != null)
            {
				registeredToConsole();
            }
        }
		
		protected function addModuleRegisteryCallback(matcher:ModuleTypeMatcher, registerCallback:Function, unregisterCallback:Function = null):void
		{
			if(_moduleDependences == null)
			{
				_moduleDependences = ModuleRegisteryWatcher.createUsingModule(this);
			}
			_moduleDependences.addCallback(matcher, registerCallback, unregisterCallback);
		}

        protected function registeredToConsole():void
        {
            dispatchEvent(new ConsoleModuleEvent(ConsoleModuleEvent.REGISTERED_TO_CONSOLE, this));
        }

        protected function unregisteredFromConsole():void
        {
            dispatchEvent(new ConsoleModuleEvent(ConsoleModuleEvent.UNREGISTERED_FROM_CONSOLE, this));
        }
		
		public function isRegisteredToConsole():Boolean
		{
			return _console != null;
		}

        public function get console():Console
        {
            return _console;
        }

		public function get modules():ConsoleModulesManager
		{
			return console.modules;
		}
		
		public function get logger():ConsoleLogger
		{
			return console.logger;
		}

        public function get config():ConsoleConfig
        {
            return console.config;
        }

		public function get style():ConsoleStyle
		{
			return config.style;
		}

        public function get layer():ConsoleLayer
        {
            return console.layer;
        }

        public function report(obj:* = "", priority:int = 0, skipSafe:Boolean = true, ch:String = null):void
        {
            logger.report(obj, priority, skipSafe, ch);
        }
    }
}
