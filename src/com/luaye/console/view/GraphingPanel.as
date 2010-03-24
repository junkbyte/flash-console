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
	import com.luaye.console.Console;
	import com.luaye.console.utils.Utils;

	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.TextEvent;
	import flash.text.TextField;

	public class GraphingPanel extends AbstractPanel {
		private var _interests:Array = [];
		private var _updatedFrame:uint = 0;
		private var _drawnFrame:uint = 0;
		private var _needRedraw:Boolean;
		private var _isRunning:Boolean;
		protected var _history:Array = [];
		//
		protected var fixed:Boolean;
		protected var underlay:Shape;
		protected var graph:Shape;
		protected var lowTxt:TextField;
		protected var highTxt:TextField;
		protected var keyTxt:TextField;
		//
		public var updateEvery:uint = 1;
		public var drawEvery:uint = 1;
		public var lowest:Number;
		public var highest:Number;
		public var averaging:uint;
		public var startOffset:int = 5;
		public var inverse:Boolean;
		//
		public function GraphingPanel(m:Console, W:int = 0, H:int = 0, resizable:Boolean = true) {
			super(m);
			registerDragger(bg);
			minimumHeight = 26;
			//
			lowTxt = new TextField();
			lowTxt.name = "lowestField";
			lowTxt.mouseEnabled = false;
			lowTxt.styleSheet = m.css;
			lowTxt.height = master.style.menuFontSize+2;
			addChild(lowTxt);
			highTxt = new TextField();
			highTxt.name = "highestField";
			highTxt.mouseEnabled = false;
			highTxt.styleSheet = m.css;
			highTxt.height = master.style.menuFontSize+2;
			highTxt.y = master.style.menuFontSize-4;
			addChild(highTxt);
			//
			keyTxt = new TextField();
			keyTxt.name = "menuField";
			keyTxt.styleSheet = m.css;
			keyTxt.height = m.style.menuFontSize+4;
			keyTxt.y = -3;
			keyTxt.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			registerRollOverTextField(keyTxt);
			keyTxt.addEventListener(AbstractPanel.TEXT_LINK, onMenuRollOver, false, 0, true);
			registerDragger(keyTxt); // so that we can still drag from textfield
			addChild(keyTxt);
			//
			underlay = new Shape();
			addChild(underlay);
			//
			graph = new Shape();
			graph.name = "graph";
			graph.y = m.style.menuFontSize;
			addChild(graph);
			//
			init(W?W:100,H?H:80,resizable);
		}
		
		public function get rand():Number{
			return Math.random();
		}
		public function add(obj:Object, prop:String, col:Number = -1, key:String=null):void{
			if(isNaN(col) || col<0) col = Math.random()*0xFFFFFF;
			if(key == null) key = prop;
			var i:Interest = new Interest(obj, prop, col, key);
			var cur:Number;
			try{
				cur = i.getValue();
				if(!isNaN(cur)){
					if(isNaN(lowest)) lowest = cur;
					if(isNaN(highest)) highest = cur;
				}
			}catch(e:Error){
				
			}
			_interests.push(i);
			updateKeyText();
			//
			start();
		}
		public function remove(obj:Object = null, prop:String = null):void{
			var all:Boolean = (obj==null&&prop==null);
			for(var i:int = _interests.length-1;i>=0;i--){
				var interest:Interest = _interests[i];
				if(all || (interest && (obj == null || interest.obj == obj) && (prop == null || interest.prop == prop))){
					_interests.splice(i, 1);
				}
			}
			if(_interests.length==0){
				close();
			}else{
				updateKeyText();
			}
		}
		/*public function mark(col:Number = -1, v:Number = NaN):void{
			if(_history.length==0) return;
			var interests:Array = _history[_history.length-1];
			interests.push([col, v]);
		}*/
		public function start():void{
			_isRunning = true;
			// Note that if it has already started, it won't add another listener on top.
			addEventListener(Event.ENTER_FRAME, onFrame, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, removeListeners);
		}
		public function stop():void {
			_isRunning = false;
			removeListeners();
		}
		private function removeListeners(e:Event=null):void{
			removeEventListener(Event.ENTER_FRAME, onFrame);
			removeEventListener(Event.REMOVED_FROM_STAGE, removeListeners);
		}
		public function get numInterests():int{
			return _interests.length;
		}
		override public function close():void {
			stop();
			super.close();
		}
		public function reset():void{
			if(!fixed){
				lowest = NaN;
				highest = NaN;
			}
			_history = [];
			graph.graphics.clear();
		}
		public function get running():Boolean {
			return _isRunning;
		}
		public function fixRange(low:Number,high:Number):void{
			if(isNaN(low) || isNaN(high)) {
				fixed = false;
				return;
			}
			fixed = true;
			lowest = low;
			highest = high;
		}
		public function set showKeyText(b:Boolean):void{
			keyTxt.visible = b;
		}
		public function get showKeyText():Boolean{
			return keyTxt.visible;
		}
		public function set showBoundsText(b:Boolean):void{
			lowTxt.visible = b;
			highTxt.visible = b;
		}
		public function get showBoundsText():Boolean{
			return lowTxt.visible;
		}
		override public function set height(n:Number):void{
			super.height = n;
			lowTxt.y = n-master.style.menuFontSize;
			_needRedraw = true;
			
			var g:Graphics = underlay.graphics;
			g.clear();
			g.lineStyle(1,master.style.controlColor, 0.6);
			g.moveTo(0, graph.y);
			g.lineTo(width-startOffset, graph.y);
			g.lineTo(width-startOffset, n);
		}
		override public function set width(n:Number):void{
			super.width = n;
			lowTxt.width = n;
			highTxt.width = n;
			keyTxt.width = n;
			keyTxt.scrollH = keyTxt.maxScrollH;
			_needRedraw = true;
			
		}
		protected function getCurrentOf(i:int):Number{
			var values:Array = _history[_history.length-1];
			return values?values[i]:0;
		}
		protected function getAverageOf(i:int):Number{
			var interest:Interest = _interests[i];
			return interest?interest.avg:0;
		}
		//
		//
		//
		protected function onFrame(e:Event):Boolean{
			var ok:Boolean = (master.visible && !master.paused);
			if(ok) {
				updateData();
			}
			if(ok || _needRedraw){
				drawGraph();
			}
			return ok;
		}
		protected function updateData():void{
			_updatedFrame++;
			if(_updatedFrame < updateEvery) return;
			_updatedFrame= 0;
			var values:Array = [];
			var v:Number;
			for each(var interest:Interest in _interests){
				try{
					v = interest.getValue();
					if(isNaN(v)){
						v = 0;
					}else{
						if(isNaN(lowest)) lowest = v;
						if(isNaN(highest)) highest = v;
					}
					values.push(v);
					if(averaging>0){
						var avg:Number = interest.avg;
						if(isNaN(avg)) {
							interest.avg = v;
						}else{
							interest.avg = Utils.averageOut(avg, v, averaging);
						}
					}
					if(!fixed){
						if(v > highest) highest = v;
						if(v < lowest) lowest = v;
					}
				}catch(e:Error){
					remove(interest.obj, interest.prop);
				}
			}
			_history.push(values);
			// clean up off screen data
			var maxLen:int = Math.floor(width)+10;
			var len:uint = _history.length;
			if(len > maxLen){
				_history.splice(0, (len-maxLen));
			}
		}
		public function drawGraph():void{
			_drawnFrame++;
			if(!_needRedraw && _drawnFrame < drawEvery) return;
			_needRedraw = false;
			_drawnFrame= 0;
			var W:Number = width-startOffset;
			var H:Number = height-graph.y;
			graph.graphics.clear();
			var diffGraph:Number = highest-lowest;
			var numInterests:int = _interests.length;
			var len:int = _history.length;
			for(var j:int = 0;j<numInterests;j++){
				var interest:Interest = _interests[j];
				var first:Boolean = true;
				for(var i:int = 1;i<W;i++){
					if(len < i) break;
					var values:Array = _history[len-i];
					if(first){
						graph.graphics.lineStyle(1,interest.col);
					}
					var Y:Number = (diffGraph?((values[j]-lowest)/diffGraph):0.5)*H;
					if(!inverse) Y = H-Y;
					if(Y<0)Y=0;
					if(Y>H)Y=H;
					if(first){
						graph.graphics.moveTo(width, Y);
						graph.graphics.lineTo((W-i), Y);
					}else{
						graph.graphics.lineTo((W-i), Y);
					}
					first = false;
				}
				if(averaging>0 && diffGraph){
					Y = ((interest.avg-lowest)/diffGraph)*H;
					if(!inverse) Y = H-Y;
					if(Y<-1)Y=-1;
					if(Y>H)Y=H+1;
					graph.graphics.lineStyle(1,interest.col, 0.3);
					graph.graphics.moveTo(0, Y);
					graph.graphics.lineTo(W, Y);
				}
			}
			(inverse?highTxt:lowTxt).text = isNaN(lowest)?"":"<s>"+lowest+"</s>";
			(inverse?lowTxt:highTxt).text = isNaN(highest)?"":"<s>"+highest+"</s>";
		}
		public function updateKeyText():void{
			var str:String = "<r><s>";
			for each(var interest:Interest in _interests){
				str += " <font color='#"+interest.col.toString(16)+"'>"+interest.key+"</font>";
			}
			str +=  " | <menu><a href=\"event:reset\">R</a> <a href=\"event:close\">X</a></menu></s></r>";
			keyTxt.htmlText = str;
			keyTxt.scrollH = keyTxt.maxScrollH;
		}
		protected function linkHandler(e:TextEvent):void{
			TextField(e.currentTarget).setSelection(0, 0);
			if(e.text == "reset"){
				reset();
			}else if(e.text == "close"){
				close();
			}
			e.stopPropagation();
		}
		protected function onMenuRollOver(e:TextEvent):void{
			master.panels.tooltip(e.text?e.text.replace("event:",""):null, this);
		}
	}
}

import com.luaye.console.core.Executer;
import com.luaye.console.utils.WeakRef;

class Interest{
	private var _ref:WeakRef;
	public var prop:String;
	public var col:Number;
	public var key:String;
	public var avg:Number;
	private var useExec:Boolean;
	public function Interest(object:Object, property:String, color:Number, keystr:String):void{
		_ref = new WeakRef(object);
		prop = property;
		col = color;
		key = keystr;
		useExec = prop.search(/[^\w\d]/) >= 0;
	}
	public function getValue():Number{
		return useExec?Executer.Exec(obj, prop):obj[prop];
	}
	public function get obj():Object{
		return _ref.reference;
	}
}