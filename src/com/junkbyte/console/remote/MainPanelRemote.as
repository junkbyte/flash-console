package com.junkbyte.console.remote
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.Remoting;
	import com.junkbyte.console.view.MainPanel;
	
	import flash.events.Event;
	import flash.events.TextEvent;
	
	public class MainPanelRemote extends MainPanel
	{
		public function MainPanelRemote(m:Console)
		{
			super(m);
		}
		
		override protected function updateCmdHint(e:Event = null):void{
			
			
		}
		
		override protected function linkHandler(e:TextEvent):void{
			super.linkHandler(e);
			if(e.text == "remote")
			{
				console.remoter.remoting = Remoting.RECIEVER;
			}
		}
	}
}