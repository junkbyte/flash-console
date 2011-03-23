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
	import flash.geom.Matrix;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import com.junkbyte.console.ConsoleConfig;	
	import com.junkbyte.console.ConsoleStyle;	
	import com.junkbyte.console.Console;
	
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Mouse;		

	public class Ruler extends Sprite{
		
		private var _master:Console;
		private var _config : ConsoleConfig;

		private var _area:Rectangle;
		private var _pointer:Shape;
		
		private var _posTxt:TextField;
		private var _zoom:Bitmap;
		
		private var _points:Array;
		
		public function Ruler(console:Console) {
			_master = console;
			_config = console.config;
			buttonMode = true;
			_points = new Array();
			_pointer = new Shape();
			addChild(_pointer);
			var p:Point = new Point();
			p = globalToLocal(p);
			_area = new Rectangle(-console.stage.stageWidth*1.5+p.x, -console.stage.stageHeight*1.5+p.y, console.stage.stageWidth*3, console.stage.stageHeight*3);
			graphics.beginFill(_config.style.backgroundColor, 0.2);
			graphics.drawRect(_area.x, _area.y, _area.width, _area.height);
			graphics.endFill();
			//
			_posTxt = _master.panels.mainPanel.makeTF("positionText", true);
			_posTxt.autoSize = TextFieldAutoSize.LEFT;
			addChild(_posTxt);
			//
			_zoom = new Bitmap();
			_zoom.scaleY = _zoom.scaleX = 2;
			addChild(_zoom);
			//
			addEventListener(MouseEvent.CLICK, onMouseClick, false, 0, true);
			addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
			onMouseMove();
			if(_config.rulerHidesMouse) Mouse.hide();
			_master.report("<b>Ruler started. Click on two locations to measure.</b>", -1);
		}
		private function onMouseMove(e:MouseEvent = null):void{
			_pointer.graphics.clear();
			_pointer.graphics.lineStyle(1, 0xAACC00, 1);
			_pointer.graphics.moveTo(_area.x, mouseY);
			_pointer.graphics.lineTo(_area.x+_area.width, mouseY);
			_pointer.graphics.moveTo(mouseX, _area.y);
			_pointer.graphics.lineTo(mouseX, _area.y+_area.height);
			_pointer.blendMode = BlendMode.INVERT;
			_posTxt.text = "<low>"+mouseX+","+mouseY+"</low>";
			//
			var bmd:BitmapData = new BitmapData(30, 30);
			try{
				var m:Matrix = new Matrix();
				m.tx = -stage.mouseX+15;
				m.ty = -stage.mouseY+15;
				bmd.draw(stage, m);
			}catch(err:Error){
				bmd = null;
			}
			_zoom.bitmapData = bmd;
			//
			var d:int = 10;
			_posTxt.x = mouseX-_posTxt.width-d;
			_posTxt.y = mouseY-_posTxt.height-d;
			_zoom.x = _posTxt.x+_posTxt.width-_zoom.width;
			_zoom.y = _posTxt.y-_zoom.height;
			if(_posTxt.x < 16){
				_posTxt.x = mouseX+d;
				_zoom.x = _posTxt.x;
			}
			if(_posTxt.y < 38){
				_posTxt.y = mouseY+d;
				_zoom.y = _posTxt.y+_posTxt.height;
			}
		}
		private function onMouseClick(e:MouseEvent):void{
			e.stopPropagation();
			var p:Point;
			var style : ConsoleStyle = _config.style;
			if(_points.length==0){
				p = new Point(e.localX, e.localY);
				graphics.lineStyle(1, 0xFF0000);
				graphics.drawCircle(p.x, p.y, 3);
				_points.push(p);
			}else if(_points.length==1){
				_zoom.bitmapData = null;
				if(_config.rulerHidesMouse) Mouse.show();
				removeChild(_pointer);
				removeChild(_posTxt);
				removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				p = _points[0];
				var p2:Point =  new Point(e.localX, e.localY);
				_points.push(p2);
				graphics.clear();
				graphics.beginFill(style.backgroundColor, 0.4);
				graphics.drawRect(_area.x, _area.y, _area.width, _area.height);
				graphics.endFill();
				graphics.lineStyle(1.5, 0xFF0000);
				graphics.drawCircle(p.x, p.y, 4);
				graphics.lineStyle(1.5, 0xFF9900);
				graphics.drawCircle(p2.x, p2.y, 4);
				var mp:Point = Point.interpolate(p, p2, 0.5);
				graphics.lineStyle(1, 0xAAAAAA);
				graphics.drawCircle(mp.x, mp.y, 4);
				//
				var xmin:Point = p;
				var xmax:Point = p2;
				if(p.x>p2.x){
					xmin = p2;
					xmax = p;
				}
				var ymin:Point = p;
				var ymax:Point = p2;
				if(p.y>p2.y){
					ymin = p2;
					ymax = p;
				}
				//
				var w:Number = xmax.x-xmin.x;
				var h:Number = ymax.y-ymin.y;
				var d:Number = Point.distance(p, p2);
				//
				var txt:TextField = makeTxtField(style.highColor);
				txt.text = round(p.x)+","+ round(p.y);
				txt.x = p.x;
				txt.y = p.y-(ymin==p?14:0);
				addChild(txt);
				//
				txt = makeTxtField(style.highColor);
				txt.text = round(p2.x)+","+ round(p2.y);
				txt.x = p2.x;
				txt.y = p2.y-(ymin==p2?14:0);;
				addChild(txt);
				//
				if(w>40 || h>25){
					txt = makeTxtField(style.lowColor);
					txt.text = round(mp.x)+","+ round(mp.y);
					txt.x = mp.x;
					txt.y = mp.y;
					addChild(txt);
				}
				//
				graphics.lineStyle(1, 0xAACC00, 0.5);
				graphics.moveTo(_area.x, ymin.y);
				graphics.lineTo(_area.x+_area.width, ymin.y);
				graphics.moveTo(_area.x, ymax.y);
				graphics.lineTo(_area.x+_area.width, ymax.y);
				graphics.moveTo(xmin.x, _area.y);
				graphics.lineTo(xmin.x, _area.y+_area.height);
				graphics.moveTo(xmax.x, _area.y);
				graphics.lineTo(xmax.x, _area.y+_area.height);
				//
				var a1:Number = round(angle(p,p2),100);
				var a2:Number = round(angle(p2,p),100);
				graphics.lineStyle(1, 0xAA0000, 0.8);
				drawCircleSegment(graphics, 10,p, a1, -90);
				graphics.lineStyle(1, 0xCC8800, 0.8);
				drawCircleSegment(graphics, 10,p2, a2, -90);
				//
				graphics.lineStyle(2, 0x00FF00, 0.7);
				graphics.moveTo(p.x, p.y);
				graphics.lineTo(p2.x, p2.y);
				//
				_master.report("Ruler results: (red) <b>["+p.x+","+p.y+"]</b> to (orange) <b>["+p2.x+","+p2.y+"]</b>", -2);
				_master.report("Distance: <b>"+round(d,100) +"</b>", -2);
				_master.report("Mid point: <b>["+mp.x+","+mp.y+"]</b>", -2);
				_master.report("Width:<b>"+w+"</b>, Height: <b>"+h+"</b>", -2);
				_master.report("Angle from first point (red): <b>"+a1+"°</b>", -2);
				_master.report("Angle from second point (orange): <b>"+a2+"°</b>", -2);
			}else{
				exit();
			}
		}
		public function exit():void{
			_master = null;
			dispatchEvent(new Event(Event.COMPLETE));
		}
		private function makeTxtField(col:Number, b:Boolean = true):TextField{
			var format:TextFormat = new TextFormat(_config.style.menuFont, _config.style.menuFontSize, col, b, true, null, null, TextFormatAlign.RIGHT);
			var txt:TextField = new TextField();
			txt.autoSize = TextFieldAutoSize.RIGHT;
			txt.selectable = false;
        	txt.defaultTextFormat = format;
           	return txt;
		}
		
		
		private function round(n:Number, d:uint = 10):Number{
			return Math.round(n*d)/d;
		}
		private function angle(srcP:Point, point:Point):Number {
			var a:Number = Math.atan2(point.y - srcP.y , point.x - srcP.x)/Math.PI * 180;
			a +=90;
			if(a>180) a -= 360;
			return a;
		}
		private function drawCircleSegment(g : Graphics,radius :Number,pos:Point, deg:Number = 180, startDeg:Number = 0):Point
		{
			var reversed:Boolean = false;
			if(deg<0){
				reversed = true;
				deg = Math.abs(deg);
			}
			var rad:Number = (deg*Math.PI)/180;
			var rad2:Number = (startDeg*Math.PI)/180;
			var p:Point = getPointOnCircle(radius, rad2);
			p.offset(pos.x,pos.y);
			g.moveTo(p.x,p.y);
			var pra:Number = 0;
			for (var i:int = 1; i<=(rad+1); i++) {
				var ra:Number = i<=rad?i:rad;
				var diffr:Number = ra-pra;
				var offr:Number = 1+(0.12*diffr*diffr);
				var ap:Point = getPointOnCircle(radius*offr, ((ra-(diffr/2))*(reversed?-1:1))+rad2);
				ap.offset(pos.x,pos.y);
				p = getPointOnCircle(radius, (ra*(reversed?-1:1))+rad2);
				p.offset(pos.x,pos.y);
				g.curveTo(ap.x,ap.y, p.x,p.y);
				pra = ra;
			}
			return p;
		}
		private function getPointOnCircle(radius:Number, rad:Number):Point {
			return new Point(radius * Math.cos(rad),radius * Math.sin(rad));
		}
		
		
		
	}
}