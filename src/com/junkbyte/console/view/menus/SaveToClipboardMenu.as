package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IKeyStates;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	import flash.net.FileReference;
	import flash.system.System;

	public class SaveToClipboardMenu extends BaseConsoleMenuModule
	{

		public var defaultSaveFileName:String = "log.txt";

		public function SaveToClipboardMenu()
		{
			super();

			addModuleRegisteryCallback(new ModuleTypeMatcher(IKeyStates), onKeyStatesModuleChange, onKeyStatesModuleChange);
		}

		protected function onKeyStatesModuleChange(keyStates:IKeyStates):void
		{
			update();
		}

		override protected function initMenu():void
		{
			menu = new ConsoleMenuItem("Sv", onClick);
			menu.sortPriority = -60;
			update();
		}

		override protected function onClick():void
		{
			var keyStates:IKeyStates = getKeyStates();

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

		override protected function update():void
		{
			var str:String = "Save to clipboard";

			if (getKeyStates() != null)
			{
				str += "::shift: no channel name\nctrl: use viewing filters\nalt: save to file";
			}

			menu.tooltip = str;
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
				file.save(string, generateSaveFileName());
			}
			catch (err:Error)
			{
				report("Error saving to file.", 8);
			}
		}

		protected function generateSaveFileName():String
		{
			return defaultSaveFileName;
		}

		protected function getKeyStates():IKeyStates
		{
			return modules.findModulesByMatcher(new ModuleTypeMatcher(IKeyStates)) as IKeyStates;
		}
	}
}
