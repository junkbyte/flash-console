package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.view.ConsolePanel;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	public class ClosePanelMenu extends BaseConsoleMenuModule
	{

		private var panel:ConsolePanel;

		public function ClosePanelMenu(panel:ConsolePanel)
		{
			this.panel = panel;
			super();
		}

		override protected function initMenu():void
		{
			menu = new ConsoleMenuItem("X", onClick);
			menu.tooltip = "Close::Type password to show again";
			menu.sortPriority = -90;
		}

		override protected function onClick():void
		{
			panel.removeFromParent();
		}
	}
}
