/*
* 
* Copyright (c) 2008-2009 Lu Aye Oo
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
package com.luaye.console.view {
	import com.luaye.console.Console;

	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class ChannelsPanel extends AbstractPanel{
		
		private var _txtField:TextField;
		
		private var _channels:Array;
		
		public function ChannelsPanel(m:Console) {
			super(m);
			name = Console.PANEL_CHANNELS;
			init(10,10,false);
			_txtField = new TextField();
			_txtField.name = "channelsField";
			_txtField.wordWrap = true;
			_txtField.width = 160;
			_txtField.multiline = true;
			_txtField.autoSize = TextFieldAutoSize.LEFT;
			_txtField.styleSheet = style.css;
			_txtField.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			registerRollOverTextField(_txtField);
			_txtField.addEventListener(AbstractPanel.TEXT_LINK, onMenuRollOver, false, 0, true);
			registerDragger(_txtField);
			addChild(_txtField);
		}
		public function start(channels:Array):void{
			_channels = channels;
			update();
		}
		public function update():void{
			_txtField.wordWrap = false;
			_txtField.width = 80;
			var str:String = "<w><menu> <b><a href=\"event:close\">X</a></b></menu> "+ master.panels.mainPanel.getChannelsLink();
			_txtField.htmlText = str+"</w>";
			if(_txtField.width>160){
				_txtField.wordWrap = true;
				_txtField.width = 160;
			}
			width = _txtField.width+4;
			height = _txtField.height;
		}
		private function onMenuRollOver(e:TextEvent):void{
			master.panels.mainPanel.onMenuRollOver(e, this);
		}
		protected function linkHandler(e:TextEvent):void{
			_txtField.setSelection(0, 0);
			if(e.text == "close"){
				master.channelsPanel = false;
			}else if(e.text.substring(0,8) == "channel_"){
				master.panels.mainPanel.onChannelPressed(e.text.substring(8));
			}
			_txtField.setSelection(0, 0);
			e.stopPropagation();
		}
	}
}