package com.junkbyte.console.events {
	import flash.events.Event;
	/**
	 * @author LuAye
	 */
	public class ConsoleEvent extends Event
	{
		
		public static const STARTED:String = "started";
		
		public static const SHOWN:String = "shown";
		public static const HIDDEN:String = "hidden";
		
		public static const PAUSED:String = "paused";
		public static const RESUMED:String = "resumed";
		
		public static const UPDATE_DATA:String = "updateData";
		public static const DATA_UPDATED:String = "dataUpdated";
		
		public static const UPDATE_DISPLAY:String = "updateDisplay";
		
		public var msDelta:uint;
		
		public function ConsoleEvent(type:String)
		{
            super(type, false, false);
		}
		
		public static function create(type:String):ConsoleEvent
		{
			return new ConsoleEvent(type);
		}
	}
}
