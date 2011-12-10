package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.vos.ConsoleMenuItem;

	public class ClearLogsMenu extends BaseConsoleMenuModule
	{

		public function ClearLogsMenu()
		{
			super();
		}

		override protected function initMenu():void
		{
			menu = new ConsoleMenuItem("C", onClick);
			menu.sortPriority = -80;
		}

		override protected function onClick():void
		{
			logger.logs.clear();
		}
	}
}
