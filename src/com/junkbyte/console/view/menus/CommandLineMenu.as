package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.view.mainPanel.MainPanel;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	import flash.events.Event;

	public class CommandLineMenu extends ConsoleMenuItem
	{

		private var mainPanel:MainPanel;

		public function CommandLineMenu(mainPanel:MainPanel)
		{
			super("CL", onMenuClick);
			this.mainPanel = mainPanel;
		}

		protected function onMenuClick():void
		{
			mainPanel.commandLine = !mainPanel.commandLine;
		}

		override public function getTooltip():String
		{
			return isActive() ? "Hide Command Line" : "Show Command Line";
		}

		override public function onMenuAdded(module:IConsoleModule):void
		{
			super.onMenuAdded(module);
			mainPanel.addEventListener(MainPanel.COMMAND_LINE_VISIBLITY_CHANGED, onCLVisibiltyChanged);
			update();
		}

		override public function onMenuRemoved(module:IConsoleModule):void
		{
			mainPanel.addEventListener(MainPanel.COMMAND_LINE_VISIBLITY_CHANGED, onCLVisibiltyChanged);
			super.onMenuRemoved(module);
		}

		protected function onCLVisibiltyChanged(event:Event):void
		{
			update();
			announceChanged();
		}

		protected function update():void
		{
			active = mainPanel.commandLine;
		}
	}
}
