package com.junkbyte.console.interfaces
{
	import com.junkbyte.console.logging.LogEntry;

	public interface IConsoleLogProcessor
	{
		function process(input:*, currentOutput:String):String;
	}
}