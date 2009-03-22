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
		}
		public function start(reportFunction:Function = null):void{
			_reportFunction = reportFunction;
			
		}
		
		public function exit():void{
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