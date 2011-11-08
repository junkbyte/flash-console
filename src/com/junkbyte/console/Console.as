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
package com.junkbyte.console
{
    import com.junkbyte.console.core.ConsoleModulesManager;
    import com.junkbyte.console.core.ModuleDependenceCallback;
    import com.junkbyte.console.events.ConsoleEvent;
    import com.junkbyte.console.logging.ConsoleLogger;
    import com.junkbyte.console.modules.ConsoleModuleNames;
    import com.junkbyte.console.view.ConsoleLayer;
    import com.junkbyte.console.view.mainPanel.MainPanel;
    import com.junkbyte.console.vos.ConsoleModuleMatch;
    
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.system.Capabilities;
    import flash.utils.getTimer;

    /**
     * @see http://code.google.com/p/flash-console/
     */
    [Event(name = "consoleStarted", type = "com.junkbyte.console.events.ConsoleEvent")]
    [Event(name = "consoleShown", type = "com.junkbyte.console.events.ConsoleEvent")]
    [Event(name = "consoleHidden", type = "com.junkbyte.console.events.ConsoleEvent")]
    [Event(name = "paused", type = "com.junkbyte.console.events.ConsoleEvent")]
    [Event(name = "resumed", type = "com.junkbyte.console.events.ConsoleEvent")]
    [Event(name = "updateData", type = "com.junkbyte.console.events.ConsoleEvent")]
    [Event(name = "dataUpdated", type = "com.junkbyte.console.events.ConsoleEvent")]
    public class Console extends EventDispatcher
    {

        protected var _modules:ConsoleModulesManager;

        protected var _logger:ConsoleLogger;

        protected var _display:ConsoleLayer;

        protected var _config:ConsoleConfig;

        protected var _paused:Boolean;

        protected var _lastTimer:Number;

        /**
         * Console is the main class.
         * @see http://code.google.com/p/flash-console/
         */
        public function Console()
        {
        }

        public function start(container:DisplayObjectContainer = null):void
        {
            if (started)
            {
                addToContainer(container);
                return;
            }
            config.style.updateStyleSheet();
			initData();
            initDisplay();
            addToContainer(container);
            dispatchEvent(ConsoleEvent.create(ConsoleEvent.STARTED));
        }
		
		protected function initData():void
		{
			initModulesManager();
			listenForLoggerRegister();
			registerLoggerModule();
			/*
			modules.registerModule(new ConsoleReferencingModule());
			modules.registerModule(new SlashCommandLine());
			modules.registerModule(new KeyBinder());
			*/
		}

        protected function initModulesManager():void
        {
            _modules = new ConsoleModulesManager(this);
        }

        protected function listenForLoggerRegister():void
        {
            var watcher:ModuleDependenceCallback = ModuleDependenceCallback.createUsingModulesManager(_modules);
            watcher.addCallback(ConsoleModuleMatch.createForName(ConsoleModuleNames.LOGGER), onLoggerRegistered);
        }
		
		protected function registerLoggerModule():void
		{
			modules.registerModule(CLog != null ? CLog : new ConsoleLogger());
		}
		
		// this is so that if anyone wants to extend ConsoleLogger and register it, it'll catch that new module as replacement.
		protected function onLoggerRegistered(logger:ConsoleLogger):void
		{
			if (logger != null)
			{
				_logger = logger;
				setStaticCLog();
			}
		}
		
		protected function setStaticCLog():void
		{
			CLog = logger;
		}

        protected function initDisplay():void
        {
            _display = new ConsoleLayer(this);

            if (config.keystrokePassword)
                _display.visible = false;
            _display.start();

            logger.report("<b>Console v" + ConsoleVersion.VERSION + ConsoleVersion.STAGE + "</b> build " + ConsoleVersion.BUILD + ". " + Capabilities.playerType + " " + Capabilities.version + ".", ConsoleLevel.CONSOLE_EVENT);

            layer.addEventListener(Event.ENTER_FRAME, onLayerEnterFrame);
        }

        protected function addToContainer(container:DisplayObjectContainer):void
        {
            if (container != null)
            {
                container.addChild(layer);
            }
        }

        public function startOnStage(target:DisplayObject):void
        {
            if (!started)
            {
                start();
            }
            if (target)
            {
                if (target.stage)
                {
                    addToContainer(target.stage);
                }
                else
                {
                    target.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
                }
            }
        }

        private function onAddedToStage(e:Event):void
        {
            var mc:DisplayObjectContainer = e.currentTarget as DisplayObjectContainer;
            mc.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            addToContainer(mc.stage);
        }

        public function get started():Boolean
        {
            return _modules != null;
        }

        protected function onLayerEnterFrame(e:Event):void
        {
            var msDelta:uint = updateTime();
            announceDataUpdate(msDelta);
            announceViewUpdate(msDelta);
        }

        protected function updateTime():uint
        {
            var timeNow:Number = getTimer();
            var msDelta:uint = timeNow - _lastTimer;
            _lastTimer = timeNow;
            return msDelta;
        }

        protected function announceDataUpdate(msDelta:uint):void
        {
            var event:ConsoleEvent = ConsoleEvent.create(ConsoleEvent.UPDATE_DATA);
            event.msDelta = msDelta;
            dispatchEvent(event);
        }

        protected function announceViewUpdate(msDelta:uint):void
        {
            var event:ConsoleEvent = ConsoleEvent.create(ConsoleEvent.DATA_UPDATED);
            event.msDelta = msDelta;
            dispatchEvent(event);
        }

        public function get paused():Boolean
        {
            return _paused;
        }

        public function set paused(newV:Boolean):void
        {
            if (_paused == newV)
            {
                return;
            }
            if (newV)
			{
				logger.report("Paused", ConsoleLevel.CONSOLE_STATUS);
			}
            else
			{
				logger.report("Resumed", ConsoleLevel.CONSOLE_STATUS);
			}
            _paused = newV;
            dispatchEvent(new Event(_paused ? ConsoleEvent.PAUSED : ConsoleEvent.RESUMED));
        }

        //
        //
        //

        public function get modules():ConsoleModulesManager
        {
            return _modules;
        }

        public function get logger():ConsoleLogger
        {
            return _logger;
        }

        public function get layer():ConsoleLayer
        {
            return _display;
        }
		
		public function get mainPanel():MainPanel
		{
			return layer.mainPanel;
		}

        public function get config():ConsoleConfig
        {
            if (_config == null)
			{
				_config = new ConsoleConfig();
			}
            return _config;
        }
    }
}
