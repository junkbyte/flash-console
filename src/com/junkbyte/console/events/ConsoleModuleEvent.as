package com.junkbyte.console.events {
	import com.junkbyte.console.interfaces.IConsoleModule;

	import flash.events.Event;

	public class ConsoleModuleEvent extends Event {
		
		public static const MODULE_REGISTERED:String = "moduleRegistered";
		public static const MODULE_UNREGISTERED:String = "moduleUnregistered";
		
		public var module:IConsoleModule;
		
		public function ConsoleModuleEvent(type : String, module:IConsoleModule) {
			super(type, false, false);
			this.module = module;
		}
	}
}
