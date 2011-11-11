/*
*
* Copyright (c) 2008-2011 Lu Aye Oo
*
* @author 		Lu Aye Oo
*
* http://code.google.com/p/flash-console/
* http://junkbyte.com
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
package com.junkbyte.console.view.mainPanel
{
    import com.junkbyte.console.ConsoleLevel;
    import com.junkbyte.console.core.ModuleTypeMatcher;
    import com.junkbyte.console.events.ConsoleEvent;
    import com.junkbyte.console.events.ConsolePanelEvent;
    import com.junkbyte.console.logging.Logs;
    import com.junkbyte.console.view.ChannelsPanel;
    import com.junkbyte.console.view.ConsolePanel;
    
    import flash.events.Event;
    import flash.events.TextEvent;
    import flash.geom.Point;
    import flash.system.Security;
    import flash.system.SecurityPanel;

    public class MainPanel extends ConsolePanel
    {

        public static const NAME:String = "mainPanel";

        public static const COMMAND_LINE_VISIBLITY_CHANGED:String = "commandLineVisibilityChanged";


        private var _menu:MainPanelMenu;

        private var _traces:MainPanelLogs;

        private var _commandArea:MainPanelCL;

        private var _needUpdateMenu:Boolean;

        private var _enteringLogin:Boolean;

        private var _movedFrom:Point;

        public function MainPanel()
        {
            super();
            minSize.x = 160;

            addEventListener(ConsolePanelEvent.STARTED_MOVING, onStartedDragging);
        }

        override protected function initToConsole():void
        {
            super.initToConsole();
            sprite.name = NAME;

            //
            _menu = new MainPanelMenu(this);
            _traces = new MainPanelLogs(this);
            _commandArea = new MainPanelCL(this);

            _menu.addEventListener(Event.CHANGE, onMenuChanged);
            
            modules.registerModule(_menu);

            modules.registerModule(_traces);

            modules.registerModule(_commandArea);

            startPanelResizer();

            sprite.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);

            setPanelSize(480, 100);
        }

        public function get menu():MainPanelMenu
        {
            return _menu;
        }

        public function get traces():MainPanelLogs
        {
            return _traces;
        }

        public function get commandArea():MainPanelCL
        {
            return _commandArea;
        }
		
		public function setViewingChannels(...channels:Array):void
		{
			traces.setViewingChannels.apply(this, channels);
		}
		
		public function setIgnoredChannels(...channels:Array):void
		{
			traces.setIgnoredChannels.apply(this, channels);
		}
		
		public function set minimumPriority(level:uint):void
		{
			traces.priority = level;
		}

        private function onStartedDragging(e:Event):void
        {
            _movedFrom = new Point(x, y);
        }

        public function requestLogin(on:Boolean = true):void
        {
            if (on)
            {
                commandLine = true;
				logger.report("//", ConsoleLevel.CONSOLE_EVENT);
				logger.report("// <b>Enter remoting password</b> in CommandLine below...", ConsoleLevel.CONSOLE_EVENT);
            }
            _traces.requestLogin(on);
            _commandArea.requestLogin(on);
            _enteringLogin = on;
        }

        public function get enteringLogin():Boolean
        {
            return _enteringLogin;
        }

        override protected function resizePanel(w:Number, h:Number):void
        {
            super.resizePanel(w, h);

            updateMenuArea();

            updateCommandArea();
            _needUpdateMenu = true;

            var fsize:int = style.menuFontSize;
            var msize:Number = fsize + 6 + style.traceFontSize;
            if (height != h)
            {
                _menu.mini = h < (_commandArea.isVisible ? (msize + fsize + 4) : msize);
            }

            updateTraceArea();
        }

        private function updateMenuArea():void
        {
            _menu.setArea(0, 0, width - 6, height);
        }

        private function updateTraceArea():void
        {
            var mini:Boolean = _menu.mini || !style.topMenu;

            var traceY:Number = mini ? 0 : (_menu.area.y + _menu.area.height - 6);
            var traceHeight:Number = height - (_commandArea.isVisible ? (style.menuFontSize + 4) : 0) - traceY;
            _traces.setArea(0, traceY, width, traceHeight);

        }

        private function updateCommandArea():void
        {
            _commandArea.setArea(0, 0, width, height);
        }

        //
        //
        //
        public function updateMenu(instant:Boolean = false):void
        {
            if (instant)
            {
                _updateMenu();
            }
            else
            {
                _needUpdateMenu = true;
            }
        }

        private function _updateMenu():void
        {
            _menu.update();
        }

        private function onMenuChanged(e:Event):void
        {
			updateMenuArea();
            updateTraceArea();
        }

        public function onMenuRollOver(e:TextEvent, src:ConsolePanel = null):void
        {
            if (src == null)
                src = this;
            var txt:String = e.text ? e.text.replace("event:", "") : "";
            if (txt == "channel_" + Logs.GLOBAL_CHANNEL)
            {
                txt = "View all channels";
            }
            else if (txt == "channel_" + Logs.DEFAULT_CHANNEL)
            {
                txt = "Default channel::Logs with no channel";
            }
            else if (txt == "channel_" + Logs.CONSOLE_CHANNEL)
            {
                txt = "Console's channel::Logs generated from Console";
            }
            /*else if(txt == "channel_"+ Logs.FILTER_CHANNEL) {
                txt = _filterRegExp?String(_filterRegExp):_filterText;
                txt = "Filtering channel"+"::*"+txt+"*";
            }*/
            else if (txt == "channel_" + Logs.INSPECTING_CHANNEL)
            {
                txt = "Inspecting channel";
            }
            else if (txt.indexOf("channel_") == 0)
            {
                txt = "Change channel::shift: select multiple\nctrl: ignore channel";
            }
            else if (txt == "pause")
            {
                if (console.paused)
                    txt = "Resume updates";
                else
                    txt = "Pause updates";
            }
            else if (txt == "close" && src == this)
            {
                txt = "Close::Type password to show again";
            }
            else
            {
                var obj:Object = { fps: "Frames Per Second", mm: "Memory Monitor", channels: "Expand channels", close: "Close" };
                txt = obj[txt];
            }
			layer.setTooltip(txt, src);
        }

        private function linkHandler(e:TextEvent):void
        {
            _menu.textField.setSelection(0, 0);
            sprite.stopDrag();
            var t:String = e.text;
            if (t == "channels")
            {
				toggleChannelsPanel();
            }
            /*else if(t == "priority"){
                var keyStates:IKeyStates = modules.getModuleByName(ConsoleModuleNames.KEY_STATES) as IKeyStates;

                traces.incPriority(keyStates != null && keyStates.shiftKeyDown);
            }*/
            else if (t == "settings")
            {
				logger.report("A new window should open in browser. If not, try searching for 'Flash Player Global Security Settings panel' online :)", ConsoleLevel.CONSOLE_STATUS);
                Security.showSettings(SecurityPanel.SETTINGS_MANAGER);
            }
            else if (t == "remote")
            {
                //central.remoter.remoting = Remoting.RECIEVER;
                //} else if(t.indexOf("ref")==0){
                //	central.refs.handleRefEvent(t);
            }
            else if (t.indexOf("channel_") == 0)
            {
                traces.onChannelPressed(t.substring(8));
            }
            else if (t.indexOf("cl_") == 0)
            {
                var ind:int = t.indexOf("_", 3);
                //central.cl.handleScopeEvent(uint(t.substring(3, ind<0?t.length:ind)));
                if (ind >= 0)
                {
                    _commandArea.inputText = t.substring(ind + 1);
                }
            }
            _menu.textField.setSelection(0, 0);
            e.stopPropagation();
        }
		
		private function toggleChannelsPanel():void
		{
			var channelsPanel:ChannelsPanel = modules.findModulesByMatcher(new ModuleTypeMatcher(ChannelsPanel)) as ChannelsPanel;
			if(channelsPanel != null)
			{
				modules.unregisterModule(channelsPanel);
			}
			else
			{
				channelsPanel = new ChannelsPanel();
				modules.registerModule(channelsPanel);
			}
		}

        override public function close():void
        {
			layer.setTooltip();
            sprite.visible = false;
            dispatchEvent(new Event(Event.CLOSE));
        }

        public function toggleTopMenu():void
        {
            if (_menu.mini)
            {
                showTopMenu();
            }
            else
            {
                hideTopMenu();
            }
        }

        public function hideTopMenu():void
        {
			layer.setTooltip();
            _menu.mini = true;
            config.style.topMenu = false;
            height = height;
            updateMenu();
        }

        public function showTopMenu():void
        {
			layer.setTooltip();
            _menu.mini = false;
            config.style.topMenu = true;
            height = height;
            updateMenu();
        }

        public function set commandLine(b:Boolean):void
        {

            _commandArea.isVisible = b;

            _needUpdateMenu = true;
            
            this.height = height;
            dispatchEvent(new Event(COMMAND_LINE_VISIBLITY_CHANGED));
        }


        public function get commandLine():Boolean
        {
            return _commandArea.isVisible;
        }

        public function moveToLastSafePosition():void
        {
            if (_movedFrom != null)
            {
                // This will only work if stage size is not altered OR stage.align is top left
                if (x + width < 10 || (sprite.stage && sprite.stage.stageWidth < x + 10) || y + height < 10 || (sprite.stage && sprite.stage.stageHeight < y + 20))
                {
                    x = _movedFrom.x;
                    y = _movedFrom.y;
                }
                _movedFrom = null;
            }
        }
    }
}