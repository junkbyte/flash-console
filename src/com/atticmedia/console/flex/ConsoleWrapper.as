package com.atticmedia.console.flex
{
	import com.atticmedia.console.C;
	
	import flash.events.Event;
	
	import mx.core.Container;
	import mx.core.UIComponent;
	
	public class ConsoleWrapper extends UIComponent
	{
		private static var _wrapper:ConsoleWrapper;
		
		public function ConsoleWrapper()
		{
		}
		public function listChanged(e:Event):void
		{
			if(C.exists && C.alwaysOnTop){
				if(!_wrapper.parent || _wrapper.parent != e.currentTarget){
					e.currentTarget.removeEventListener(Event.ADDED, _wrapper.listChanged);
				}else{
					_wrapper.parent.setChildIndex(_wrapper,_wrapper.parent.numChildren-1);
				}
			}
		}
		
		public static function start(ui:Container, p:String = "", allowInBrowser:Boolean = true, forceRunOnRemote:Boolean = true):void{
			if(!C.exists){
				_wrapper = new ConsoleWrapper();
				C.start(_wrapper, p, allowInBrowser, forceRunOnRemote);
				ui.addChild(_wrapper);
				ui.addEventListener(Event.ADDED, _wrapper.listChanged, false, 0, true);
			}
		}
	}
}