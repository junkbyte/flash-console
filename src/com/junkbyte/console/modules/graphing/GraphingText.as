package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.ConsoleStyle;
	import com.junkbyte.console.view.ConsolePanel;
	
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class GraphingText
	{
		private var panel:GraphingPanelModule;
		private var group:GraphingGroup;
		private var textField:TextField;

		public function GraphingText(targetPanel:GraphingPanelModule, group:GraphingGroup)
		{
			this.panel = targetPanel;
			this.group = group;

			textField = new TextField();
			textField.name = "menuField";
			textField.autoSize = TextFieldAutoSize.RIGHT;
			var style:ConsoleStyle = targetPanel.style;
			textField.height = style.menuFontSize + 4;
			textField.y = -3;
			
			textField.addEventListener(TextEvent.LINK, linkHandler);

			textField.defaultTextFormat = new TextFormat(style.menuFont, style.traceFontSize, style.menuColor);
			targetPanel.registerMoveDragger(textField);
			targetPanel.addChild(textField);
		}

		public function setArea(x:Number, y:Number, width:Number, height:Number):void
		{
			textField.x = 0;
			textField.width = width;
		}

		public function update(event:GraphingGroupEvent):void
		{

			var str:String = "<r><low>";

			for (var X:String in group.lines)
			{
				var line:GraphingLine = group.lines[X];
				var value:Number = event.values[X];
				str += " <font color='#" + line.color.toString(16) + "'>" + value + "</font>";
			}
			str += " | <menu><a href=\"event:reset\">R</a>";
			str += " <a href=\"event:close\">X</a></menu></low></r>";
			textField.htmlText = str;
			textField.scrollH = textField.maxScrollH;
		}

		protected function linkHandler(e:TextEvent):void
		{
			TextField(e.currentTarget).setSelection(0, 0);
			if (e.text == "reset")
			{
				panel.reset();
			}
			else if (e.text == "close")
			{
				panel.modules.unregisterModule(panel);
			}
			e.stopPropagation();
		}

		protected function onMenuRollOver(e:TextEvent):void
		{
			var txt:String = e.text ? e.text.replace("event:", "") : null;
			//panel.layer.tooltip(txt, this);
		}
	}
}
