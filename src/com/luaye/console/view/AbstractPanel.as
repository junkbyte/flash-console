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
	import flash.events.TextEvent;

	import com.luaye.console.Console;

	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class AbstractPanel extends Sprite {
		
		public static const STARTED_DRAGGING:String = "startedDragging";
		public static const STARTED_SCALING:String = "startedScaling";
		
		//event might be clearer to have it independent...
		//[Event(name="textLinkEvent", type="flash.events.TextEvent")]
		public static const TEXT_LINK:String = "textLinkEvent";
		
		private var _snaps:Array;
		private var _dragOffset:Point;
		private var _resizeTxt:TextField;
		
		protected var master:Console;
		protected var style:Style;
		protected var bg:Sprite;
		protected var scaler:Sprite;
		protected var minimumWidth:int = 18;
		protected var minimumHeight:int = 18;
		
		public var moveable:Boolean = true;
		public var snapping:uint = 3;
		
		public function AbstractPanel(m:Console) {
			master = m;
			style = master.style;
			bg = new Sprite();
			bg.name = "background";
			addChild(bg);
		}
		protected function drawBG(col:Number = 0, a:Number = 0.6, rounding:int = 10):void{
			bg.graphics.clear();
			bg.graphics.beginFill(col, a);
			var size:int = 100;
			var roundSize:int = 100-(rounding*2);
			bg.graphics.drawRoundRect(0, 0, size, size,rounding,rounding);
			var grid:Rectangle = new Rectangle(rounding, rounding, roundSize, roundSize);
			bg.scale9Grid = grid;
		}
		public function init(w:Number,h:Number,resizable:Boolean = false, col:Number = -1, a:Number = -1, rounding:int = 10):void{
			drawBG(col>=0?col:style.panelBackgroundColor, a>=0?a:style.panelBackgroundAlpha, rounding);
			scalable = resizable;
			width = w;
			height = h;
		}
		public function close():void {
			stopDragging();
			master.panels.tooltip();
			if(parent){
				parent.removeChild(this);
			}
			//dispatchEvent(new Event(CLOSED));
		}
		//
		// SIZE
		//
		override public function set width(n:Number):void{
			if(n < minimumWidth) n = minimumWidth;
			if(scaler) scaler.x = n;
			bg.width = n;
		}
		override public function set height(n:Number):void{
			if(n < minimumHeight) n = minimumHeight;
			if(scaler) scaler.y = n;
			bg.height = n;
		}
		override public function get width():Number{
			return bg.width;
		}
		override public function get height():Number{
			return bg.height;
		}
		//
		// MOVING
		//
		public function registerSnaps(X:Array, Y:Array):void{
			_snaps = [X,Y];
		}
		protected function registerDragger(mc:DisplayObject, dereg:Boolean = false):void{
			if(dereg){
				mc.removeEventListener(MouseEvent.MOUSE_DOWN, onDraggerMouseDown);
			}else{
				mc.addEventListener(MouseEvent.MOUSE_DOWN, onDraggerMouseDown, false, 0, true);
			}
		}
		private function onDraggerMouseDown(e:MouseEvent):void{
			if(!stage || !moveable) return;
			//
			_resizeTxt = new TextField();
			_resizeTxt.name = "positioningField";
			_resizeTxt.autoSize = TextFieldAutoSize.LEFT;
           	formatText(_resizeTxt);
			addChild(_resizeTxt);
			updateDragText();
			//
			_dragOffset = new Point(mouseX,mouseY); // using this way instead of startDrag, so that it can control snapping.
			_snaps = [[],[]];
			dispatchEvent(new Event(STARTED_DRAGGING));
			stage.addEventListener(MouseEvent.MOUSE_UP, onDraggerMouseUp, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onDraggerMouseMove, false, 0, true);
		}
		private function onDraggerMouseMove(e:MouseEvent = null):void{
			if(snapping==0) return;
			// YEE HA, SNAPPING!
			var p:Point = returnSnappedFor(parent.mouseX-_dragOffset.x, parent.mouseY-_dragOffset.y);
			x = p.x;
			y = p.y;
			updateDragText();
		}
		private function updateDragText():void{
			_resizeTxt.text = "<s>"+x+","+y+"</s>";
		}
		private function onDraggerMouseUp(e:MouseEvent):void{
			stopDragging();
		}
		private function stopDragging():void{
			_snaps = null;
			if(stage){
				stage.removeEventListener(MouseEvent.MOUSE_UP, onDraggerMouseUp);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDraggerMouseMove);
			}
			if(_resizeTxt && _resizeTxt.parent){
				_resizeTxt.parent.removeChild(_resizeTxt);
			}
			_resizeTxt = null;
		}
		//
		// SCALING
		//
		public function get scalable():Boolean{
			return scaler?true:false;
		}
		public function set scalable(b:Boolean):void{
			if(b && !scaler){
				scaler = new Sprite();
				scaler.name = "scaler";
				scaler.graphics.beginFill(style.panelScalerColor, style.panelBackgroundAlpha);
	            scaler.graphics.lineTo(-10, 0);
	            scaler.graphics.lineTo(0, -10);
	            scaler.graphics.endFill();
				scaler.buttonMode = true;
				scaler.doubleClickEnabled = true;
				scaler.addEventListener(MouseEvent.MOUSE_DOWN,onScalerMouseDown, false, 0, true);
	            addChild(scaler);
			}else if(!b && scaler){
				if(contains(scaler)){
					removeChild(scaler);
				}
				scaler = null;
			}
		}
		private function onScalerMouseDown(e:Event):void{
			_resizeTxt = new TextField();
			_resizeTxt.name = "resizingField";
			_resizeTxt.autoSize = TextFieldAutoSize.RIGHT;
			_resizeTxt.x = -4;
			_resizeTxt.y = -17;
           	formatText(_resizeTxt);
			scaler.addChild(_resizeTxt);
			updateScaleText();
			_dragOffset = new Point(scaler.mouseX,scaler.mouseY); // using this way instead of startDrag, so that it can control snapping.
			_snaps = [[],[]];
			scaler.stage.addEventListener(MouseEvent.MOUSE_UP,onScalerMouseUp, false, 0, true);
			scaler.stage.addEventListener(MouseEvent.MOUSE_MOVE,updateScale, false, 0, true);
			dispatchEvent(new Event(STARTED_SCALING));
		}
		private function updateScale(e:Event = null):void{
			var p:Point = returnSnappedFor(x+mouseX-_dragOffset.x, y+mouseY-_dragOffset.x);
			p.x-=x;
			p.y-=y;
			width = p.x<minimumWidth?minimumWidth:p.x;
			height = p.y<minimumHeight?minimumHeight:p.y;
			updateScaleText();
		}
		private function updateScaleText():void{
			_resizeTxt.text = "<s>"+width+","+height+"</s>";
		}
		public function stopScaling():void{
			onScalerMouseUp(null);
		}
		private function onScalerMouseUp(e:Event):void{
			scaler.stage.removeEventListener(MouseEvent.MOUSE_UP,onScalerMouseUp);
			scaler.stage.removeEventListener(MouseEvent.MOUSE_MOVE,updateScale);
			updateScale();
			_snaps = null;
			if(_resizeTxt && _resizeTxt.parent){
				_resizeTxt.parent.removeChild(_resizeTxt);
			}
			_resizeTxt = null;
		}
		//
		//
		//
		private function formatText(txt:TextField):void{
            txt.background = true;
            txt.backgroundColor = style.panelBackgroundColor;
			txt.styleSheet = style.css;
			txt.mouseEnabled = false;
		}
		private function returnSnappedFor(X:Number,Y:Number):Point{
			var ex:Number = X+width;
			var Xs:Array = _snaps[0];
			for each(var Xi:Number in Xs){
				if(Math.abs(Xi-X)<snapping){
					X = Xi;
					break;
				}
				if(Math.abs(Xi-ex)<snapping){
					X = Xi-width;
					break;
				}
			}
			var ey:Number = Y+height;
			var Ys:Array = _snaps[1];
			for each(var Yi:Number in Ys){
				if(Math.abs(Yi-Y)<snapping){
					Y = Yi;
					break;
				}
				if(Math.abs(Yi-ey)<snapping){
					Y = Yi-height;
					break;
				}
			}
			return new Point(X,Y);
		}
		
		public static function registerRollOverTextField(field:TextField):void{
			field.addEventListener(MouseEvent.MOUSE_MOVE, onTextFieldMouseMove, false, 0, true);
			field.addEventListener(MouseEvent.ROLL_OUT, onTextFieldMouseMove, false, 0, true);
		}
		private static function onTextFieldMouseMove(e:MouseEvent):void{
			var field:TextField = e.currentTarget as TextField;
			if(!field.stage || !field.visible || (field.parent && !field.parent.visible)) {
				// this can happen if you removed it while rolled over and roll out calls on next move	
				field.dispatchEvent(new TextEvent(TEXT_LINK));
				return;
			}
			var index:int;
			if(field.scrollH>0){
				// kinda a hack really :(
				var scrollH:Number = field.scrollH;
				var w:Number = field.width;
				field.width = w+scrollH;
				index = field.getCharIndexAtPoint(field.mouseX+scrollH, field.mouseY);
				field.width = w;
				field.scrollH = scrollH;
			}else{
				index = field.getCharIndexAtPoint(field.mouseX, field.mouseY);
			}
			var url:String = null;
			var txt:String = null;
			if(index>0){
				// TextField.getXMLText(...) is not documented
				var X:XML = new XML(field.getXMLText(index,index+1));
				if(X.hasOwnProperty("textformat")){
					var txtformat:XML = X["textformat"][0] as XML;
					if(txtformat){
						url = txtformat.@url;
						txt = txtformat.toString();
					}
				}
			}
			field.dispatchEvent(new TextEvent(TEXT_LINK,false,false,url));
		}
	}
}