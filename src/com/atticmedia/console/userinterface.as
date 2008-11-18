/*
* Copyright (c) 2008 Lu Aye Oo (Atticmedia)
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
*/


package com.atticmedia.console {
	import flash.text.TextField;	
	import flash.display.Shape;	
	import flash.text.TextFormat;
	import flash.geom.ColorTransform;
	public class userinterface {

		private var _background:Shape;
		private var _commandBackground:Shape;
		private var _menuField:TextField;
		private var _field:TextField;
		private var _commandField:TextField;
		private var _priorities:Object;
		private var _preset:int;
		
		
		public function userinterface(bg:Shape, menu:TextField, field:TextField, commandBG:Shape, commandField:TextField) {
			_background = bg;
			_commandBackground = commandBG;
			_commandField = commandField;
			_menuField = menu;
			_field = field;
			_priorities = new Object();
			preset = 1;
		}
		
		public function set preset(num:int):void{
			if(this["preset"+num]){
				this["preset"+num]();
				_preset = num;
			}
		}
		public function get preset():int{
			return _preset;
		}
		public function preset1():void{
			setbackgroundColour(0.15,0.15,0.2);
			backgroundAlpha = 0.8;
			backgroundBlendMode = "normal";
			var format:TextFormat = new TextFormat();
			format.font = "Arial";
			format.size = 12;
			format.color = 0xFFFFFF;
			menuFormat = format;
			_priorities[0] = "#000000";
			_priorities[1] = "#33AA33";
			_priorities[2] = "#77D077";
			_priorities[3] = "#AAEEAA";
			_priorities[4] = "#D6FFD6";
			_priorities[5] = "#FFFFFF";
			_priorities[6] = "#FFD6D6";
			_priorities[7] = "#FFAAAA";
			_priorities[8] = "#FF7777";
			_priorities[9] = "#FF3333";
			_priorities[10] = "#FF0000";
			_priorities[-1] = "#0099CC";
			_priorities[-2] = "#FF8800";
		}
		
		public function preset2():void{
			setbackgroundColour(1,1,1);
			backgroundAlpha = 0.8;
			backgroundBlendMode = "normal";
			var format:TextFormat = new TextFormat();
			format.font = "Arial";
			format.size = 12;
			format.color = 0;
			menuFormat = format;
			_priorities[0] = "#666666";
			_priorities[1] = "#44DD44";
			_priorities[2] = "#33AA33";
			_priorities[3] = "#227722";
			_priorities[4] = "#115511";
			_priorities[5] = "#000000";
			_priorities[6] = "#660000";
			_priorities[7] = "#990000";
			_priorities[8] = "#BB0000";
			_priorities[9] = "#DD0000";
			_priorities[10] = "#FF0000";
			_priorities[-1] = "#0099CC";
			_priorities[-2] = "#FF6600";
		}
		
		//
		public function setbackgroundColour(r:Number,g:Number,b:Number):void{
			_background.transform.colorTransform = new ColorTransform(r,g,b);
			_commandBackground.transform.colorTransform = new ColorTransform(r,g,b);
		}
		public function get backgroundColour():ColorTransform{
			return _background.transform.colorTransform;
		}
		public function set backgroundAlpha(newA:Number):void{
			_background.alpha = newA;
			_commandBackground.alpha = newA*0.8;
		}
		public function get backgroundAlpha():Number{
			return _background.alpha;
		}
		public function set backgroundBlendMode(newS:String):void{
			_background.blendMode = newS;
		}
		public function get backgroundBlendMode():String{
			return _background.blendMode;
		}
		public function set backgroundFilters(newF:Array):void{
			_background.filters = newF;
		}
		public function get backgroundFilters():Array{
			return _background.filters;
		}
		//
		//
		public function set menuFormat(newFormat:TextFormat):void{
			_menuField.defaultTextFormat = newFormat;
			_commandField.defaultTextFormat = newFormat;
		}
		
		public function setPriorityHex(id:int,col:String):void{
			_priorities[id] = "#"+col;
		}
		public function getPriorityHex(pri:int):String{
			if(_priorities[pri]){
				return _priorities[pri];
			}else{
				return _priorities[0];
			}
		}
	}
}