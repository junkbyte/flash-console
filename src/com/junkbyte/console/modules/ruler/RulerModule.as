package com.junkbyte.console.modules.ruler
{
	import com.junkbyte.console.vos.ConsoleModuleMatch;
	import com.junkbyte.console.interfaces.IMainMenu;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	import flash.events.Event;
	/**
	 * @author LuAye
	 */
	public class RulerModule extends ConsoleModule{
		
		public static const NAME:String = "ruler";
		
		protected var menu:ConsoleMenuItem;
		protected var _ruler:Ruler;
		
		
		public function RulerModule()
		{
			menu = new ConsoleMenuItem("RL", start, null, "Screen Ruler::Measure the distance and angle between two points on screen.");
			
			addModuleDependencyCallback(ConsoleModuleMatch.createForClass(IMainMenu), onMainMenuRegistered, onMainMenuUnregistered);
		}
		
		protected function onMainMenuRegistered(module:IMainMenu):void
		{
			module.addMenu(menu);
		}
		
		protected function onMainMenuUnregistered(module:IMainMenu):void
		{
			module.removeMenu(menu);
		}
		
		override public function getModuleName() : String 
		{
			return NAME;
		}
		
		private function start():void
		{
			_ruler = new Ruler(this);
			_ruler.addEventListener(Event.CLOSE, onExit, false, 0, true);
			layer.addChild(_ruler);
			menu.active = true;
			menu.announceChanged();
		}
		
		protected function onExit(event:Event):void
		{
			if(_ruler && layer.contains(_ruler))
			{
				layer.removeChild(_ruler);
			}
			_ruler = null;
			menu.active = false;
			menu.announceChanged();
		}
	}
}
