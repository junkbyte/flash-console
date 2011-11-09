/*
* 
* Copyright (c) 2008-2010 Lu Aye Oo
* 
* @author 		Lu Aye Oo
* 
* http://code.google.com/p/flash-console/
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
package com.junkbyte.console.view {
	import com.junkbyte.console.core.ConsoleModulesManager;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.logging.Logs;
	import com.junkbyte.console.view.helpers.ConsoleTextRoller;
	
	import flash.events.Event;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class ChannelsPanel extends ConsolePanel{
		
		public static const NAME:String = "channelsPanel";
		
		protected var txtField:TextField;
		
		protected var needsUpdate:Boolean = true;
		
		public function ChannelsPanel() {
			super();
			sprite.name = NAME;
		}
		
		
		
		override protected function initToConsole():void
		{
			super.initToConsole();
			
			txtField = new TextField();
			txtField.name = "channelsField";
			txtField.styleSheet = style.styleSheet;
			txtField.wordWrap = true;
			txtField.width = 160;
			txtField.multiline = true;
			txtField.autoSize = TextFieldAutoSize.LEFT;
			
			ConsoleTextRoller.register(txtField, onMenuRollOver, linkHandler);
			registerMoveDragger(txtField);
			
			addChild(txtField);
		}
		
		override protected function registeredToConsole():void
		{
			display.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			console.logger.logs.addEventListener(Logs.CHANNELS_CHANGED, onChannelsChanged);
			
			super.registeredToConsole();
		}
		
		override protected function unregisteredFromConsole():void
		{
			display.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			console.logger.logs.removeEventListener(Logs.CHANNELS_CHANGED, onChannelsChanged);
			
			super.unregisteredFromConsole();
		}
		
		private function onChannelsChanged(e:Event):void
		{
			needsUpdate = true;
		}
		
		protected function onEnterFrame(event:Event):void
		{
			if(needsUpdate)
			{
				update();
				needsUpdate = false;
			}
		}
		
		
		protected function update():void{
			txtField.wordWrap = false;
			txtField.width = 80;
			var str:String = "<high><menu> <b><a href=\"event:close\">X</a></b></menu> "+ layer.mainPanel.traces.getChannelsLink();
			txtField.htmlText = str+"</high>";
			if(txtField.width>160){
				txtField.wordWrap = true;
				txtField.width = 160;
			}
			setPanelSize(txtField.width+4, txtField.height);
		}
		
		private function onMenuRollOver(e:TextEvent):void
		{
			//modules.display.mainPanel.onMenuRollOver(e, this);
		}
		
		protected function linkHandler(e:TextEvent):void{
			txtField.setSelection(0, 0);
			if(e.text == "close"){
				close();
				layer.channelsPanel = false;
			}else if(e.text.substring(0,8) == "channel_"){
				layer.mainPanel.traces.onChannelPressed(e.text.substring(8));
			}
			txtField.setSelection(0, 0);
			e.stopPropagation();
		}
	}
}