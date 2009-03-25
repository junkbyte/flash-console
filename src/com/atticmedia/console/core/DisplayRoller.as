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
	import flash.utils.Dictionary;	
	import flash.utils.getQualifiedClassName;	
	import flash.display.DisplayObjectContainer;	
	import flash.display.DisplayObject;	
	import flash.text.TextFormat;	
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
		
		private var _txtField:TextField;
		private var _base:DisplayObjectContainer;
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
			
			_txtField = new TextField();
			_txtField.name = "rollerprints";
			_txtField.background  = false;
			_txtField.multiline = true;
			_txtField.autoSize = TextFieldAutoSize.LEFT;
			_txtField.selectable = false;
			_txtField.defaultTextFormat = new TextFormat("Arial", 11, 0xDD5500);
			_txtField.addEventListener(MouseEvent.MOUSE_DOWN, onFieldMouseDown, false, 0, true);
			addChild(_txtField);
		}
		private function onFieldMouseDown(e:MouseEvent):void{
			startDrag();
			stage.addEventListener(MouseEvent.MOUSE_UP, onFieldMouseUp, false, 0, true);
		}
		private function onFieldMouseUp(e:MouseEvent):void{
			stage.removeEventListener(MouseEvent.MOUSE_UP, onFieldMouseUp);
			stopDrag();
		}
		public function start(base:DisplayObjectContainer):void{
			_base = base;
			addEventListener(Event.ENTER_FRAME, _onFrame, false, 0, true);
		}
		
		private function _onFrame(e:Event):void{
			if(!_base || !_base.stage){
				exit();
				return;
			}
			var str:String = "";
			var objs:Array = _base.getObjectsUnderPoint(new Point(_base.mouseX, _base.mouseY));
			//
			// TODO: need to make it work 'better' and 'properly'...
			//
			var stepMap:Dictionary = new Dictionary(true);
			for each(var child:DisplayObject in objs){
				var chain:Array = new Array(child);
				var par:DisplayObjectContainer = child.parent;
				while(par){
					chain.unshift(par);
					par = par.parent;
				}
				var len:uint = chain.length;
				for (var i:uint=0; i<len; i++){
					var obj:DisplayObject = chain[i];
					if(stepMap[obj] == undefined){
						stepMap[obj] = i;
						for(var j:uint = i;j>0;j--){
							str += j==1?" ∟":" -";
						}
						if(i == len-1){
							str +=  "<b>"+obj.name+"("+getQualifiedClassName(obj).split("::").pop()+")</b><br/>";
						}else{
							str +=  "<i>"+obj.name+"("+getQualifiedClassName(obj).split("::").pop()+")</i><br/>";
						}
					}
				}
			}
			_txtField.htmlText = str;
			_txtField.autoSize = TextFieldAutoSize.LEFT;
			_bg.width = _txtField.width+4;
			_bg.height = _txtField.height;
		}
		
		public function exit():void{
			removeEventListener(Event.ENTER_FRAME, _onFrame);
			_base = null;
			dispatchEvent(new Event(EXIT));
		}
	}
}