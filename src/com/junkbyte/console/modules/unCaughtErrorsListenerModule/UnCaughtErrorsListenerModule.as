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
		
		override public function registeredToConsole(console:Console):void
		{
			super.registeredToConsole(console);
			if(console.display.parent != null)
			{
				onConsoleAddedToDisplay();
			}
			else
			{
				console.display.addEventListener(Event.ADDED, onConsoleAddedToDisplay, false, 0, true);
			}
		}
		
		protected function onConsoleAddedToDisplay(e:Event = null):void
		{
			console.display.removeEventListener(Event.ADDED, onConsoleAddedToDisplay);
			if(console.display.loaderInfo != null)
			{
				listen(console.display.loaderInfo);
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
				str = _central.refs.makeString(error);
			}else if (error is ErrorEvent){
				str = ErrorEvent(error).text;
			}
			if(!str){
				str = String(error);
			}
			_central.report("Uncaught Error:"+str, ConsoleLevel.FATAL, false);
		}
	}
}