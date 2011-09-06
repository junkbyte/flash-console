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
	import com.junkbyte.console.ConsoleLevel;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.events.ConsoleModuleEvent;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.modules.UnCaughtErrorsListenerModule;
	import com.junkbyte.console.modules.displayRoller.DisplayRollerModule;
	import com.junkbyte.console.modules.remoting.IRemoter;
	import com.junkbyte.console.modules.ruler.RulerModule;
	import com.junkbyte.console.view.ConsoleLayer;
	import com.junkbyte.console.view.MainPanelMenu;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.SharedObject;
	import flash.system.System;
	
	[Event(name="moduleAdded", type="com.junkbyte.console.events.ConsoleModuleEvent")]
	[Event(name="moduleRemoved", type="com.junkbyte.console.events.ConsoleModuleEvent")]
	
	public class ConsoleCentral extends EventDispatcher{
		
		public static const PAUSED:String = "pause";
		
		protected var _modules:Vector.<IConsoleModule> = new Vector.<IConsoleModule>();
		protected var _modulesByName:Object = new Object();
		protected var _moduleInterestCallbacks:Vector.<ModuleInterestCallback> = new Vector.<ModuleInterestCallback>();
		//
		private var _console:Console;
		private var _config:ConsoleConfig;
		private var _panels:ConsoleLayer;
		private var _refs:LogReferences;
		private var _remoter:IRemoter;
		private var _tools:ConsoleTools;
		//
		private var _logs:Logs;
		private var _paused:Boolean;
		
		private var _so:SharedObject;
		private var _soData:Object = {};
		
		/**
		 * Console is the main class. However please use Cc for singleton Console adapter.
		 * Using Console through Cc will also make sure you can remove console in a later date
		 * by simply removing Cc.start() or Cc.startOnStage()
	 	 * See com.junkbyte.console.Cc for documentation as it shares the same properties and methods structure.
		 * 
		 * @see com.junkbyte.console.Cc
		 * @see http://code.google.com/p/flash-console/
		 */
		public function ConsoleCentral(console:Console, config:ConsoleConfig = null) {
			_console = console;
			if(config == null) config = new ConsoleConfig();
			_config = config;
		}
		
		public function init():void
		{
			_config.style.updateStyleSheet();
			_panels = new ConsoleLayer(this);
			
			_remoter = new Remoting();
			registerModule(_remoter as IConsoleModule);
			_logs = new Logs();
			registerModule(_logs);
			_refs = new LogReferences(this);
			registerModule(new CommandLine());
			_tools =  new ConsoleTools(this);
			registerModule(new Graphing());
			
			/*
			cl.addCLCmd("remotingSocket", function(str:String = ""):void{
				var args:Array = str.split(/\s+|\:/);
				console.remotingSocket(args[0], args[1]);
			}, "Connect to socket remote. /remotingSocket ip port");
			*/
			
			if(_config.sharedObjectName){
				try{
					_so = SharedObject.getLocal(_config.sharedObjectName, _config.sharedObjectPath);
					_soData = _so.data;
				}catch(e:Error){
					
				}
			}
			if(config.keystrokePassword) _panels.visible = false;
			_panels.start();

			
			initBaseModules();
			
			//_central.remoter.registerCallback("gc", gc);
			
		}
		
		protected function initBaseModules():void
		{
			registerModule(new KeyBinder());
			registerModule(new KeyStates());
			registerModule(new RulerModule());
			registerModule(new DisplayRollerModule());
			registerModule(new UnCaughtErrorsListenerModule());
		}
		
		public function getModuleByName(moduleName:String):IConsoleModule
		{
			return _modulesByName[moduleName];
		}
		
		public function findModuleByClass(moduleClass:Class):IConsoleModule
		{
			var len:uint = _modules.length;
			for (var i:int = _modules.length-1; i>=0; i--)
			{
				if(_modules[i] is moduleClass)
				{
					return _modules[i];
				}
			}
			return null;
		}
		
		public function registerModule(module:IConsoleModule):void
		{
			if(!isModuleRegistered(module))
			{
				var moduleName:String = module.getModuleName();
				if(moduleName != null)
				{
					var currentModule:IConsoleModule = _modulesByName[moduleName];
					if(currentModule != null)
					{
						unregisterModule(currentModule);
					}
					_modulesByName[moduleName] = module;
				}
				_modules.push(module);
				module.registeredToConsole(console);
				callModuleCallbacks(module, true);
				dispatchEvent(new ConsoleModuleEvent(ConsoleModuleEvent.MODULE_REGISTERED, module));
			}
		}
		
		public function isModuleRegistered(module:IConsoleModule):Boolean
		{
			return _modules.indexOf(module) >= 0;
		}
		
		public function unregisterModule(module:IConsoleModule):void
		{
			var index:int = _modules.indexOf(module);
			if(index >= 0)
			{
				var moduleName:String = module.getModuleName();
				if(moduleName != null)
				{
					if(_modulesByName[moduleName] == module)
					{
						delete _modulesByName[moduleName];
					}
				}
				_modules.splice(index, 1);
				removeModuleCallbacksAddedByModule(module);
				module.unregisteredFromConsole(console);
				callModuleCallbacks(module, false);
				dispatchEvent(new ConsoleModuleEvent(ConsoleModuleEvent.MODULE_UNREGISTERED, module));
			}
		}
		
		public function addModuleInterestCallback(interestedModuleName:String, callbackModule:IConsoleModule, callOnSelfUnregiser:Boolean = true):void
		{
			var cb:ModuleInterestCallback = new ModuleInterestCallback(interestedModuleName, callbackModule, callOnSelfUnregiser);
			_moduleInterestCallbacks.push(cb);
			
			var interestedModule:IConsoleModule = getModuleByName(interestedModuleName);
			if(interestedModule != null)
			{
				callbackModule.interestModuleRegistered(interestedModule);
			}
		}
		
		protected function callModuleCallbacks(module:IConsoleModule, isRegistered:Boolean):void
		{
			var moduleName:String = module.getModuleName();
			for (var i:int = _moduleInterestCallbacks.length-1; i>=0; i--)
			{
				var cb:ModuleInterestCallback = _moduleInterestCallbacks[i];
				if(cb.interestedModuleName == moduleName)
				{
					if(isRegistered)
					{
						cb.callbackModule.interestModuleRegistered(module);
					}
					else
					{
						cb.callbackModule.interestModuleUnregistered(module);
					}
				}
			}
		}
		
		
		protected function removeModuleCallbacksAddedByModule(module:IConsoleModule):void
		{
			var moduleName:String = module.getModuleName();
			for (var i:int = _moduleInterestCallbacks.length-1; i>=0; i--)
			{
				var cb:ModuleInterestCallback = _moduleInterestCallbacks[i];
				if(cb.callbackModule == module)
				{
					_moduleInterestCallbacks.splice(i, 1);
					if(cb.callOnSelfUnregiser)
					{
						var interestedModule:IConsoleModule = getModuleByName(cb.interestedModuleName);
						if(interestedModule != null)
						{
							cb.callbackModule.interestModuleUnregistered(module);
						}
					}
				}
			}
		}
		//
		//
		//
		public function update(msDelta:uint = 0):void{
			dispatchEvent(ConsoleEvent.create(ConsoleEvent.UPDATE));
			var hasNewLog:Boolean = _logs.update();
			_refs.update(msDelta);
			var graphsList:Array;
			if(remoter.isSender)
			{
			 	graphsList = graphing.update(_panels.stage?_panels.stage.frameRate:0);
			}
			
			dispatchEvent(ConsoleEvent.create(ConsoleEvent.UPDATED));
			
			_panels.update(paused, hasNewLog);
			if(graphsList) _panels.updateGraphs(graphsList);
			
		}
		
		public function gc():void {
			if(!remoter.isSender){
				try{
					//report("Sending garbage collection request to client",-1);
					remoter.send("gc");
				}catch(e:Error){
					report(e, ConsoleLevel.ERROR);
				}
			}else{
				var ok:Boolean;
				try{
					// have to put in brackes cause some compilers will complain.
					if(System["gc"] != null){
						System["gc"]();
						ok = true;
					}
				}catch(e:Error){ }
				
				var str:String = "Manual garbage collection "+(ok?"successful.":"FAILED. You need debugger version of flash player.");
				report(str,(ok?ConsoleLevel.CONSOLE_STATUS:ConsoleLevel.ERROR));
			}
		}
		//
		// Panel settings
		// basically passing through to panels manager to save lines
		//
		//
		//
		//
		public function get paused():Boolean{
			return _paused;
		}
		public function set paused(newV:Boolean):void{
			if(_paused == newV) return;
			if(newV) report("Paused", ConsoleLevel.ERROR);
			else report("Resumed", ConsoleLevel.CONSOLE_STATUS);
			_paused = newV;
			display.mainPanel.setPaused(newV);
			dispatchEvent(new Event(ConsoleCentral.PAUSED));
		}
		//
		//
		public function report(obj:*, priority:int = 0, skipSafe:Boolean = true, channel:String = null):void{
			if(!channel) channel = display.mainPanel.reportChannel;
			console.addLine([obj], priority, channel, false, skipSafe, 0);
		}
		//
		public function get console():Console{return _console;}
		public function get config():ConsoleConfig{return _config;}
		public function get display():ConsoleLayer{return _panels;}
		
		public function get mainPanelMenu():MainPanelMenu{return getModuleByName(MainPanelMenu.NAME) as MainPanelMenu;}
		
		public function get cl():CommandLine{return getModuleByName(CommandLine.NAME) as CommandLine;}
		
		public function get remoter():IRemoter{return _remoter;}
		public function get graphing():Graphing{return getModuleByName(Graphing.NAME) as Graphing;}
		public function get refs():LogReferences{return _refs;}
		public function get logs():Logs{return _logs;}
		public function get tools():ConsoleTools{return _tools;}
		
		public function get so():Object{return _soData;}
		public function updateSO(key:String = null):void{
			if(_so) {
				if(key) _so.setDirty(key);
				else _so.clear();
			}
		}
		//
		//
		//
		public static function MakeChannelName(obj:*):String{
			if(obj is String) return obj as String;
			else if(obj) return LogReferences.ShortClassName(obj);
			return Logs.DEFAULT_CHANNEL;
		}
	}
}