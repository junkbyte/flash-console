package com.junkbyte.console.core
{
	import com.junkbyte.console.interfaces.IConsoleModule;

	public class ModuleInterestCallback
	{
		public var interestedModuleName:String;
		public var callbackModule:IConsoleModule;
		public var callOnSelfUnregiser:Boolean;
		
		public function ModuleInterestCallback(interestedModuleName:String, callbackModule:IConsoleModule, callOnSelfUnregiser:Boolean):void
		{
			this.interestedModuleName = interestedModuleName;
			this.callbackModule = callbackModule;
			this.callOnSelfUnregiser = callOnSelfUnregiser;
		}
	}
}