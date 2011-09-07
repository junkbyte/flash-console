package com.junkbyte.console.modules.keyStates
{
	public interface IKeyStates
	{
		
		function get altKeyDown():Boolean;
		
		function get ctrlKeyDown():Boolean;
		
		function get shiftKeyDown():Boolean;
		
		function isKeyCodeDown(keyCode:uint):Boolean;
		
	}
}