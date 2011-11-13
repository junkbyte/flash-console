package com.junkbyte.console.core
{

	import com.junkbyte.console.Console;
	import com.junkbyte.console.events.ConsoleEvent;
	
	import flash.events.Event;
	import flash.utils.getTimer;

	public class ConsoleTicker
	{

		protected var _lastTimer:Number;

		protected var _console:Console;

		public function ConsoleTicker(console:Console)
		{
			_console = console;
			_console.layer.addEventListener(Event.ENTER_FRAME, onLayerEnterFrame);
		}

		protected function onLayerEnterFrame(e:Event):void
		{
			var msDelta:uint = updateTime();
			announceUpdateData(msDelta);
			announceDataUpdated(msDelta);
		}

		protected function updateTime():uint
		{
			var timeNow:Number = getTimer();
			var msDelta:uint = timeNow - _lastTimer;
			_lastTimer = timeNow;
			return msDelta;
		}

		protected function announceUpdateData(msDelta:uint):void
		{
			var event:ConsoleEvent = ConsoleEvent.create(ConsoleEvent.UPDATE_DATA);
			event.msDelta = msDelta;
			_console.dispatchEvent(event);
		}

		protected function announceDataUpdated(msDelta:uint):void
		{
			var event:ConsoleEvent = ConsoleEvent.create(ConsoleEvent.DATA_UPDATED);
			event.msDelta = msDelta;
			_console.dispatchEvent(event);
		}
	}
}
