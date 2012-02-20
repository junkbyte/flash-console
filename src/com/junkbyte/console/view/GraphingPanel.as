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
	import com.junkbyte.console.Console;
	import com.junkbyte.console.vos.GraphGroup;
	import com.junkbyte.console.vos.GraphInterest;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * @private
	 */
	public class GraphingPanel extends ConsolePanel {
		//
		public static const FPS:String = "fpsPanel";
		public static const MEM:String = "memoryPanel";
		//
		private var _group:GraphGroup;
		private var _interest:GraphInterest;
		private var _infoMap:Object = new Object();
		
		private var _menuString:String;
		//
		private var _type:String;
		//
		private var _needRedraw:Boolean;
		//
		private var underlay:Shape;
		private var graph:Shape;
		private var lowTxt:TextField;
		private var highTxt:TextField;
		//
		public var startOffset:int = 5;
		//
		public function GraphingPanel(m:Console, W:int, H:int, type:String = null) {
			super(m);
			_type = type;
			registerDragger(bg);
			minWidth = 32;
			minHeight = 26;
			//
			var textFormat:TextFormat = new TextFormat();
			var lowStyle:Object = style.styleSheet.getStyle("low");
			textFormat.font = lowStyle.fontFamily;
			textFormat.size = lowStyle.fontSize;
			textFormat.color = style.lowColor;
			
			lowTxt = new TextField();
			lowTxt.name = "lowestField";
			lowTxt.defaultTextFormat = textFormat;
			lowTxt.mouseEnabled = false;
			lowTxt.height = style.menuFontSize+2;
			addChild(lowTxt);
			
			highTxt = new TextField();
			highTxt.name = "highestField";
			highTxt.defaultTextFormat = textFormat;
			highTxt.mouseEnabled = false;
			highTxt.height = style.menuFontSize+2;
			highTxt.y = style.menuFontSize-4;
			addChild(highTxt);
			//
			txtField = makeTF("menuField");
			txtField.height = style.menuFontSize+4;
			txtField.y = -3;
			registerTFRoller(txtField, onMenuRollOver, linkHandler);
			registerDragger(txtField); // so that we can still drag from textfield
			addChild(txtField);
			//
			underlay = new Shape();
			addChild(underlay);
			//
			graph = new Shape();
			graph.name = "graph";
			graph.y = style.menuFontSize;
			addChild(graph);
			//
			
			_menuString = "<menu>";
			if(_type == MEM){
				_menuString += " <a href=\"event:gc\">G</a> ";
			}
			_menuString += "<a href=\"event:reset\">R</a> <a href=\"event:close\">X</a></menu></low></r>";
			
			//
			init(W,H,true);
		}
		private function stop():void {
			if(_group) console.graphing.remove(_group.name);
		}
		public function get group():GraphGroup{
			return _group;
		}
		public function reset():void{
			_infoMap = {};
			graph.graphics.clear();
			if(!_group.fixed)
			{
				_group.low = NaN;
				_group.hi = NaN;
			}
		}
		/*public function set showKeyText(b:Boolean):void{
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
		}*/
		override public function set height(n:Number):void{
			super.height = n;
			lowTxt.y = n-style.menuFontSize;
			_needRedraw = true;
			
			var g:Graphics = underlay.graphics;
			g.clear();
			g.lineStyle(1,style.controlColor, 0.6);
			g.moveTo(0, graph.y);
			g.lineTo(width-startOffset, graph.y);
			g.lineTo(width-startOffset, n);
		}
		override public function set width(n:Number):void{
			super.width = n;
			lowTxt.width = n;
			highTxt.width = n;
			txtField.width = n;
			txtField.scrollH = txtField.maxScrollH;
			graph.graphics.clear();
			_needRedraw = true;
		}
		//
		//
		//
		public function update(group:GraphGroup, draw:Boolean):void{
			_group = group;
			var push:int = 1; // 0 = no push, 1 = 1 push, 2 = push all
			if(group.idle>0){
				push = 0;
				if(!_needRedraw) return;
			}
			if(_needRedraw) draw = true;
			_needRedraw = false;
			var interests:Array = group.interests;
			var W:int = width-startOffset;
			var H:int = height-graph.y;
			var lowest:Number = group.low;
			var highest:Number = group.hi;
			var diffGraph:Number = highest-lowest;
			var listchanged:Boolean = false;
			if(draw) {
				TextField(group.inv?highTxt:lowTxt).text = String(group.low);
				TextField(group.inv?lowTxt:highTxt).text = String(group.hi);
				graph.graphics.clear();
			}
			var interest:GraphInterest;
			for each(interest in interests){
				_interest = interest;
				var n:String = _interest.key;
				var info:Array = _infoMap[n];
				if(info == null){
					listchanged = true;
					// used to use InterestInfo
					info = new Array(_interest.col.toString(16), new Array());
					_infoMap[n] = info;
				}
				var history:Array = info[1];
				if(push == 1) {
					// special case for FPS, because it needs to fill some frames for lagged 1s...
					if(group.type == GraphGroup.FPS){
						var frames:int = Math.floor(group.hi/_interest.v);
						if(frames>30) frames = 30; // Don't add too many lagged frames
						while(frames>0){
							history.push(_interest.v);
							frames--;
						}
					}else{
						history.push(_interest.v);
					}
				}
				var maxLen:int = Math.floor(W)+10;
				while(history.length > maxLen)
				{
					history.shift();
				}
				if(draw) {
					var len:int = history.length;
					graph.graphics.lineStyle(1, _interest.col);
					var maxi:int = W>len?len:W;
					for(var i:int = 1; i<maxi; i++){
						var Y:Number = (diffGraph?((history[len-i]-lowest)/diffGraph):0.5)*H;
						if(!group.inv) Y = H-Y;
						if(Y<0)Y=0;
						if(Y>H)Y=H;
						if(i==1){
							graph.graphics.moveTo(width, Y);
						}
						graph.graphics.lineTo((W-i), Y);
					}
					if(isNaN(_interest.avg) && diffGraph){
						Y = ((_interest.avg-lowest)/diffGraph)*H;
						if(!group.inv) Y = H-Y;
						if(Y<0)Y=0;
						if(Y>H)Y=H;
						graph.graphics.lineStyle(1,_interest.col, 0.3);
						graph.graphics.moveTo(0, Y);
						graph.graphics.lineTo(W, Y);
					}
				}
			}
			for(var X:String in _infoMap){
				var found:Boolean;
				for each(interest in interests){
					if(interest.key == X)
					{
						found = true;
					}
				}
				if(!found){
					listchanged = true;
					delete _infoMap[X];
				}
			}
			if(draw && (listchanged || _type)) updateKeyText();
		}
		
		public function updateKeyText():void{
			var str:String = "<r><low>";
			if(_type){
				if(isNaN(_interest.v)){
					str += "no input";
				}else if(_type == FPS){
					str += _interest.avg.toFixed(1);
				}else{
					str += _interest.v+"mb";
				}
			}else{
				for(var X:String in _infoMap){
					str += " <font color='#"+_infoMap[X][0]+"'>"+X+"</font>";
				}
				str += " |";
			}
			txtField.htmlText = str+_menuString;
			txtField.scrollH = txtField.maxScrollH;
		}
		
		
		protected function linkHandler(e:TextEvent):void{
			TextField(e.currentTarget).setSelection(0, 0);
			if(e.text == "reset"){
				reset();
			}else if(e.text == "close"){
				if(_type == FPS) console.fpsMonitor = false;
				else if(_type == MEM) console.memoryMonitor = false;
				else stop();
				console.panels.removeGraph(_group);
			}else if(e.text == "gc"){
				console.gc();
			} 
			e.stopPropagation();
		}
		protected function onMenuRollOver(e:TextEvent):void{
			var txt:String = e.text?e.text.replace("event:",""):null;
			if(txt == "gc"){
				txt = "Garbage collect::Requires debugger version of flash player";
			}
			console.panels.tooltip(txt, this);
		}
	}
}
/*
Stopped using this to save 0.5kb! - wow
class InterestInfo{
	public var col:Number;
	public var history:Array = [];
	public function InterestInfo(c:Number){
		col = c;
	}
}*/