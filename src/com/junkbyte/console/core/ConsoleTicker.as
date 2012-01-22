package com.junkbyte.console.core
{

	import flash.events.Event;
	import flash.utils.getTimer;
	import com.junkbyte.console.interfaces.ConsoleDataUpdatedListener;
	import com.junkbyte.console.interfaces.ConsoleUpdateDataListener;

	public class ConsoleTicker extends ConsoleModule
	{

		protected var _lastTimer:Number;

		private var updateDispatcher:CallbackDispatcher = new CallbackDispatcher();
		private var updatedDispatcher:CallbackDispatcher = new CallbackDispatcher();

		public function ConsoleTicker()
		{

		}

		override protected function registeredToConsole():void
		{
			super.registeredToConsole();
			layer.addEventListener(Event.ENTER_FRAME, onLayerEnterFrame);
		}

		override protected function unregisteredFromConsole():void
		{
			layer.removeEventListener(Event.ENTER_FRAME, onLayerEnterFrame);
			super.unregisteredFromConsole();
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
			for each (var listener:ConsoleUpdateDataListener in updateDispatcher.list)
			{
				listener.onUpdateData(msDelta);
			}
		}

		public function addUpdateDataListener(listener:ConsoleUpdateDataListener):void
		{
			updateDispatcher.add(listener);
		}

		public function removeUpdateDataListener(listener:ConsoleUpdateDataListener):void
		{
			updateDispatcher.remove(listener);
		}

		protected function announceDataUpdated(msDelta:uint):void
		{
			for each (var listener:ConsoleDataUpdatedListener in updatedDispatcher.list)
			{
				listener.onDataUpdated(msDelta);
			}
		}

		public function addDataUpdatedListener(listener:ConsoleDataUpdatedListener):void
		{
			updateDispatcher.add(listener);
		}

		public function removeDataUpdatedListener(listener:ConsoleDataUpdatedListener):void
		{
			updateDispatcher.remove(listener);
		}
	}
}
