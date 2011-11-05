package com.junkbyte.console.events
{
	import flash.events.Event;
	
	public class ConsolePanelEvent extends Event
	{
		
		public static const STARTED_MOVING:String = "startedMoving";
		public static const STOPPED_MOVING:String = "stoppedMoving";
		
		public static const STARTED_RESIZING:String = "startedScaling";
		public static const STOPPED_RESIZING:String = "stoppedScaling";
		
		public static const PANEL_RESIZED:String = "panelResized";
		
		public function ConsolePanelEvent(type:String)
		{
			super(type, false, false);
		}
		
		public static function create(type:String):ConsolePanelEvent
		{
			return new ConsolePanelEvent(type);
		}
	}
}