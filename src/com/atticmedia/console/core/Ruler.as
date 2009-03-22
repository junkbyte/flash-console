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
	import flash.display.Graphics;	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;		

	public class Ruler extends Sprite{
		
		public static const NAME:String = "ruler";
		public static const EXIT:String = "exit";
		
		private var _reportFunction:Function;
		private var _area:Rectangle;
		
		private var _points:Array;
		
		public function Ruler() {
			name = NAME;
		}
		public function start(reportFunction:Function = null):void{
			_reportFunction = reportFunction;
			buttonMode = true;
			_points = new Array();
			var p:Point = new Point();
			p = globalToLocal(p);
			_area = new Rectangle(-stage.stageWidth*1.5+p.x, -stage.stageHeight*1.5+p.y, stage.stageWidth*3, stage.stageHeight*3);
			graphics.beginFill(0x000000, 0.2);
			graphics.drawRect(_area.x, _area.y, _area.width, _area.height);
			graphics.endFill();
			addEventListener(MouseEvent.CLICK, onMouseClick, false, 0, true);
		}
		private function onMouseClick(e:MouseEvent):void{
			e.stopPropagation();
			var p:Point;
			if(_points.length==0){
				p = new Point(e.localX, e.localY);
				graphics.lineStyle(1, 0xFF0000);
				graphics.drawCircle(p.x, p.y, 3);
				_points.push(p);
			}else if(_points.length==1){
				p = _points[0];
				var p2:Point =  new Point(e.localX, e.localY);
				_points.push(p2);
				graphics.clear();
				graphics.beginFill(0x000000, 0.4);
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
				var txt:TextField = makeTxtField();
				txt.text = Utils.round(p.x,10)+","+ Utils.round(p.y,10);
				txt.x = p.x;
				txt.y = p.y-(ymin==p?14:0);
				addChild(txt);
				//
				txt = makeTxtField();
				txt.text = Utils.round(p2.x,10)+","+ Utils.round(p2.y,10);
				txt.x = p2.x;
				txt.y = p2.y-(ymin==p2?14:0);;
				addChild(txt);
				//
				if(w>40 || h>25){
					txt = makeTxtField(0x00AA00);
					txt.text = Utils.round(mp.x,10)+","+ Utils.round(mp.y,10);
					txt.x = mp.x;
					txt.y = mp.y;
					addChild(txt);
					/*
					txt = makeTxtField(0x00AA00, false);
					txt.text = xmin.x+","+ ymin.y;
					txt.x = xmin.x;
					txt.y = (xmin.y==ymin.y)?ymax.y:(ymin.y-14);
					addChild(txt);
					//
					txt = makeTxtField(0x00AA00, false);
					txt.text = xmax.x+","+ ymax.y;
					txt.x = xmax.x;
					txt.y = (xmax.y==ymax.y)?(ymin.y-14):ymax.y;
					addChild(txt);
					*/
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
				var a1:Number = Utils.round(Utils.angle(p,p2),100);
				var a2:Number = Utils.round(Utils.angle(p2,p),100);
				graphics.lineStyle(1, 0xAA0000, 0.8);
				Utils.drawCircleSegment(graphics, 10,p, a1, -90);
				graphics.lineStyle(1, 0xCC8800, 0.8);
				Utils.drawCircleSegment(graphics, 10,p2, a2, -90);
				//
				graphics.lineStyle(2, 0x00FF00, 0.7);
				graphics.moveTo(p.x, p.y);
				graphics.lineTo(p2.x, p2.y);
				//
				report("Ruler results: (red) <b>["+p.x+","+p.y+"]</b> to (orange) <b>["+p2.x+","+p2.y+"]</b>", -2);
				report("Distance: <b>"+Utils.round(d,100) +"</b>", -2);
				report("Mid point: <b>["+mp.x+","+mp.y+"]</b>", -2);
				report("Width:<b>"+w+"</b>, Height: <b>"+h+"</b>", -2);
				report("Angle from first point (red): <b>"+a1+"°</b>", -2);
				report("Angle from second point (orange): <b>"+a2+"°</b>", -2);
			}else{
				exit();
			}
		}
		public function exit():void{
			_points = null;
			_reportFunction = null;
			dispatchEvent(new Event(EXIT));
		}
		private function makeTxtField(col:Number = 0x00FF00, b:Boolean = true):TextField{
			var format:TextFormat = new TextFormat("Arial", 11, col, b, true, null, null, TextFormatAlign.RIGHT);
			var txt:TextField = new TextField();
			txt.autoSize = TextFieldAutoSize.RIGHT;
			txt.selectable = false;
        	txt.defaultTextFormat = format;
           	return txt;
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