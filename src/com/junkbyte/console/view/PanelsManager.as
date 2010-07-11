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
	import com.junkbyte.console.vos.GraphGroup;
	import com.junkbyte.console.Console;

	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class PanelsManager{
		
		
		private static const USER_GRAPH_PREFIX:String = "graph_";
		private static const USER_OBJECTMONITOR_PREFIX:String = "objMonitor_";
		
		private var _master:Console;
		private var _mainPanel:MainPanel;
		private var _ruler:Ruler;
		private var _channels:Array;
		
		private var _chsPanel:ChannelsPanel;
		private var _fpsPanel:FPSPanel;
		private var _memPanel:MemoryPanel;
		private var _graphsMap:Object = {};
		private var _objMonitors:Object = {};
		
		private var _tooltipField:TextField;
		
		public function PanelsManager(master:Console, mp:MainPanel, channels:Array) {
			_master = master;
			_mainPanel = mp;
			_channels = channels;
			_tooltipField = mainPanel.makeTF("tooltip", false, true);
			_tooltipField.autoSize = TextFieldAutoSize.CENTER;
			_tooltipField.multiline = true;
			addPanel(_mainPanel);
		}
		public function addPanel(panel:AbstractPanel):void{
			if(_master.contains(_tooltipField)){
				_master.addChildAt(panel, _master.getChildIndex(_tooltipField));
			}else{
				_master.addChild(panel);
			}
			panel.addEventListener(AbstractPanel.STARTED_DRAGGING, onPanelStartDragScale, false,0, true);
			panel.addEventListener(AbstractPanel.STARTED_SCALING, onPanelStartDragScale, false,0, true);
		}
		public function removePanel(n:String):void{
			var panel:AbstractPanel = _master.getChildByName(n) as AbstractPanel;
			if(panel){
				// this removes it self from parent. this way each individual panel can clean up before closing.  
				panel.close();
			}
		}
		public function getPanel(n:String):AbstractPanel{
			return _master.getChildByName(n) as AbstractPanel;
		}
		public function get mainPanel():MainPanel{
			return _mainPanel;
		}
		public function panelExists(n:String):Boolean{
			return (_master.getChildByName(n) as AbstractPanel)?true:false;
		}
		public function setPanelArea(panelname:String, rect:Rectangle):void{
			var panel:AbstractPanel = getPanel(panelname);
			if(panel){
				if(rect.x) panel.x = rect.x;
				if(rect.y) panel.y = rect.y;
				if(rect.width) panel.width = rect.width;
				if(rect.height) panel.height = rect.height;
			}
		}
		public function updateMenu():void{
			_mainPanel.updateMenu();
			var chpanel:ChannelsPanel = getPanel(ChannelsPanel.NAME) as ChannelsPanel;
			if(chpanel) chpanel.update();
		}
		public function update(paused:Boolean, lineAdded:Boolean):void{
			_mainPanel.update(!paused && lineAdded);
			if(!paused) {
				if(lineAdded && _chsPanel!=null){
					_chsPanel.update();
				}
			}
		}
		public function updateGraphs(graphs:Array, draw:Boolean = true):void{
			var usedMap:Object = {};
			var fpsGroup:GraphGroup;
			var memGroup:GraphGroup;
			for each(var group:GraphGroup in graphs){
				if(group.type == GraphGroup.TYPE_FPS) {
					fpsGroup = group;
				}else if(group.type == GraphGroup.TYPE_MEM) {
					memGroup = group;
				}else{
					var n:String = group.name;
					var panel:GraphingPanel = _graphsMap[n] as GraphingPanel;
					if(!panel){
						var rect:Rectangle = group.rect;
						if(rect == null) rect = new Rectangle(NaN,NaN, 0, 0);
						// TODO: somehow auto place the panel if rect is empty
						if(isNaN(rect.x))  rect.x = _mainPanel.x+80;
						if(isNaN(rect.y)) rect.y = _mainPanel.y+20;
						if(rect.width<=0 || isNaN(rect.width))  rect.width = 100;
						if(rect.height<=0 || isNaN(rect.height)) rect.height = 100;
						panel = new GraphingPanel(_master, rect.width,rect.height);
						panel.x = rect.x;
						panel.y = rect.y;
						panel.name = USER_GRAPH_PREFIX+n;
						_graphsMap[n] = panel;
						addPanel(panel);
					}
					panel.update(group, draw);
				}
				usedMap[group.name] = true;
			}
			for(var X:String in _graphsMap){
				if(!usedMap[X]){
					_graphsMap[X].close();
					delete _graphsMap[X];
				}
			}
			//
			//
			if(fpsGroup != null){
				if(_fpsPanel == null){
					_fpsPanel = new FPSPanel(_master);
					_fpsPanel.x = _mainPanel.x+_mainPanel.width-160;
					_fpsPanel.y = _mainPanel.y+15;
					addPanel(_fpsPanel);
					_mainPanel.updateMenu();
				}
				_fpsPanel.update(fpsGroup);
			}else if(_fpsPanel!=null){
				removePanel(FPSPanel.NAME);
				_fpsPanel = null;
			}
			//
			//
			if(memGroup != null){
				if(_memPanel == null){
					_memPanel = new MemoryPanel(_master);
					_memPanel.x = _mainPanel.x+_mainPanel.width-80;
					_memPanel.y = _mainPanel.y+15;
					addPanel(_memPanel);
					_mainPanel.updateMenu();
				}
				_memPanel.update(memGroup);
			}else if(_memPanel!=null){
				removePanel(MemoryPanel.NAME);
				_memPanel = null;
			}
		}
		public function updateObjMonitors(objs:Object):void{
			var usedMap:Object = {};
			for (var X:String in objs){
				var panel:ObjMonitorPanel = _objMonitors[X] as ObjMonitorPanel;
				if(panel == null){
					panel = new ObjMonitorPanel(_master);
					//TODO: better placing.
					panel.x = 200;
					panel.y = 200;
					panel.id = X;
					panel.name = USER_OBJECTMONITOR_PREFIX+X;
					_objMonitors[X] = panel;
					addPanel(panel);
				}
				panel.update(objs[X]);
				usedMap[X] = true;
			}
			for(var Z:String in _objMonitors){
				if(!usedMap[Z]){
					_objMonitors[Z].close();
					delete _objMonitors[Z];
				}
			}
		}
		//
		//
		//
		public function get displayRoller():Boolean{
			return (getPanel(RollerPanel.NAME) as RollerPanel)?true:false;
		}
		public function set displayRoller(n:Boolean):void{
			if(displayRoller != n){
				if(n){
					var roller:RollerPanel = new RollerPanel(_master);
					roller.x = _mainPanel.x+_mainPanel.width-180;
					roller.y = _mainPanel.y+55;
					addPanel(roller);
					roller.start(_master);
				}else{
					removePanel(RollerPanel.NAME);
				}
				_mainPanel.updateMenu();
			}
		}
		//
		//
		//
		public function get channelsPanel():Boolean{
			return _chsPanel!=null;
		}
		public function set channelsPanel(b:Boolean):void{
			if(channelsPanel != b){
				if(b){
					_chsPanel = new ChannelsPanel(_master);
					_chsPanel.x = _mainPanel.x+_mainPanel.width-332;
					_chsPanel.y = _mainPanel.y-2;
					addPanel(_chsPanel);
					_chsPanel.start(_channels);
					updateMenu();
				}else {
					removePanel(ChannelsPanel.NAME);
					_chsPanel = null;
				}
				updateMenu();
			}
		}
		//
		//
		//
		public function get memoryMonitor():Boolean{
			return _memPanel!=null;
		}
		public function get fpsMonitor():Boolean{
			return _fpsPanel!=null;
		}
		//
		//
		//
		public function tooltip(str:String = null, panel:AbstractPanel = null):void{
			if(str && !rulerActive){
				str = str.replace(/\:\:(.*)/, "<br/><s>$1</s>");
				_master.addChild(_tooltipField);
				_tooltipField.wordWrap = false;
				_tooltipField.htmlText = "<tt>"+str+"</tt>";
				if(_tooltipField.width>120){
					_tooltipField.width = 120;
					_tooltipField.wordWrap = true;
				}
				_tooltipField.x = _master.mouseX-(_tooltipField.width/2);
				_tooltipField.y = _master.mouseY+20;
				if(panel){
					var txtRect:Rectangle = _tooltipField.getBounds(_master);
					var panRect:Rectangle = new Rectangle(panel.x,panel.y,panel.width,panel.height);
					var doff:Number = txtRect.bottom - panRect.bottom;
					if(doff>0){
						if((_tooltipField.y - doff)>(_master.mouseY+15)){
							_tooltipField.y -= doff;
						}else if(panRect.y<(_master.mouseY-24) && txtRect.y>panRect.bottom){
							_tooltipField.y = _master.mouseY-_tooltipField.height-15;
						}
					}
					var loff:Number = txtRect.left - panRect.left;
					var roff:Number = txtRect.right - panRect.right;
					if(loff<0){
						_tooltipField.x -= loff;
					}else if(roff>0){
						_tooltipField.x -= roff;
					}
				}
			}else if(_master.contains(_tooltipField)){
				_master.removeChild(_tooltipField);
			}
		}
		//
		//
		//
		public function startRuler():void{
			if(rulerActive){
				return;
			}
			_ruler = new Ruler();
			_ruler.addEventListener(Event.COMPLETE, onRulerExit, false, 0, true);
			_master.addChild(_ruler);
			_ruler.start(_master);
			_mainPanel.updateMenu();
		}
		public function get rulerActive():Boolean{
			return (_ruler && _master.contains(_ruler))?true:false;
		}
		private function onRulerExit(e:Event):void{
			if(_ruler && _master.contains(_ruler)){
				_master.removeChild(_ruler);
			}
			_ruler = null;
			_mainPanel.updateMenu();
		}
		//
		//
		//
		private function onPanelStartDragScale(e:Event):void{
			var target:AbstractPanel = e.currentTarget as AbstractPanel;
			if(target.snapping){
				var X:Array = [0];
				var Y:Array = [0];
				if(_master.stage){
					// this will only work if stage size is not changed or top left aligned
					X.push(_master.stage.stageWidth);
					Y.push(_master.stage.stageHeight);
				}
				var numchildren:int = _master.numChildren;
				for(var i:int = 0;i<numchildren;i++){
					var panel:AbstractPanel = _master.getChildAt(i) as AbstractPanel;
					if(panel && panel.visible){
						X.push(panel.x);
						X.push(panel.x+panel.width);
						Y.push(panel.y);
						Y.push(panel.y+panel.height);
					}
				}
				target.registerSnaps(X, Y);
			}
		}
	}
}
