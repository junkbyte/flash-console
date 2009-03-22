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
	import flash.geom.Point;	
	import flash.events.MouseEvent;	
	import flash.text.TextFieldAutoSize;	
	import flash.geom.Rectangle;	
	import flash.text.TextField;	
	import flash.display.Shape;	
	import flash.display.Sprite;
	import flash.events.Event;		

	public class DisplayRoller extends Sprite{
		
		public static const NAME:String = "roller";
		public static const EXIT:String = "exit";
		
		private var _reportFunction:Function;
		
		private var _channelsField:TextField;
		private var _bg:Shape;
		
		
		public function DisplayRoller() {
			name = NAME;
			
			_bg = new Shape();
			_bg.name = "rollerbg";
			_bg.graphics.beginFill(0, 0.6);
			_bg.graphics.drawRoundRect(0, 0, 100, 18,8,8);
			var grid:Rectangle = new Rectangle(10, 8, 80, 8);
			_bg.scale9Grid = grid ;
			addChild(_bg);
			
			_channelsField = new TextField();
			_channelsField.name = "rollerprints";
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
		public function start(reportFunction:Function = null):void{
			_reportFunction = reportFunction;
			addEventListener(Event.ENTER_FRAME, _onFrame, false, 0, true);
		}
		
		private function _onFrame(e:Event):void{
			var objs:Array = parent.parent.getObjectsUnderPoint(new Point(parent.parent.mouseX, parent.parent.mouseY));
			for(var X:String in objs){
				objs[X] = objs[X].name;
			}
			_channelsField.htmlText = "<font color=\"#DD5500\"><b>"+objs.toString()+"</font>";
			_bg.width = _channelsField.width;
			_bg.height = _channelsField.height;
		}
		
		public function exit():void{
			removeEventListener(Event.ENTER_FRAME, _onFrame);
			_reportFunction = null;
			dispatchEvent(new Event(EXIT));
		}
		private function report(txt:String, prio:Number=5, skipSafe:Boolean = false, quiet:Boolean = false):void {
			if (_reportFunction != null) {
				_reportFunction(new LogLineVO(txt,null,prio,false,skipSafe), quiet);
			} else {
				trace("C: "+ txt);
			}
		}
	}
}