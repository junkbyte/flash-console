package com.junkbyte.console.addons.autoFocus
{
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.Console;
	import com.junkbyte.console.view.ConsolePanel;
	import com.junkbyte.console.view.MainPanel;

	import flash.events.Event;
	import flash.text.TextField;

	/**
	 * This addon sets focus to commandLine input field whenever Console becomes visible, e.g after entering password key.
	 */
	public class CommandLineAutoFocusAddon
	{
		public static function registerToConsole(console:Console = null):void
		{
			if (console == null)
			{
				console = Cc.instance;
			}
			if (console == null)
			{
				return;
			}

			console.panels.mainPanel.addEventListener(ConsolePanel.VISIBLITY_CHANGED, onPanelVisibilityChanged);
		}

		private static function onPanelVisibilityChanged(event:Event):void
		{
			var mainPanel:MainPanel = event.currentTarget as MainPanel;

			if (mainPanel.visible == false)
			{
				return;
			}

			var commandField:TextField = mainPanel.getChildByName("commandField") as TextField;

			if (commandField && commandField.stage)
			{
				commandField.stage.focus = commandField;
				var textLen:uint = commandField.text.length;
				commandField.setSelection(textLen, textLen);
			}
		}
	}
}
