/*
* 
* Copyright (c) 2008 Atticmedia
* 
* @author 		Lu Aye Oo
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
* 
*/
package com.atticmedia.console.core {
	import flash.events.MouseEvent;	
	import flash.geom.Rectangle;	
	import flash.text.*;
	import flash.display.*;	

	public class ChannelsPanel extends Sprite{
		
		private var _channelsField:TextField;
		private var _bg:Shape;
		
		public function ChannelsPanel() {
			name = "ChannelsPanel";
			
			
			_bg = new Shape();
			_bg.name = "ChannelsBackground";
			_bg.graphics.beginFill(0, 0.6);
			_bg.graphics.drawRoundRect(0, 0, 100, 18,8,8);
			var grid:Rectangle = new Rectangle(10, 8, 80, 8);
			_bg.scale9Grid = grid ;
			addChild(_bg);
			
			_channelsField = new TextField();
			_channelsField.name = "channelsField";
			_channelsField.wordWrap = true;
			_channelsField.background  = false;
			_channelsField.multiline = true;
			_channelsField.autoSize = TextFieldAutoSize.LEFT;
			_channelsField.width = 160;
			_channelsField.x = -120;
			_channelsField.selectable = false;
			_channelsField.addEventListener(MouseEvent.MOUSE_DOWN, onFieldMouseDown, false, 0, true);
			_channelsField.addEventListener(MouseEvent.MOUSE_UP, onFieldMouseUp, false, 0, true);
			
			
			addChild(_channelsField);
			_bg.x = _channelsField.x;
		}
		
		private function onFieldMouseDown(e:MouseEvent):void{
			startDrag();
		}
		private function onFieldMouseUp(e:MouseEvent):void{
			stopDrag();
		}
		public function update(list:Array, viewing:Array, current:String, pinned:Boolean):void{
			var str:String = "<textformat leading=\"2\"><font face=\"Arial\" size=\"11\" color=\"#FFFFFF\" >";
			
			str += "<font color=\"#DD5500\"><b><a href=\"event:pinChannels\">"+(pinned?"^^":"vv")+"</a>]</b></font> ";
			for each(var channel in list){
				var channelTxt:String = (viewing.indexOf(channel)>=0) ? "<font color=\"#0099CC\"><b>"+channel+"</b></font>" : channel;
				channelTxt = channel==current ? "<i>"+channelTxt+"</i>" : channelTxt;
				str += "<a href=\"event:channel_"+channel+"\">["+channelTxt+"]</a> ";
			}
			_channelsField.htmlText = str+"</font></textformat>";
			
			_bg.width = _channelsField.width;
			_bg.height = _channelsField.height;
		}
	}
}