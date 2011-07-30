package com.junkbyte.console.vos {
	import com.junkbyte.console.interfaces.IConsoleMenuItem;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	[Event(name="change", type="flash.events.Event")]
	public class ConsoleMenuItem extends EventDispatcher implements IConsoleMenuItem{
		
		public var name:String;
		public var callback:Function;
		public var arguments:Array;
		public var tooltip:String;
		public var visible:Boolean;
		public var active:Boolean;
		public var sortPriority:int;
		
		public function ConsoleMenuItem(name : String, cb:Function = null, args:Array = null, tooltip:String = null) : void {
			this.name = name;
			this.callback = cb;
			this.arguments = args;
			this.tooltip = tooltip;
		}
		
		
		public function isVisible():Boolean{
			return visible;
		}
		
		public function getName():String{
			return name;
		}
		
		public function onClick():void{
			if(callback != null)
			{
				callback.apply(this, arguments);
			}
		}
		
		// return true if you want it to be on active state (bold text)
		public function isActive():Boolean{
			return active;
		}
		
		public function getTooltip():String{
			return tooltip;
		}
		
		public function getSortPriority():int{
			return sortPriority;
		}
		
		public function announceChanged():void{
			dispatchEvent(new Event(Event.CHANGE));
		}
	}
}
