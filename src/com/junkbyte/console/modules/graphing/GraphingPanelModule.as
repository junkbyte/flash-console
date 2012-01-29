package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.view.ConsolePanel;
	import com.junkbyte.console.view.helpers.ConsoleTextRoller;

	import flash.events.Event;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class GraphingPanelModule extends ConsolePanel
	{

		protected var _group:GraphingGroup;
		protected var _graph:GraphingBitmap;
		protected var textField:TextField;

		protected var _menuString:String;

		public function GraphingPanelModule(group:GraphingGroup)
		{
			super();

			_group = group;

		}

		public function get group():GraphingGroup
		{
			return _group;
		}

		override protected function initToConsole():void
		{
			super.initToConsole();

			group.addEventListener(Event.CLOSE, onCloseEvent);
			group.addPushCallback(onGroupPush);

			startPanelResizer();

			registerMoveDragger(background);

			minSize.x = 32;
			minSize.y = 26;

			initTextField();
			initGrapher();

			setPanelSize(80, 40);
			addToLayer();
		}

		protected function initGrapher():void
		{
			_graph = new GraphingBitmap(this, group);
		}

		override protected function unregisteredFromConsole():void
		{
			_group.removePushCallback(onGroupPush);
			_group = null;
			super.unregisteredFromConsole();
		}

		override protected function resizePanel(w:Number, h:Number):void
		{
			super.resizePanel(w, h);
			resizeTextArea();
			resizeGrapher();
		}

		protected function resizeTextArea():void
		{
			textField.x = 0;
			textField.width = width;
		}

		protected function resizeGrapher():void
		{
			_graph.setArea(0, style.menuFontSize, width - 5, height - style.menuFontSize);
		}

		public function reset():void
		{
			_graph.reset();
		}

		protected function onGroupPush(group:GraphingGroup, values:Vector.<Number>):void
		{
			_graph.push(values);
			updateTextField(group, values);
		}

		protected function onCloseEvent(event:Event):void
		{
			modules.unregisterModule(this);
		}

		protected function initTextField():void
		{
			textField = new TextField();
			textField.name = "menuField";
			textField.autoSize = TextFieldAutoSize.RIGHT;
			textField.height = style.menuFontSize + 4;
			textField.y = -3;
			textField.styleSheet = style.styleSheet;

			ConsoleTextRoller.register(textField, onTextRollOverHandler, onTextLinkHandler);

			registerMoveDragger(textField);
			addChild(textField);
		}

		protected function updateTextField(group:GraphingGroup, values:Vector.<Number>):void
		{
			var str:String = "<r><low>";

			for (var X:String in group.lines)
			{
				var line:GraphingLine = group.lines[X];
				var value:Number = values[X];
				str += " <font color='#" + line.color.toString(16) + "'>" + value + "</font>";
			}
			str += createMenuString() + "</low></r>";
			textField.htmlText = str;
			textField.scrollH = textField.maxScrollH;
		}

		protected function getMenuString():String
		{
			if (_menuString == null)
			{
				_menuString = createMenuString();
			}
			return _menuString;
		}
		
		// TODO , use menu feature, like in main menu
		protected function createMenuString():String
		{
			var str:String = " | <menu>";
			for each (var menu:String in getMenuKeys())
			{
				str += "<menu><a href=\"event:" + menu + "\">" + menu + "</a> ";
			}

			return str + "</menu>";
		}

		protected function getMenuKeys():Vector.<String>
		{
			return Vector.<String>(["R", "X"]);
		}

		protected function onTextLinkHandler(e:TextEvent):void
		{
			e.stopPropagation();
			TextField(e.currentTarget).setSelection(0, 0);
			if (e.text == "R")
			{
				reset();
			}
			else if (e.text == "X")
			{
				group.close();
			}
		}

		protected function onTextRollOverHandler(e:TextEvent):void
		{
			var txt:String = e.text ? e.text : null;

			setTooltip(txt);
		}
	}
}
