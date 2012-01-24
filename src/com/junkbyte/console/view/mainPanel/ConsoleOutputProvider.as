package com.junkbyte.console.view.mainPanel
{
	public interface ConsoleOutputProvider
	{
				function getFullOutput():String;

		function getOutputFromBottom(lines:uint,maxChars:uint):String;

		function addUpdateCallback(callback:Function):void;

		function removeUpdateCallback(callback:Function):void;

	}
}