package com.junkbyte.console.modules.graphing
{
	import flash.events.Event;

	public class GraphingGroupEvent extends Event
	{

		public static const META_CHANGE:String = "metaChange";
		public static const PUSH:String = "push";

		public var values:Vector.<Number>;

		public function GraphingGroupEvent(type:String)
		{
			super(type, false, false);
		}

		public override function clone():Event
		{
			var event:GraphingGroupEvent = new GraphingGroupEvent(type);
			event.values = values;
			return event;
		}

		public override function toString():String
		{
			return formatToString("GraphingGroupEvent");
		}
	}
}
