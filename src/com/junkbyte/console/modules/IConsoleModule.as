package com.junkbyte.console.modules {
	import com.junkbyte.console.Console;

	public interface IConsoleModule {
		
		function initializeUsingConsole(consle:Console):void;
		
		function getModuleName():String;
		
	}
}
