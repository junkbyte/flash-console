package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.interfaces.IKeyStates;
	import com.junkbyte.console.logging.ConsoleLogsFilter;
	import com.junkbyte.console.view.mainPanel.MainPanel;
	import com.junkbyte.console.vos.ConsoleMenuItem;
	
	import flash.events.Event;

	public class LogPriorityMenu extends ConsoleMenuItem
	{
		public function LogPriorityMenu()
		{
			super("P0", onMenuClick, null, "Priority filter::shift: previous priority\n(skips unused priorites)");
		}

		override public function onMenuAdded(module:IConsoleModule):void
		{
			super.onMenuAdded(module);
			console.logsFilter.addEventListener(ConsoleLogsFilter.FILTER_PRIORITY_CHANGED, onDispatch);
			update();
		}

		override public function onMenuRemoved(module:IConsoleModule):void
		{
			console.logsFilter.removeEventListener(ConsoleLogsFilter.FILTER_PRIORITY_CHANGED, onDispatch);
			super.onMenuRemoved(module);
		}

		protected function onMenuClick():void
		{
			var keyStates:IKeyStates = console.modules.findModulesByMatcher(new ModuleTypeMatcher(IKeyStates)) as IKeyStates;

			console.logsFilter.incPriority(keyStates != null && keyStates.shiftKeyDown);
		}

		protected function onDispatch(event:Event):void
		{
			update();
			announceChanged();
		}

		protected function update():void
		{
			active = console.logsFilter.priority > 0;
			name = "P" + console.logsFilter.priority;
		}
	}
}
