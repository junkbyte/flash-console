package com.junkbyte.console.modules.unCaughtErrorsListenerModule
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.ConsoleLevel;
	import com.junkbyte.console.core.ConsoleModule;

	import flash.display.LoaderInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IEventDispatcher;

	public class UnCaughtErrorsListenerModule extends ConsoleModule
	{
		public function UnCaughtErrorsListenerModule()
		{
		}
		
		override protected function registeredToConsole():void
		{
			super.registeredToConsole();
			if(console.layer.parent != null)
			{
				onConsoleAddedToDisplay();
			}
			else
			{
				console.layer.addEventListener(Event.ADDED, onConsoleAddedToDisplay, false, 0, true);
			}
		}
		
		protected function onConsoleAddedToDisplay(e:Event = null):void
		{
			console.layer.removeEventListener(Event.ADDED, onConsoleAddedToDisplay);
			if(console.layer.loaderInfo != null)
			{
				listen(console.layer.loaderInfo);
			}
		}
		
		// requires flash player target to be 10.1
		public function listen(loaderinfo:LoaderInfo):void {
			try{
				var uncaughtErrorEvents:IEventDispatcher = loaderinfo["uncaughtErrorEvents"];
				if(uncaughtErrorEvents){
					uncaughtErrorEvents.addEventListener("uncaughtError", uncaughtErrorHandle, false, 0, true);
				}
			}catch(err:Error){
				// seems uncaughtErrorEvents is not avaviable on this player/target, which is fine.
			}
		}
		
		protected function uncaughtErrorHandle(e:Event):void{
			var error:* = e.hasOwnProperty("error")?e["error"]:e; // for flash 9 compatibility
			var str:String;
			if (error is Error){
				str = console.logger.makeString(error);
			}else if (error is ErrorEvent){
				str = ErrorEvent(error).text;
			}
			if(!str){
				str = String(error);
			}
			logger.report("Uncaught Error:"+str, ConsoleLevel.FATAL, false);
		}
	}
}