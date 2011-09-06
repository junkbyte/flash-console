package com.junkbyte.console.core
{
	import com.junkbyte.console.interfaces.IConsoleModule;

	public class ModuleRegisteryCallback
	{
		public var interestedModuleName:String;
		public var callbackModule:IConsoleModule;
		public var callOnSelfUnregiser:Boolean;
		
		public function ModuleRegisteryCallback(interestedModuleName:String, callbackModule:IConsoleModule, callOnSelfUnregiser:Boolean):void
		{
			this.interestedModuleName = interestedModuleName;
			this.callbackModule = callbackModule;
			this.callOnSelfUnregiser = callOnSelfUnregiser;
		}
	}
}