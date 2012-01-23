package com.junkbyte.console.modules.graphing
{
	import flash.events.Event;

	public class GraphingEvent extends Event
	{

		public static const ADD_GROUP:String = "addGroup";

		public var group:GraphingGroup;

		public function GraphingEvent(type:String)
		{
			super(type, false, false);
		}

		public override function clone():Event
		{
			var event:GraphingEvent = new GraphingEvent(type);
			event.group = group;
			return event;
		}

		public override function toString():String
		{
			return formatToString("GraphingEvent");
		}
	}
}
