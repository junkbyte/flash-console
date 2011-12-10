package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.view.mainPanel.MainPanel;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	public class CommandLineMenu extends BaseConsoleMenuModule
	{

		public function CommandLineMenu()
		{
			super();
		}

		override protected function initMenu():void
		{
			mainPanel.addEventListener(MainPanel.COMMAND_LINE_VISIBLITY_CHANGED, onRelatedChanged);

			menu = new ConsoleMenuItem("CL", onClick);
			menu.sortPriority = -40;

			update();
		}

		override protected function decMenu():void
		{
			mainPanel.removeEventListener(MainPanel.COMMAND_LINE_VISIBLITY_CHANGED, onRelatedChanged);
		}

		override protected function onClick():void
		{
			mainPanel.commandLine = !mainPanel.commandLine;
		}

		override protected function update():void
		{
			menu.active = mainPanel.commandLine;
			menu.tooltip = menu.active ? "Hide Command Line" : "Show Command Line";
		}

		protected function get mainPanel():MainPanel
		{
			return layer.mainPanel;
		}
	}
}
