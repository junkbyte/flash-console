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
	import com.junkbyte.console.ConsoleStyle;	
	import com.junkbyte.console.ConsoleConfig;

	import flash.events.TextEvent;

	import com.junkbyte.console.Console;

	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	/**
	 * Dispatched when dragging / moving started
	 */
	[Event(name="draggingStarted", type="flash.events.Event")]
	/**
	 * Dispatched when dragging / moving stopped
	 */
	[Event(name="draggingEnded", type="flash.events.Event")]
	
	/**
	 * Dispatched when scaling panel started
	 */
	[Event(name="scalingStarted", type="flash.events.Event")]
	/**
	 * Dispatched when scaling panel stopped
	 */
	[Event(name="scalingEnded", type="flash.events.Event")]
	
	/**
	 * Dispatched when visible property is set
	 */
	[Event(name="visibilityChanged", type="flash.events.Event")]
	
	/**
	 * Dispatched when started dragging
	 */
	[Event(name="close", type="flash.events.Event")]
	
	public class ConsolePanel extends Sprite {
		
		public static const DRAGGING_STARTED:String = "draggingStarted";
		public static const DRAGGING_ENDED:String = "draggingEnded";
		
		public static const SCALING_STARTED:String = "scalingStarted";
		public static const SCALING_ENDED:String = "scalingEnded";
		
		public static const VISIBLITY_CHANGED:String = "visibilityChanged";
		
		//[Event(name="TEXT_ROLL", type="flash.events.TextEvent")]
		private static const TEXT_ROLL:String = "TEXT_ROLL";
		
		private var _snaps:Array;
		private var _dragOffset:Point;
		
		private var _resizeTxt:TextField;
		//
		protected var console:Console;
		protected var bg:Sprite;
		protected var scaler:Sprite;
		protected var txtField:TextField;
		protected var minWidth:int = 18;
		protected var minHeight:int = 18;
		
		private var _movedFrom:Point;
		/**
		 * Specifies whether this panel can be moved from GUI.
		 */
		public var moveable:Boolean = true;
		
		public function ConsolePanel(m:Console) {
			console = m;
			bg = new Sprite();
			bg.name = "background";
			addChild(bg);
		}
		
		protected function get config() : ConsoleConfig {
			return console.config;
		}
		
		protected function get style() : ConsoleStyle {
			return console.config.style;
		}
		
		protected function init(w:Number,h:Number,resizable:Boolean = false, col:Number = -1, a:Number = -1, rounding:int = -1):void{
			
			bg.graphics.clear();
			bg.graphics.beginFill(col>=0?col:style.backgroundColor, a>=0?a:style.backgroundAlpha);
			if(rounding < 0) rounding = style.roundBorder;
			if(rounding <= 0) bg.graphics.drawRect(0, 0, 100, 100);
			else {
				bg.graphics.drawRoundRect(0, 0, rounding+10, rounding+10, rounding, rounding);
				bg.scale9Grid = new Rectangle(rounding*0.5, rounding*0.5, 10, 10);
			}
			
			scalable = resizable;
			width = w;
			height = h;
		}
		
		/**
		 * Close / remove the panel.
		 */
		public function close():void {
			stopDragging();
			console.panels.tooltip();
			if(parent){
				parent.removeChild(this);
			}
			dispatchEvent(new Event(Event.CLOSE));
		}
		
		override public function set visible(b:Boolean):void
		{
			super.visible = b;
			dispatchEvent(new Event(VISIBLITY_CHANGED));
		}
		//
		// SIZE
		//
		override public function set width(n:Number):void{
			if(n < minWidth) n = minWidth;
			if(scaler) scaler.x = n;
			bg.width = n;
		}
		
		override public function set height(n:Number):void{
			if(n < minHeight) n = minHeight;
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
		/**
		 * @private
		 */
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
			_resizeTxt = makeTF("positioningField", true);
			_resizeTxt.mouseEnabled = false;
			_resizeTxt.autoSize = TextFieldAutoSize.LEFT;
			addChild(_resizeTxt);
			updateDragText();
			//
			_movedFrom = new Point(x, y);
			_dragOffset = new Point(mouseX,mouseY); // using this way instead of startDrag, so that it can control snapping.
			_snaps = [[],[]];
			dispatchEvent(new Event(DRAGGING_STARTED));
			stage.addEventListener(MouseEvent.MOUSE_UP, onDraggerMouseUp, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onDraggerMouseMove, false, 0, true);
		}
		private function onDraggerMouseMove(e:MouseEvent = null):void{
			if(style.panelSnapping==0) return;
			// YEE HA, SNAPPING!
			var p:Point = returnSnappedFor(parent.mouseX-_dragOffset.x, parent.mouseY-_dragOffset.y);
			x = p.x;
			y = p.y;
			updateDragText();
		}
		private function updateDragText():void{
			_resizeTxt.text = "<low>"+x+","+y+"</low>";
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
			dispatchEvent(new Event(DRAGGING_ENDED));
		}
		/**
		 * @private
		 */
		public function moveBackSafePosition():void{
			if(_movedFrom != null){
				// This will only work if stage size is not altered OR stage.align is top left
				if(x+width<10 || (stage && stage.stageWidth<x+10) || y+height<10 || (stage && stage.stageHeight<y+20)) {
					x = _movedFrom.x;
					y = _movedFrom.y;
				}
				_movedFrom = null;
			}
		}
		//
		// SCALING
		//
		/**
		 * Specifies whether this panel can be scaled from GUI.
		 */
		public function get scalable():Boolean{
			return scaler?true:false;
		}
		
		public function set scalable(b:Boolean):void{
			if(b && !scaler){
				var size:uint = 8+(style.controlSize*0.5);
				scaler = new Sprite();
				scaler.name = "scaler";
				scaler.graphics.beginFill(0, 0);
				scaler.graphics.drawRect(-size*1.5, -size*1.5, size*1.5, size*1.5);
	            scaler.graphics.endFill();
				scaler.graphics.beginFill(style.controlColor, style.backgroundAlpha);
	            scaler.graphics.moveTo(0, 0);
	            scaler.graphics.lineTo(-size, 0);
	            scaler.graphics.lineTo(0, -size);
	            scaler.graphics.endFill();
				scaler.buttonMode = true;
				scaler.doubleClickEnabled = true;
				scaler.addEventListener(MouseEvent.MOUSE_DOWN,onScalerMouseDown, false, 0, true);
	            addChildAt(scaler, getChildIndex(bg)+1);
			}else if(!b && scaler){
				if(contains(scaler)){
					removeChild(scaler);
				}
				scaler = null;
			}
		}
		
		private function onScalerMouseDown(e:Event):void{
			_resizeTxt = makeTF("resizingField", true);
			_resizeTxt.mouseEnabled = false;
			_resizeTxt.autoSize = TextFieldAutoSize.RIGHT;
			_resizeTxt.x = -4;
			_resizeTxt.y = -17;
			scaler.addChild(_resizeTxt);
			updateScaleText();
			_dragOffset = new Point(scaler.mouseX,scaler.mouseY); // using this way instead of startDrag, so that it can control snapping.
			_snaps = [[],[]];
			scaler.stage.addEventListener(MouseEvent.MOUSE_UP,onScalerMouseUp, false, 0, true);
			scaler.stage.addEventListener(MouseEvent.MOUSE_MOVE,updateScale, false, 0, true);
			dispatchEvent(new Event(SCALING_STARTED));
		}
		private function updateScale(e:Event = null):void{
			var p:Point = returnSnappedFor(x+mouseX-_dragOffset.x, y+mouseY-_dragOffset.x);
			p.x-=x;
			p.y-=y;
			width = p.x<minWidth?minWidth:p.x;
			height = p.y<minHeight?minHeight:p.y;
			updateScaleText();
		}
		private function updateScaleText():void{
			_resizeTxt.text = "<low>"+width+","+height+"</low>";
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
			dispatchEvent(new Event(SCALING_ENDED));
		}
		//
		//
		/**
		 * @private
		 */
		public function makeTF(n:String, back:Boolean = false):TextField
		{
			var txt:TextField = new TextField();
			txt.name = n;
			txt.styleSheet = style.styleSheet;
			if(back){
          	 	txt.background = true;
            	txt.backgroundColor = style.backgroundColor;
			}
			return txt;
		}
		//
		//
		private function returnSnappedFor(X:Number,Y:Number):Point{
			return new Point(getSnapOf(X, true),getSnapOf(Y, false));
		}
		private function getSnapOf(v:Number, isX:Boolean):Number{
			var end:Number = v+width;
			var a:Array = _snaps[isX?0:1];
			var s:int = style.panelSnapping;
			for each(var ii:Number in a){
				if(Math.abs(ii-v)<s) return ii;
				if(Math.abs(ii-end)<s) return ii-width;
			}
			return v;
		}
		
		protected function registerTFRoller(field:TextField, overhandle:Function, linkHandler:Function = null):void{
			field.addEventListener(MouseEvent.MOUSE_MOVE, onTextFieldMouseMove, false, 0, true);
			field.addEventListener(MouseEvent.ROLL_OUT, onTextFieldMouseOut, false, 0, true);
			field.addEventListener(TEXT_ROLL, overhandle, false, 0, true);
			if(linkHandler != null) field.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
		}
		
		private static function onTextFieldMouseOut(e:MouseEvent):void{
			TextField(e.currentTarget).dispatchEvent(new TextEvent(TEXT_ROLL));
		}
		private static function onTextFieldMouseMove(e:MouseEvent):void{
			var field:TextField = e.currentTarget as TextField;
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
			//var txt:String = null;
			if(index>0){
				// TextField.getXMLText(...) is not documented
				try{
					var X:XML = new XML(field.getXMLText(index,index+1));
					if(X.hasOwnProperty("textformat")){
						var txtformat:XML = X["textformat"][0] as XML;
						if(txtformat){
							url = txtformat.@url;
							//txt = txtformat.toString();
						}
					}
				}catch(err:Error){
					url = null;
				}
			}
			field.dispatchEvent(new TextEvent(TEXT_ROLL,false,false,url));
		}
	}
}