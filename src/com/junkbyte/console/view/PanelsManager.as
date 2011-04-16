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
package com.junkbyte.console.view 
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.vos.GraphGroup;

	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class PanelsManager{
		
		private var console:Console;
		private var _mainPanel:MainPanel;
		private var _ruler:Ruler;
		
		private var _chsPanel:ChannelsPanel;
		private var _fpsPanel:GraphingPanel;
		private var _memPanel:GraphingPanel;
		private var _graphsMap:Object = {};
		private var _graphPlaced:uint = 0;
		
		private var _tooltipField:TextField;
		private var _canDraw:Boolean;
		
		public function PanelsManager(master:Console) {
			console = master;
			_mainPanel = new MainPanel(console);
			_tooltipField = mainPanel.makeTF("tooltip", true);
			_tooltipField.mouseEnabled = false;
			_tooltipField.autoSize = TextFieldAutoSize.CENTER;
			_tooltipField.multiline = true;
			addPanel(_mainPanel);
		}
		public function addPanel(panel:ConsolePanel):void{
			if(console.contains(_tooltipField)){
				console.addChildAt(panel, console.getChildIndex(_tooltipField));
			}else{
				console.addChild(panel);
			}
			panel.addEventListener(ConsolePanel.DRAGGING, onPanelStartDragScale, false,0, true);
			panel.addEventListener(ConsolePanel.SCALING, onPanelStartDragScale, false,0, true);
		}
		public function removePanel(n:String):void{
			var panel:ConsolePanel = console.getChildByName(n) as ConsolePanel;
			if(panel){
				// this removes it self from parent. this way each individual panel can clean up before closing.  
				panel.close();
			}
		}
		public function getPanel(n:String):ConsolePanel{
			return console.getChildByName(n) as ConsolePanel;
		}
		public function get mainPanel():MainPanel{
			return _mainPanel;
		}
		public function panelExists(n:String):Boolean{
			return (console.getChildByName(n) as ConsolePanel)?true:false;
		}
		/**
		 * Set panel position and size.
		 * <p>
		 * See panel names in Console.NAME, FPSPanel.NAME, MemoryPanel.NAME, RollerPanel.NAME, RollerPanel.NAME, etc...
		 * No effect if panel of that name doesn't exist.
		 * </p>
		 * @param	Name of panel to set
		 * @param	Rectangle area for panel size and position. Leave any property value zero to keep as is.
		 *  		For example, if you don't want to change the height of the panel, pass rect.height = 0;
		 */
		public function setPanelArea(panelname:String, rect:Rectangle):void{
			var panel:ConsolePanel = getPanel(panelname);
			if(panel){
				panel.x = rect.x;
				panel.y = rect.y;
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
			_canDraw = !paused;
			_mainPanel.update(!paused && lineAdded);
			if(!paused) {
				if(lineAdded && _chsPanel!=null){
					_chsPanel.update();
				}
			}
		}
		public function updateGraphs(graphs:Array):void{
			var usedMap:Object = {};
			var fpsGroup:GraphGroup;
			var memGroup:GraphGroup;
			_graphPlaced = 0;
			for each(var group:GraphGroup in graphs){
				if(group.type == GraphGroup.FPS) {
					fpsGroup = group;
				}else if(group.type == GraphGroup.MEM) {
					memGroup = group;
				}else{
					var n:String = group.name;
					var panel:GraphingPanel = _graphsMap[n] as GraphingPanel;
					if(!panel){
						var rect:Rectangle = group.rect;
						if(rect == null) rect = new Rectangle(NaN,NaN, 0, 0);
						var size:Number = 100;
						if(isNaN(rect.x) || isNaN(rect.y)){
							if(_mainPanel.width < 150){
								size = 50;
							}
							var maxX:Number = Math.floor(_mainPanel.width/size)-1;
							if(maxX <=1) maxX = 2;
							var ix:int = _graphPlaced%maxX;
							var iy:int = Math.floor(_graphPlaced/maxX);
							rect.x = _mainPanel.x+size+(ix*size);
							rect.y = _mainPanel.y+(size*0.6)+(iy*size);
							_graphPlaced++;
						}
						if(rect.width<=0 || isNaN(rect.width))  rect.width = size;
						if(rect.height<=0 || isNaN(rect.height)) rect.height = size;
						panel = new GraphingPanel(console, rect.width,rect.height);
						panel.x = rect.x;
						panel.y = rect.y;
						panel.name = "graph_"+n;
						_graphsMap[n] = panel;
						addPanel(panel);
					}
					panel.update(group, _canDraw);
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
				if (_fpsPanel == null) {
					_fpsPanel = new GraphingPanel(console, 80 ,40, GraphingPanel.FPS);
					_fpsPanel.name = GraphingPanel.FPS;
					_fpsPanel.x = _mainPanel.x+_mainPanel.width-160;
					_fpsPanel.y = _mainPanel.y+15;
					addPanel(_fpsPanel);
					_mainPanel.updateMenu();
				}
				_fpsPanel.update(fpsGroup, _canDraw);
			}else if(_fpsPanel!=null){
				removePanel(GraphingPanel.FPS);
				_fpsPanel = null;
			}
			//
			//
			if(memGroup != null){
				if(_memPanel == null){
					_memPanel = new GraphingPanel(console, 80 ,40, GraphingPanel.MEM);
					_memPanel.name = GraphingPanel.MEM;
					_memPanel.x = _mainPanel.x+_mainPanel.width-80;
					_memPanel.y = _mainPanel.y+15;
					addPanel(_memPanel);
					_mainPanel.updateMenu();
				}
				_memPanel.update(memGroup, _canDraw);
			}else if(_memPanel!=null){
				removePanel(GraphingPanel.MEM);
				_memPanel = null;
			}
			_canDraw = false;
		}
		public function removeGraph(group:GraphGroup):void
		{
			if(_fpsPanel && group == _fpsPanel.group){
				_fpsPanel.close();
				_fpsPanel = null;
			}else if(_memPanel && group == _memPanel.group){
				_memPanel.close();
				_memPanel = null;
			}else{
				var graph:GraphingPanel = _graphsMap[group.name];
				if(graph){
					graph.close();
					delete _graphsMap[group.name];
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
					if(console.config.displayRollerEnabled){
						var roller:RollerPanel = new RollerPanel(console);
						roller.x = _mainPanel.x+_mainPanel.width-180;
						roller.y = _mainPanel.y+55;
						addPanel(roller);
					}else{
						console.report("Display roller is disabled in config.", 9);
					}
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
				console.logs.cleanChannels();
				if(b){
					_chsPanel = new ChannelsPanel(console);
					_chsPanel.x = _mainPanel.x+_mainPanel.width-332;
					_chsPanel.y = _mainPanel.y-2;
					addPanel(_chsPanel);
					_chsPanel.update();
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
		public function tooltip(str:String = null, panel:ConsolePanel = null):void{
			if(str && !rulerActive){
				var split:Array = str.split("::");
				str = split[0];
				if(split.length > 1) str += "<br/><low>"+split[1]+"</low>";
				console.addChild(_tooltipField);
				_tooltipField.wordWrap = false;
				_tooltipField.htmlText = "<tt>"+str+"</tt>";
				if(_tooltipField.width>120){
					_tooltipField.width = 120;
					_tooltipField.wordWrap = true;
				}
				_tooltipField.x = console.mouseX-(_tooltipField.width/2);
				_tooltipField.y = console.mouseY+20;
				if(panel){
					var txtRect:Rectangle = _tooltipField.getBounds(console);
					var panRect:Rectangle = new Rectangle(panel.x,panel.y,panel.width,panel.height);
					var doff:Number = txtRect.bottom - panRect.bottom;
					if(doff>0){
						if((_tooltipField.y - doff)>(console.mouseY+15)){
							_tooltipField.y -= doff;
						}else if(panRect.y<(console.mouseY-24) && txtRect.y>panRect.bottom){
							_tooltipField.y = console.mouseY-_tooltipField.height-15;
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
			}else if(console.contains(_tooltipField)){
				console.removeChild(_tooltipField);
			}
		}
		//
		//
		//
		public function startRuler():void{
			if(rulerActive){
				return;
			}
			_ruler = new Ruler(console);
			_ruler.addEventListener(Event.COMPLETE, onRulerExit, false, 0, true);
			console.addChild(_ruler);
			_mainPanel.updateMenu();
		}
		public function get rulerActive():Boolean{
			return (_ruler && console.contains(_ruler))?true:false;
		}
		private function onRulerExit(e:Event):void{
			if(_ruler && console.contains(_ruler)){
				console.removeChild(_ruler);
			}
			_ruler = null;
			_mainPanel.updateMenu();
		}
		//
		//
		//
		private function onPanelStartDragScale(e:Event):void{
			var target:ConsolePanel = e.currentTarget as ConsolePanel;
			if(console.config.style.panelSnapping) {
				var X:Array = [0];
				var Y:Array = [0];
				if(console.stage){
					// this will only work if stage size is not changed or top left aligned
					X.push(console.stage.stageWidth);
					Y.push(console.stage.stageHeight);
				}
				var numchildren:int = console.numChildren;
				for(var i:int = 0;i<numchildren;i++){
					var panel:ConsolePanel = console.getChildAt(i) as ConsolePanel;
					if(panel && panel.visible){
						X.push(panel.x, panel.x+panel.width);
						Y.push(panel.y, panel.y+panel.height);
					}
				}
				target.registerSnaps(X, Y);
			}
		}
	}
}
