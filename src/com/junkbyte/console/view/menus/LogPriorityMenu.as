package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.interfaces.IKeyStates;
	import com.junkbyte.console.view.mainPanel.MainPanelLogs;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	import flash.events.Event;

	public class LogPriorityMenu extends ConsoleMenuItem
	{
		private var logsPanel:MainPanelLogs;

		public function LogPriorityMenu(logsPanel:MainPanelLogs)
		{
			this.logsPanel = logsPanel;
			super("P0", onMenuClick, null, "Priority filter::shift: previous priority\n(skips unused priorites)");
		}

		override public function onMenuAdded(module:IConsoleModule):void
		{
			super.onMenuAdded(module);
			logsPanel.addEventListener(MainPanelLogs.FILTER_PRIORITY_CHANGED, onDispatch);
			update();
		}

		override public function onMenuRemoved(module:IConsoleModule):void
		{
			logsPanel.removeEventListener(MainPanelLogs.FILTER_PRIORITY_CHANGED, onDispatch);
			super.onMenuRemoved(module);
		}

		protected function onMenuClick():void
		{
			var keyStates:IKeyStates = console.modules.findModulesByMatcher(new ModuleTypeMatcher(IKeyStates)) as IKeyStates;

			logsPanel.incPriority(keyStates != null && keyStates.shiftKeyDown);
		}

		protected function onDispatch(event:Event):void
		{
			update();
			announceChanged();
		}

		protected function update():void
		{
			active = logsPanel.priority > 0;
			name = "P" + logsPanel.priority;
		}
	}
}
