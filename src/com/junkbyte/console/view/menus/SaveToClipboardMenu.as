package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IKeyStates;
	import com.junkbyte.console.interfaces.IMainMenu;
	import com.junkbyte.console.vos.ConsoleMenuItem;
	
	import flash.net.FileReference;
	import flash.system.System;

	public class SaveToClipboardMenu extends ConsoleMenuModule
	{
		public function SaveToClipboardMenu()
		{
			super();
		}

		override protected function initMenu():void
		{
			menu = new ConsoleMenuItem("Sv", onClick, null, "Save to clipboard::shift: no channel name\nctrl: use viewing filters\nalt: save to file");
			menu.sortPriority = -60;
		}

		override protected function onClick():void
		{
			var keyStates:IKeyStates = modules.findModulesByMatcher(new ModuleTypeMatcher(IKeyStates)) as IKeyStates;

			if (keyStates == null)
			{
				copyToClipboard(getLogsWOptions());
			}
			else
			{
				var string:String = getLogsWOptions(!keyStates.shiftKeyDown, keyStates.ctrlKeyDown ? layer.mainPanel.traces.lineShouldShow : null);
				if (keyStates.altKeyDown)
				{
					saveToFile(string);
				}
				else
				{
					copyToClipboard(string);
				}
			}
		}

		protected function getLogsWOptions(incChNames:Boolean = true, filterFunction:Function = null):String
		{
			return console.logger.logs.getLogsAsString("\r\n", incChNames, filterFunction);
		}

		protected function copyToClipboard(string:String):void
		{
			System.setClipboard(string);
			report("Copied to clipboard.", -1);
		}

		protected function saveToFile(string:String):void
		{
			var file:FileReference = new FileReference();
			try
			{
				file.save(string, generateFileName());
			}
			catch (err:Error)
			{
				report("Error saving to file.", 8);
			}
		}

		protected function generateFileName():String
		{
			return "log.txt";
		}
	}
}
