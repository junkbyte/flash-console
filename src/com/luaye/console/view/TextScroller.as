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
	import flash.geom.Rectangle;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.display.Sprite;

	public class TextScroller extends Sprite {
		
		public static const SCROLL_INCREMENT:String = "SCROLL_INCREMENT";
		public static const STARTED_SCROLLING:String = "STARTED_SCROLLING";
		public static const SCROLLED:String = "SCROLL";
		public static const STOPPED_SCROLLING:String = "STOPPED_SCROLLING";
		
		private var _scroller:Sprite;
		private var _scrolldelay:uint;
		private var _scrolldir:int;
		private var _field:TextField;
		private var _h:Number = 100;
		private var _scrolling:Boolean;
		
		private var _color:Number = 0xFF0000;
		
		public var targetIncrement:Number;
		
		public function TextScroller(target:TextField = null, color:Number = 0xFF0000) {
			_field = target;
			if(_field != null) _field.addEventListener(Event.SCROLL, onFieldScroll, false, 0, true);
			_color = color;
			name = "scroller";
			buttonMode = true;
			addEventListener(MouseEvent.MOUSE_DOWN, onScrollbarDown, false, 0, true);
			//
			_scroller = new Sprite();
			_scroller.name = "scrollbar";
			_scroller.y = 5;
			_scroller.graphics.beginFill(_color, 1);
			_scroller.graphics.drawRect(-5, 0, 5, 30);
			_scroller.graphics.beginFill(0, 0);
			_scroller.graphics.drawRect(-10, 0, 10, 30);
			_scroller.graphics.endFill();
			_scroller.buttonMode = true;
			_scroller.addEventListener(MouseEvent.MOUSE_DOWN, onScrollerDown, false, 0, true);
			addChild(_scroller);
		}
		public override function set height(n:Number):void{
			_h = n;
			_scroller.visible = _h>40;
			graphics.clear();
			if(_h>=10){
				graphics.beginFill(_color, 0.7);
				graphics.drawRect(-5, 0, 5, 5);
				graphics.drawRect(-5, n-5, 5, 5);
				graphics.beginFill(_color, 0.25);
				graphics.drawRect(-5, 5, 5, n-10);
				graphics.endFill();
			}
		}
		private function onFieldScroll(e:Event):void{
			if(_scrolling) return;
			if(_field.maxScrollV<=1 || _h<10){
				visible = false;
			}else{
				visible = true;
				scrollPercent = (_field.scrollV-1)/(_field.maxScrollV-1);
			}
		}
		public function get scrollPercent():Number{
			return (_scroller.y-5)/(_h-40);
		}
		public function set scrollPercent(per:Number):void{
			_scroller.y = 5+((_h-40)*per);
		}
		private function incScroll(i:int):void{
			if(_field == null) {
				targetIncrement = i;
				dispatchEvent(new Event(SCROLL_INCREMENT));
			}
			else _field.scrollV += i;
		}
		private function onScrollbarDown(e:MouseEvent):void{
			if((_scroller.visible && _scroller.mouseY>0) || (!_scroller.visible && mouseY>_h/2)) {
				incScroll(3);
				_scrolldir = 3;
			}else {
				incScroll(-3);
				_scrolldir = -3;
			}
			_scrolldelay = 0;
			addEventListener(Event.ENTER_FRAME, onScrollBarFrame, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, onScrollBarUp, false, 0, true);
		}
		private function onScrollBarFrame(e:Event):void{
			_scrolldelay++;
			if(_scrolldelay>10){
				_scrolldelay = 9;
				if((_scrolldir<0 && _scroller.y>mouseY)||(_scrolldir>0 && _scroller.y+_scroller.height<mouseY)){
					incScroll(_scrolldir);
				}
			}
		}
		private function onScrollBarUp(e:Event):void{
			removeEventListener(Event.ENTER_FRAME, onScrollBarFrame);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onScrollBarUp);
		}
		//
		//
		private function onScrollerDown(e:MouseEvent):void{
			_scrolling = true;
			dispatchEvent(new Event(STARTED_SCROLLING));
			_scroller.startDrag(false, new Rectangle(0,5, 0, (_h-40)));
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onScrollerMove, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, onScrollerUp, false, 0, true);
			e.stopPropagation();
		}
		private function onScrollerMove(e:MouseEvent):void{
			if(_field==null){
				dispatchEvent(new Event(SCROLLED));
			}else {
				_field.scrollV = Math.round((scrollPercent*(_field.maxScrollV-1))+1);
			}
		}
		private function onScrollerUp(e:MouseEvent):void{
			_scroller.stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onScrollerMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onScrollerUp);
			_scrolling = false;
			dispatchEvent(new Event(STOPPED_SCROLLING));
		}
	}
}
