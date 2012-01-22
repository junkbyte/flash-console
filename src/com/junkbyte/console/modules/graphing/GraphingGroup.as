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
		private var pushDeltaArray:Array = new Array(2);

		public function GraphingGroup()
		{
			pushDeltaArray[0] = this;
		}

		public function push(values:Vector.<Number>):void
		{
			pushDeltaArray[1] = values;
			pushDispatcher.apply(pushDeltaArray);
		}

		public function addPushCallback(callback:Function):void
		{
			pushDispatcher.add(callback);
		}

		public function removePushCallback(callback:Function):void
		{
			pushDispatcher.remove(callback);
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
