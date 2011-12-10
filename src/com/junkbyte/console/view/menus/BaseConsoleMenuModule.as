package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IMainMenu;
	import com.junkbyte.console.vos.ConsoleMenuItem;
	
	import flash.events.Event;

	public class BaseConsoleMenuModule extends ConsoleModule
	{
		protected var menu:ConsoleMenuItem;

		public function BaseConsoleMenuModule()
		{
			super();

			addModuleRegisteryCallback(new ModuleTypeMatcher(IMainMenu), onMainMenuRegistered, onMainMenuUnregistered);
		}

		protected function onMainMenuRegistered(module:IMainMenu):void
		{
			initMenu();
			module.addMenu(menu);
		}

		protected function onMainMenuUnregistered(module:IMainMenu):void
		{
			decMenu();
			module.removeMenu(menu);
		}

		protected function initMenu():void
		{
			// override
		}
		
		protected function decMenu():void
		{
			// override
		}

		protected function onClick():void
		{
			// override
		}
		
		protected function onRelatedChanged(e:Event):void
		{
			update();
			menu.announceChanged();
		}
		
		protected function update():void
		{
			
		}

	}
}
