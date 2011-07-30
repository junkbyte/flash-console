package com.junkbyte.console.interfaces {
	import flash.events.IEventDispatcher;
	[Event(name="change", type="flash.events.Event")]
	public interface IConsoleMenuItem extends IEventDispatcher{
		
		function isVisible():Boolean;
		
		function getName():String;
		
		function onClick():void;
		
		function isActive():Boolean; // return true if you want it to be on active state (bold text)
		
		function getSortPriority():int;
		
		function getTooltip():String;
	}
}