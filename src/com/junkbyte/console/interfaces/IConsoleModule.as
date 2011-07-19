package com.junkbyte.console.interfaces {
	import com.junkbyte.console.Console;

	public interface IConsoleModule {
		
		function initializeUsingConsole(console:Console):void;
		
		function getModuleName():String;
		
	}
}
