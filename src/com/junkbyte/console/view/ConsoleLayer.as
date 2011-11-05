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
	import com.junkbyte.console.ConsoleLevel;
	import com.junkbyte.console.core.ConsoleModulesManager;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.view.mainPanel.MainPanel;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

    public class ConsoleLayer extends Sprite
    {

        private var _central:ConsoleModulesManager;

        private var _mainPanel:MainPanel;

        private var _stageModule:StageModule;

        private var _chsPanel:ChannelsPanel;

        //private var _fpsPanel:GraphingPanel;
        //private var _memPanel:GraphingPanel;
        //private var _graphsMap:Object = {};
        //private var _graphPlaced:uint = 0;

        private var _tooltipField:TextField;

        private var _canDraw:Boolean;

        private var _topTries:int = 50;

        public function ConsoleLayer(console:Console)
        {
            name = "Console";
            _central = console.modules;
        }

        public function start():void
        {
			_mainPanel = new MainPanel();
			
			_tooltipField = new TextField();
			_tooltipField.name = "tooltip";
			_tooltipField.styleSheet = _central.config.style.styleSheet;
			_tooltipField.background = true;
			_tooltipField.backgroundColor = _central.config.style.backgroundColor;
			_tooltipField.mouseEnabled = false;
			_tooltipField.autoSize = TextFieldAutoSize.CENTER;
			_tooltipField.multiline = true;
			
			addPanel(_mainPanel);
            _central.registerModule(_mainPanel);

            addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
        }
		
		
		public function get console():Console
		{
			return _central.console;
		}

        public function toggleVisibility():void
        {
            if (visible && !mainPanel.sprite.visible)
            {
                mainPanel.sprite.visible = true;
            }
            else
            {
                visible = !visible;
            }
            mainPanel.moveToLastSafePosition();
        }

        override public function set visible(v:Boolean):void
        {
            super.visible = v;
            if (v)
                mainPanel.sprite.visible = true;

            _central.console.dispatchEvent(ConsoleEvent.create(visible ? ConsoleEvent.SHOWN : ConsoleEvent.HIDDEN));
        }

        private function stageAddedHandle(e:Event = null):void
        {
            removeEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
            addEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle);
            stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave, false, 0, true);

            _central.console.addEventListener(ConsoleEvent.UPDATE_DATA, _onDataUpdated);

            registerStageModule();
        }

        private function stageRemovedHandle(e:Event = null):void
        {
            removeEventListener(Event.REMOVED_FROM_STAGE, stageRemovedHandle);
            addEventListener(Event.ADDED_TO_STAGE, stageAddedHandle);
            stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);

            _central.console.removeEventListener(ConsoleEvent.UPDATE_DATA, _onDataUpdated);

            unregisterStageModule();
        }

        protected function registerStageModule():void
        {
            if (_stageModule == null)
            {
                _stageModule = new StageModule(stage);
                _central.registerModule(_stageModule);
            }
        }

        protected function unregisterStageModule():void
        {
            if (_stageModule != null)
            {
                _central.unregisterModule(_stageModule);
                _stageModule = null;
            }
        }

        private function onStageMouseLeave(e:Event):void
        {
            setTooltip(null);
        }

        //
        //
        //
        private function _onDataUpdated(e:ConsoleEvent):void
        {
            if (!visible || !parent)
            {
                return;
            }

            if (_central.config.alwaysOnTop && parent.getChildAt(parent.numChildren - 1) != this && _topTries > 0)
            {
                _topTries--;
                parent.addChild(this);
                _central.report("Moved console on top (alwaysOnTop enabled), " + _topTries + " attempts left.", ConsoleLevel.CONSOLE_STATUS);
            }
            var paused:Boolean = _central.console.paused;
            var lineAdded:Boolean = _central.logs.newLogsSincesLastUpdate;
            _canDraw = !paused;
            _mainPanel.update(!paused && lineAdded);
            if (!paused)
            {
                if (lineAdded && _chsPanel != null)
                {
                    _chsPanel.update();
                }
            }
        }

        public function addPanel(panel:ConsolePanel):void
        {
            addChild(panel.sprite);
            panel.addEventListener(Event.CLOSE, onPanelClose, false, 0, true);
            if (contains(_tooltipField))
            {
                addChild(_tooltipField);
            }
        }
		
		public function removePanel(panel:ConsolePanel):void
		{
			panel.close();
			if(contains(panel.sprite))
			{
				removeChild(panel.sprite);
			}
		}

        public function removePanelByName(n:String):void
        {
            var panel:ConsolePanel = getChildByName(n) as ConsolePanel;
            if (panel)
            {
                // this should removes it self from parent. this way each individual panel can clean up before closing.  
                panel.close();
            }
        }

        private function onPanelClose(e:Event):void
        {
            ConsolePanel(e.currentTarget).removeEventListener(Event.CLOSE, onPanelClose);
            setTooltip(null);
        }

        public function getPanel(n:String):ConsolePanel
        {
            return getChildByName(n) as ConsolePanel;
        }

        public function get mainPanel():MainPanel
        {
            return _mainPanel;
        }

        public function panelExists(n:String):Boolean
        {
            return (getChildByName(n) as ConsolePanel) ? true : false;
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
        public function setPanelArea(panelname:String, rect:Rectangle):void
        {
            var panel:ConsolePanel = getPanel(panelname);
            if (panel)
            {
                panel.sprite.x = rect.x;
                panel.sprite.y = rect.y;
                panel.setPanelSize(rect.width ? rect.width : panel.sprite.width, rect.height ? rect.height : panel.sprite.height);
            }
        }

        /*
        public function updateGraphs(graphs:Array):void{
            if(!visible || !parent){
                return;
            }
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
                        panel = new GraphingPanel(_central, rect.width,rect.height);
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
                    _fpsPanel = new GraphingPanel(_central, 80 ,40, GraphingPanel.FPS);
                    _fpsPanel.name = GraphingPanel.FPS;
                    _fpsPanel.x = _mainPanel.x+_mainPanel.width-160;
                    _fpsPanel.y = _mainPanel.y+15;
                    addPanel(_fpsPanel);
                    _mainPanel.updateMenu();
                }
                _fpsPanel.update(fpsGroup, _canDraw);
            }else if(_fpsPanel!=null){
                removePanelByName(GraphingPanel.FPS);
                _fpsPanel = null;
            }
            //
            //
            if(memGroup != null){
                if(_memPanel == null){
                    _memPanel = new GraphingPanel(_central, 80 ,40, GraphingPanel.MEM);
                    _memPanel.name = GraphingPanel.MEM;
                    _memPanel.x = _mainPanel.x+_mainPanel.width-80;
                    _memPanel.y = _mainPanel.y+15;
                    addPanel(_memPanel);
                    _mainPanel.updateMenu();
                }
                _memPanel.update(memGroup, _canDraw);
            }else if(_memPanel!=null){
                removePanelByName(GraphingPanel.MEM);
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
        }*/
        //
        //
        //
        public function get channelsPanel():Boolean
        {
            return _chsPanel != null;
        }

        public function set channelsPanel(b:Boolean):void
        {
            if (channelsPanel != b)
            {
                _central.logs.cleanChannels();
                if (b)
                {
                    _chsPanel = new ChannelsPanel();
					console.modules.registerModule(_chsPanel);
                    _chsPanel.sprite.x = _mainPanel.sprite.x + _mainPanel.width - 332;
                    _chsPanel.sprite.y = _mainPanel.sprite.y - 2;
                    addPanel(_chsPanel);
                    _chsPanel.update();
                }
                else
                {
					console.modules.unregisterModule(_chsPanel);
                    removePanelByName(ChannelsPanel.NAME);
                    _chsPanel = null;
                }
            }
        }

        //
        //
        //
        public function setTooltip(str:String = null, panel:ConsolePanel = null):void
        {
            if (str)
            {
                var split:Array = str.split("::");
                str = split[0];
                if (split.length > 1)
                    str += "<br/><low>" + split[1] + "</low>";
                addChild(_tooltipField);
                _tooltipField.wordWrap = false;
                _tooltipField.htmlText = "<tt>" + str + "</tt>";
                if (_tooltipField.width > 120)
                {
                    _tooltipField.width = 120;
                    _tooltipField.wordWrap = true;
                }
                _tooltipField.x = mouseX - (_tooltipField.width / 2);
                _tooltipField.y = mouseY + 20;
                if (panel)
                {
                    var txtRect:Rectangle = _tooltipField.getBounds(this);
                    var panRect:Rectangle = new Rectangle(panel.x, panel.y, panel.width, panel.height);
                    var doff:Number = txtRect.bottom - panRect.bottom;
                    if (doff > 0)
                    {
                        if ((_tooltipField.y - doff) > (mouseY + 15))
                        {
                            _tooltipField.y -= doff;
                        }
                        else if (panRect.y < (mouseY - 24) && txtRect.y > panRect.bottom)
                        {
                            _tooltipField.y = mouseY - _tooltipField.height - 15;
                        }
                    }
                    var loff:Number = txtRect.left - panRect.left;
                    var roff:Number = txtRect.right - panRect.right;
                    if (loff < 0)
                    {
                        _tooltipField.x -= loff;
                    }
                    else if (roff > 0)
                    {
                        _tooltipField.x -= roff;
                    }
                }
            }
            else if (contains(_tooltipField))
            {
                removeChild(_tooltipField);
            }
        }

        //
        //
        //
    }
}
