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
	import com.junkbyte.console.events.ConsoleModuleEvent;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.modules.commandLine.ICommandLine;
	import com.junkbyte.console.modules.commandLine.SlashCommandLine;
	import com.junkbyte.console.modules.referencing.ConsoleReferencingModule;
	import com.junkbyte.console.modules.remoting.IRemoter;
	import com.junkbyte.console.view.ConsoleLayer;
	import com.junkbyte.console.vos.ConsoleModuleMatch;

	import flash.events.EventDispatcher;

    [Event(name = "moduleRegistered", type = "com.junkbyte.console.events.ConsoleModuleEvent")]
    [Event(name = "moduleUnregistered", type = "com.junkbyte.console.events.ConsoleModuleEvent")]
    public class ConsoleModulesManager extends EventDispatcher
    {
        protected var _modules:Vector.<IConsoleModule> = new Vector.<IConsoleModule>();

        protected var _modulesByName:Object = new Object();

        protected var _console:Console;

        //
        private var _refs:ConsoleReferencingModule;

        private var _remoter:IRemoter;

        //
        private var _logs:Logs;

        public function ConsoleModulesManager(console:Console)
        {
            _console = console;

            super();
        }

        public function init():void
        {
            _logs = new Logs();
            registerModule(_logs);
            _refs = new ConsoleReferencingModule();
            registerModule(_refs);
            registerModule(new SlashCommandLine());
            registerModule(new KeyBinder());
        }

        //
        //
        public function report(obj:* = '', priority:int = 0, skipSafe:Boolean = true, channel:String = null):void
        {
            if (!channel)
                channel = display.mainPanel.traces.reportChannel;
            _logs.addLine([ obj ], priority, channel, false, skipSafe, 0);
        }

        //
        public function get console():Console
        {
            return _console;
        }

        public function get config():ConsoleConfig
        {
            return console.config;
        }

        public function get display():ConsoleLayer
        {
            return console.layer;
        }

        public function get cl():ICommandLine
        {
            return getModuleByName(ConsoleModuleNames.COMMAND_LINE) as ICommandLine;
        }

        public function get remoter():IRemoter
        {
            return _remoter;
        }
 
        public function get refs():ConsoleReferencingModule
        {
            return _refs;
        }

        public function get logs():Logs
        {
            return _logs;
        }

        public function getModuleByName(moduleName:String):IConsoleModule
        {
            return _modulesByName[moduleName];
        }

        public function findModuleByMatcher(matcher:ConsoleModuleMatch):IConsoleModule
        {
            var len:uint = _modules.length;
            for (var i:int = _modules.length - 1; i >= 0; i--)
            {
                if (matcher.matches(_modules[i]))
                {
                    return _modules[i];
                }
            }
            return null;
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
            if (!isModuleRegistered(module))
            {
                var moduleName:String = module.getModuleName();
                if (moduleName != null)
                {
                    var currentModule:IConsoleModule = _modulesByName[moduleName];
                    if (currentModule != null)
                    {
                        unregisterModule(currentModule);
                    }
                    _modulesByName[moduleName] = module;
                }
                _modules.push(module);
                module.setConsole(console);
                // this is incase module unregister it self straight away
                if (isModuleRegistered(module))
                {
                    dispatchEvent(new ConsoleModuleEvent(ConsoleModuleEvent.MODULE_REGISTERED, module));
                }
            }
        }

        public function isModuleRegistered(module:IConsoleModule):Boolean
        {
            return _modules.indexOf(module) >= 0;
        }

        public function unregisterModule(module:IConsoleModule):void
        {
            var index:int = _modules.indexOf(module);
            if (index >= 0)
            {
                var moduleName:String = module.getModuleName();
                if (moduleName != null)
                {
                    if (_modulesByName[moduleName] == module)
                    {
                        delete _modulesByName[moduleName];
                    }
                }
                _modules.splice(index, 1);
                module.setConsole(null);
                dispatchEvent(new ConsoleModuleEvent(ConsoleModuleEvent.MODULE_UNREGISTERED, module));
            }
        }

    }
}