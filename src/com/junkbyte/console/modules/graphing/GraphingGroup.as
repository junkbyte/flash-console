package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.core.CallbackDispatcher;
	import com.junkbyte.console.view.ConsolePanel;

	import flash.events.Event;
	import flash.events.EventDispatcher;

	[Event(name = "close", type = "flash.events.Event")]
	public class GraphingGroup extends EventDispatcher
	{

		public static var defaultGraphingPanelModuleClass:Class = GraphingPanelModule;

		public var updateFrequencyMS:uint = 5;

		public var fixedMin:Number;
		public var fixedMax:Number;

		public var inverted:Boolean;

		public var lines:Vector.<GraphingLine> = new Vector.<GraphingLine>();

		private var pushDispatcher:CallbackDispatcher = new CallbackDispatcher();

		public function GraphingGroup()
		{
		}

		public function push(values:Vector.<Number>):void
		{
			for each (var listener:GraphingGroupListener in pushDispatcher.list)
			{
				listener.push(this, values);
			}
		}

		public function addPushCallback(listener:GraphingGroupListener):void
		{
			pushDispatcher.add(listener);
		}

		public function removePushCallback(listener:GraphingGroupListener):void
		{
			pushDispatcher.remove(listener);
		}

		public function createPanel():ConsolePanel
		{
			return new defaultGraphingPanelModuleClass(this);
		}

		public function close():void
		{
			dispatchEvent(new Event(Event.CLOSE));
		}
	}
}
