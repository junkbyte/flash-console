package com.junkbyte.console.view.menus
{
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IKeyStates;
	import com.junkbyte.console.vos.ConsoleMenuItem;

	import flash.net.FileReference;
	import flash.system.System;

	public class SaveToClipboardMenu extends ConsoleMenuItem
	{

		public var defaultSaveFileName:String = "log.txt";

		public function SaveToClipboardMenu()
		{
			super("Sv", onMenuClick);
		}

		protected function onMenuClick():void
		{
			var keyStates:IKeyStates = getKeyStates();

			if (keyStates == null)
			{
				copyToClipboard(getLogsWOptions());
			}
			else
			{
				var string:String = getLogsWOptions(!keyStates.shiftKeyDown, keyStates.ctrlKeyDown ? modules.logsFilter.lineShouldShow : null);
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

		override public function getTooltip():String
		{
			var string:String = "Save to clipboard";

			if (getKeyStates() != null)
			{
				string += "::shift: no channel name\nctrl: use viewing filters\nalt: save to file";
			}
			return string;
		}

		protected function getLogsWOptions(incChNames:Boolean = true, filterFunction:Function = null):String
		{
			return console.logger.logs.getLogsAsString("\r\n", incChNames, filterFunction);
		}

		protected function copyToClipboard(string:String):void
		{
			System.setClipboard(string);
			console.logger.report("Copied to clipboard.", -1);
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
				console.logger.report("Error saving to file.", 8);
			}
		}

		protected function generateSaveFileName():String
		{
			return defaultSaveFileName;
		}

		protected function getKeyStates():IKeyStates
		{
			if (console != null)
			{
				return console.modules.getFirstMatchingModule(new ModuleTypeMatcher(IKeyStates)) as IKeyStates;
			}
			return null;
		}
	}
}
