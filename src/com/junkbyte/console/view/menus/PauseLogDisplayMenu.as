package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	import flash.events.Event;

	public class PauseLogDisplayMenu extends ConsoleMenuItem
	{

		public function PauseLogDisplayMenu()
		{
			super("P", onMenuClick);
		}

		protected function onMenuClick():void
		{
			console.paused = !console.paused;
		}

		override public function onMenuAdded(module:IConsoleModule):void
		{
			super.onMenuAdded(module);
			console.addEventListener(ConsoleEvent.PAUSED, onConsoleChange);
			console.addEventListener(ConsoleEvent.RESUMED, onConsoleChange);
			update();
		}

		override public function onMenuRemoved(module:IConsoleModule):void
		{
			console.removeEventListener(ConsoleEvent.PAUSED, onConsoleChange);
			console.removeEventListener(ConsoleEvent.RESUMED, onConsoleChange);
			super.onMenuRemoved(module);
		}

		protected function onConsoleChange(event:Event):void
		{
			update();
			announceChanged();
		}

		protected function update():void
		{
			active = console.paused;
		}

		override public function getTooltip():String
		{
			return isActive() ? "Resume updates" : "Pause updates";
		}
	}
}
