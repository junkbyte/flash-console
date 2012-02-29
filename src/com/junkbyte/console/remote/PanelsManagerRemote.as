package com.junkbyte.console.remote
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.view.MainPanel;
	import com.junkbyte.console.view.PanelsManager;
	
	public class PanelsManagerRemote extends PanelsManager
	{
		public function PanelsManagerRemote(master:Console)
		{
			super(master);
		}
		
		override protected function createMainPanel():MainPanel
		{
			return new MainPanelRemote(console);
		}
	}
}