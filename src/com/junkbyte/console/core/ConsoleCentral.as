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
	import flash.system.System;
	import com.junkbyte.console.Console;
	import com.junkbyte.console.ConsoleConfig;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.modules.displayRoller.DisplayRollerModule;
	import com.junkbyte.console.modules.ruler.RulerModule;
	import com.junkbyte.console.view.ConsoleLayer;
	import com.junkbyte.console.view.MainPanelMenu;

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.SharedObject;
	/**
	 * Console is the main class. 
	 * Please see com.junkbyte.console.Cc for documentation as it shares the same properties and methods structure.
	 * @see http://code.google.com/p/flash-console/
	 * @see com.junkbyte.console.Cc
	 */
	public class ConsoleCentral extends EventDispatcher{
		
		
		
		public static const PAUSED:String = "pause";
		
		protected var _modulesByName:Object = new Object();
		
		//
		private var _console:Console;
		private var _config:ConsoleConfig;
		private var _panels:ConsoleLayer;
		private var _refs:LogReferences;
		private var _remoter:Remoting;
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
			
			_remoter = new Remoting(this);
			_logs = new Logs(this);
			_refs = new LogReferences(this);
			registerModule(new CommandLine());
			_tools =  new ConsoleTools(this);
			registerModule(new Graphing());
			
			cl.addCLCmd("remotingSocket", function(str:String = ""):void{
				var args:Array = str.split(/\s+|\:/);
				console.remotingSocket(args[0], args[1]);
			}, "Connect to socket remote. /remotingSocket ip port");
			
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
		
		public function initBaseModules():void
		{
			registerModule(new KeyBinder());
			registerModule(new KeyStates());
			registerModule(new RulerModule());
			registerModule(new DisplayRollerModule());
		}
		
		public function getModuleByName(moduleName:String):IConsoleModule
		{
			return _modulesByName[moduleName];
		}
		
		public function registerModule(module:IConsoleModule):void
		{
			var moduleName:String = module.getModuleName();
			
			var currentModule:IConsoleModule = _modulesByName[moduleName];
			if(currentModule != module)
			{
				if(currentModule != null)
				{
					currentModule.unregisterConsole(console);
				}
				_modulesByName[moduleName] = module;
				module.registerConsole(console);
			}
		}
		
		public function unregisterModule(module:IConsoleModule):void
		{
			var moduleName:String = module.getModuleName();
			if(_modulesByName[moduleName] == module)
			{
				delete _modulesByName[moduleName];
				module.unregisterConsole(console);
			}
		}
		//
		//
		//
		public function update(msDelta:uint = 0):void{
			dispatchEvent(ConsoleEvent.create(ConsoleEvent.MODEL_UPDATE));
			var hasNewLog:Boolean = _logs.update();
			_refs.update(msDelta);
			var graphsList:Array;
			if(remoter.remoting != Remoting.RECIEVER)
			{
			 	graphsList = graphing.update(_panels.stage?_panels.stage.frameRate:0);
			}
			_remoter.update();
			dispatchEvent(ConsoleEvent.create(ConsoleEvent.MODEL_UPDATED));
			
			dispatchEvent(ConsoleEvent.create(ConsoleEvent.VIEW_UPDATE));
			_panels.update(paused, hasNewLog);
			if(graphsList) _panels.updateGraphs(graphsList);
			dispatchEvent(ConsoleEvent.create(ConsoleEvent.VIEW_UPDATED));
		}
		
		public function gc():void {
			if(remoter.remoting == Remoting.RECIEVER){
				try{
					//report("Sending garbage collection request to client",-1);
					remoter.send("gc");
				}catch(e:Error){
					report(e,10);
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
				report(str,(ok?-1:10));
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
			if(newV) report("Paused", 10);
			else report("Resumed", -1);
			_paused = newV;
			panels.mainPanel.setPaused(newV);
			dispatchEvent(new Event(ConsoleCentral.PAUSED));
		}
		//
		//
		public function report(obj:*, priority:int = 0, skipSafe:Boolean = true, channel:String = null):void{
			if(!channel) channel = panels.mainPanel.reportChannel;
			console.addLine([obj], priority, channel, false, skipSafe, 0);
		}
		//
		public function get console():Console{return _console;}
		public function get config():ConsoleConfig{return _config;}
		public function get panels():ConsoleLayer{return _panels;}
		
		public function get keyBinder():KeyBinder{return getModuleByName(KeyBinder.NAME) as KeyBinder;}
		public function get keyStates():KeyStates{return getModuleByName(KeyStates.NAME) as KeyStates;}
		public function get mainPanelMenu():MainPanelMenu{return getModuleByName(MainPanelMenu.NAME) as MainPanelMenu;}
		
		public function get cl():CommandLine{return getModuleByName(CommandLine.NAME) as CommandLine;}
		
		public function get remoter():Remoting{return _remoter;}
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