package com.junkbyte.console.core
{

	import com.junkbyte.console.modules.ConsoleModuleNames;
	
	import flash.events.Event;
	import flash.utils.getTimer;

	public class ConsoleTicker extends ConsoleModule
	{

		protected var lastTimer:Number;

		protected var dataDispatcher:CcCallbackDispatcher = new CcCallbackDispatcher();
		protected var viewDispatcher:CcCallbackDispatcher = new CcCallbackDispatcher();
		
		protected var deltaArray:Array = new Array(1);

		public function ConsoleTicker()
		{

		}
		
		override public function getModuleName():String
		{
			return ConsoleModuleNames.TICKER;
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
			dataDispatcher.apply(deltaArray);
			viewDispatcher.apply(deltaArray);
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
			dataDispatcher.add(callback);
		}

		public function removeUpdateDataCallback(callback:Function):void
		{
			dataDispatcher.remove(callback);
		}

		public function addUpdateViewCallback(callback:Function):void
		{
			viewDispatcher.add(callback);
		}

		public function removeUpdateViewCallback(callback:Function):void
		{
			viewDispatcher.remove(callback);
		}
	}
}
