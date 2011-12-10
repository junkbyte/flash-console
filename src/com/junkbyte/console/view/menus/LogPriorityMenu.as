package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IKeyStates;
	import com.junkbyte.console.view.mainPanel.MainPanel;
	import com.junkbyte.console.view.mainPanel.MainPanelLogs;
	import com.junkbyte.console.vos.ConsoleMenuItem;
	
	import flash.events.IEventDispatcher;

	public class LogPriorityMenu extends BaseConsoleMenuModule
	{
		
		private var dispatcher:IEventDispatcher;
		
		public function LogPriorityMenu(dispatcher:IEventDispatcher)
		{
			this.dispatcher = dispatcher;
			super();
		}

		override protected function initMenu():void
		{
			dispatcher.addEventListener(MainPanelLogs.FILTER_PRIORITY_CHANGED, onRelatedChanged);

			menu = new ConsoleMenuItem("P0", onClick);
			menu.tooltip = "Priority filter::shift: previous priority\n(skips unused priorites)";
			menu.sortPriority = -80;
		}

		override protected function decMenu():void
		{
			dispatcher.removeEventListener(MainPanelLogs.FILTER_PRIORITY_CHANGED, onRelatedChanged);
		}

		override protected function onClick():void
		{
			var keyStates:IKeyStates = modules.findModulesByMatcher(new ModuleTypeMatcher(IKeyStates)) as IKeyStates;

			mainPanel.traces.incPriority(keyStates != null && keyStates.shiftKeyDown);
		}

		override protected function update():void
		{
			menu.active = mainPanel.traces.priority > 0;
			menu.name = "P" + mainPanel.traces.priority;
		}

		protected function get mainPanel():MainPanel
		{
			return layer.mainPanel;
		}
	}
}
