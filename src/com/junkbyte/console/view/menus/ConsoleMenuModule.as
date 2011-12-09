package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IMainMenu;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	public class ConsoleMenuModule extends ConsoleModule
	{
		protected var menu:ConsoleMenuItem;

		public function SaveToClipboardMenu()
		{
			super();

			initMenu();

			addModuleRegisteryCallback(new ModuleTypeMatcher(IMainMenu), onMainMenuRegistered, onMainMenuUnregistered);
		}

		protected function onMainMenuRegistered(module:IMainMenu):void
		{
			module.addMenu(menu);
		}

		protected function onMainMenuUnregistered(module:IMainMenu):void
		{
			module.removeMenu(menu);
		}

		protected function initMenu():void
		{
			// override
		}

		protected function onClick():void
		{
			// override
		}

	}
}
