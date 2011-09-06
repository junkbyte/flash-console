package com.junkbyte.console.modules.displayRoller {
	import com.junkbyte.console.Console;
	import com.junkbyte.console.KeyBind;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.KeyBinder;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.vos.ConsoleMenuItem;
	
	import flash.events.Event;

	public class DisplayRollerModule extends ConsoleModule{
		
		protected var menu:ConsoleMenuItem;
		protected var roller:DisplayRoller;
		protected var _rollerKey:KeyBind;
		
		public function DisplayRollerModule()
		{
			menu = new ConsoleMenuItem("Ro", onClick, null, "Display Roller::Map the display list under your mouse");
		}
		
		override public function registeredToConsole(console:Console):void
		{
			super.registeredToConsole(console);
			_central.mainPanelMenu.addMenu(menu);
		}
		
		override public function unregisteredFromConsole(console:Console):void
		{
			_central.mainPanelMenu.removeMenu(menu);
			super.unregisteredFromConsole(console);
		}
		
		override public function getModuleName() : String 
		{
			return ConsoleModuleNames.DISPLAY_ROLLER;
		}
		
		public function setRollerCaptureKey(char:String, shift:Boolean = false, ctrl:Boolean = false, alt:Boolean = false):void{
			
			var keyBinder:KeyBinder = _central.getModuleByName(ConsoleModuleNames.KEYBINDER) as KeyBinder;
			if(keyBinder == null)
			{
				return;
			}
			if(_rollerKey){
				keyBinder.bindKey(_rollerKey, null);
				_rollerKey = null;
			}
			if(char && char.length==1) {
				_rollerKey = new KeyBind(char, shift, ctrl, alt);
				keyBinder.bindKey(_rollerKey, onRollerCaptureKey);
			}
		}
		
		public function hasKeyBinder():Boolean
		{
			return _central.getModuleByName(ConsoleModuleNames.KEYBINDER) != null;
		}
		
		protected function onRollerCaptureKey():void{
			if(roller){
				report("Display Roller Capture:<br/>"+roller.getMapString(true), -1);
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
			roller = new DisplayRoller(_central, this);
			roller.x = display.mainPanel.x+display.mainPanel.width-180;
			roller.y = display.mainPanel.y + 55;
			roller.addEventListener(Event.CLOSE, onClose, false, 0, true);
			_central.display.addPanel(roller);
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