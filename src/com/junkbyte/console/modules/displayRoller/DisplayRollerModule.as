package com.junkbyte.console.modules.displayRoller {
	import com.junkbyte.console.Console;
	import com.junkbyte.console.KeyBind;
	import com.junkbyte.console.core.ConsoleCore;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	import flash.events.Event;
	/**
	 * @author LuAye
	 */
	public class DisplayRollerModule extends ConsoleCore{
		
		public static const NAME:String = "displayRoller";
		
		protected var menu:ConsoleMenuItem;
		protected var roller:DisplayRoller;
		protected var _rollerKey:KeyBind;
		
		public function DisplayRollerModule()
		{
			menu = new ConsoleMenuItem("Ro", onClick, null, "Display Roller::Map the display list under your mouse");
		}
		
		override public function registerConsole(console:Console):void
		{
			super.registerConsole(console);
			_central.mainPanelMenu.addMenu(menu);
		}
		
		override public function unregisterConsole(console:Console):void
		{
			_central.mainPanelMenu.removeMenu(menu);
			super.unregisterConsole(console);
		}
		
		override public function getModuleName() : String 
		{
			return NAME;
		}
		
		public function setRollerCaptureKey(char:String, shift:Boolean = false, ctrl:Boolean = false, alt:Boolean = false):void{
			if(_rollerKey){
				_central.keyBinder.bindKey(_rollerKey, null);
				_rollerKey = null;
			}
			if(char && char.length==1) {
				_rollerKey = new KeyBind(char, shift, ctrl, alt);
				_central.keyBinder.bindKey(_rollerKey, onRollerCaptureKey);
			}
		}
		
		protected function onRollerCaptureKey():void{
			if(roller){
				_central.report("Display Roller Capture:<br/>"+roller.getMapString(true), -1);
			}
		}
		
		public function get rollerCaptureKey():KeyBind{
			return _rollerKey;
		}
		
		protected function onClick():void
		{
			if(roller) end();
			else start();
		}
		
		public function start():void
		{
			if(roller) return;
			roller = new DisplayRoller(_central);
			roller.x = panels.mainPanel.x+panels.mainPanel.width-180;
			roller.y = panels.mainPanel.y + 55;
			roller.addEventListener(Event.CLOSE, onClose, false, 0, true);
			_central.panels.addPanel(roller);
			menu.active = true;
			menu.announceChanged();
		}
		
		public function end():void
		{
			if(!roller) return;
			roller.close();
		}
		
		protected function onClose(event:Event):void
		{
			roller = null;
			menu.active = false;
			menu.announceChanged();
		}
	}
}