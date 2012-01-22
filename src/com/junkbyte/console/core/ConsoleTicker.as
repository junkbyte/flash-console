package com.junkbyte.console.core
{

	import flash.events.Event;
	import flash.utils.getTimer;

	public class ConsoleTicker extends ConsoleModule
	{

		protected var lastTimer:Number;

		protected var updateDispatcher:CallbackDispatcher = new CallbackDispatcher();
		protected var updatedDispatcher:CallbackDispatcher = new CallbackDispatcher();
		
		protected var deltaArray:Array = new Array(1);

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
			deltaArray[0] = updateTime();
			updateDispatcher.apply(deltaArray);
			updatedDispatcher.apply(deltaArray);
		}

		protected function updateTime():uint
		{
			var timeNow:Number = getTimer();
			var msDelta:uint = timeNow - lastTimer;
			lastTimer = timeNow;
			return msDelta;
		}

		public function addUpdateDataCallback(callback:Function):void
		{
			updateDispatcher.add(callback);
		}

		public function removeUpdateDataCallback(callback:Function):void
		{
			updateDispatcher.remove(callback);
		}

		public function addDataUpdatedCallback(callback:Function):void
		{
			updateDispatcher.add(callback);
		}

		public function removeDataUpdatedCallback(callback:Function):void
		{
			updateDispatcher.remove(callback);
		}
	}
}
