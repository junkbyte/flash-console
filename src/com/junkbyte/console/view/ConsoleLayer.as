/*
*
* Copyright (c) 2008-2011 Lu Aye Oo
*
* @author 		Lu Aye Oo
*
* http://code.google.com/p/flash-console/
* http://junkbyte.com
*
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
*
*/
package com.junkbyte.console.view
{

	import com.junkbyte.console.Console;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.events.ConsoleLayerEvent;
	import com.junkbyte.console.events.ConsolePanelEvent;
	import com.junkbyte.console.view.mainPanel.MainPanel;

	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;

	[Event(name = "panelAdded", type = "com.junkbyte.console.events.ConsoleLayerEvent")]
	[Event(name = "panelRemoved", type = "com.junkbyte.console.events.ConsoleLayerEvent")]
	public class ConsoleLayer extends Sprite
	{

		private var console:Console;

		private var _stageModule:StageModule;

		private var _panels:Vector.<ConsolePanel> = new Vector.<ConsolePanel>();

		public function ConsoleLayer()
		{
			name = "ConsoleLayer";
		}

		public function initUsingConsole(console:Console):void
		{
			this.console = console;
			initStageModule();
			initToolTip();
			initMainPanel();
		}

		protected function initStageModule():void
		{
			_stageModule = new StageModule();
			_stageModule.registerSelfToConsoleWhenAddedToStage(console);
		}

		protected function initToolTip():void
		{
			console.modules.registerModule(new ToolTipModule());
		}

		protected function initMainPanel():void
		{
			console.modules.registerModule(new MainPanel());
		}

		public function toggleVisibility():void
		{
			if (visible && !mainPanel.sprite.visible)
			{
				mainPanel.sprite.visible = true;
			}
			else
			{
				visible = !visible;
			}
			mainPanel.moveToLastSafePosition();
		}

		override public function set visible(v:Boolean):void
		{
			super.visible = v;
			if (v)
			{
				mainPanel.sprite.visible = true;
			}
			console.dispatchEvent(ConsoleEvent.create(visible ? ConsoleEvent.SHOWN : ConsoleEvent.HIDDEN));
		}

		//
		//
		//

		public function addPanel(panel:ConsolePanel):void
		{
			panel.addEventListener(ConsolePanelEvent.PANEL_REMOVED, onPanelRemoved);
			_panels.push(panel);
			addChild(panel.sprite);
			dispatchEvent(new ConsoleLayerEvent(ConsoleLayerEvent.PANEL_ADDED, panel));
		}

		private function onPanelRemoved(event:Event):void
		{
			var panel:ConsolePanel = event.currentTarget as ConsolePanel;
			panel.removeEventListener(ConsolePanelEvent.PANEL_REMOVED, onPanelRemoved);
			var index:int = _panels.indexOf(panel);
			if (index >= 0)
			{
				_panels.splice(index, 1);
			}
			dispatchEvent(new ConsoleLayerEvent(ConsoleLayerEvent.PANEL_REMOVED, panel));
		}

		public function getPanelFromDisplay(display:DisplayObject):ConsolePanel
		{
			for each (var panel:ConsolePanel in _panels)
			{
				if (panel.sprite == display || panel.sprite.contains(display))
				{
					return panel;
				}
			}
			return null;
		}

		public function get mainPanel():MainPanel
		{
			return console.mainPanel;
		}
	}
}
