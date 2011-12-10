package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	public class PauseLogDisplayMenu extends BaseConsoleMenuModule
	{

		public function PauseLogDisplayMenu()
		{
			super();
		}

		override protected function initMenu():void
		{
			console.addEventListener(ConsoleEvent.PAUSED, onRelatedChanged);
			console.addEventListener(ConsoleEvent.RESUMED, onRelatedChanged);

			menu = new ConsoleMenuItem("P", onClick);
			menu.sortPriority = -70;

			update();
		}

		override protected function decMenu():void
		{
			console.removeEventListener(ConsoleEvent.PAUSED, onRelatedChanged);
			console.removeEventListener(ConsoleEvent.RESUMED, onRelatedChanged);
		}

		override protected function onClick():void
		{
			console.paused = !console.paused;
		}

		override protected function update():void
		{
			if (console.paused)
			{
				menu.active = true;
				menu.tooltip = "Resume updates";
			}
			else
			{
				menu.active = false;
				menu.tooltip = "Pause updates";
			}
		}
	}
}
