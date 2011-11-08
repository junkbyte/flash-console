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
package com.junkbyte.console.modules.displayRoller
{
    import com.junkbyte.console.KeyBind;
    import com.junkbyte.console.modules.keybinder.KeyBinder;
    import com.junkbyte.console.interfaces.IMainMenu;
    import com.junkbyte.console.modules.ConsoleModuleNames;
    import com.junkbyte.console.modules.referencing.ConsoleReferencingModule;
    import com.junkbyte.console.utils.EscHTML;
    import com.junkbyte.console.utils.getQualifiedShortClassName;
    import com.junkbyte.console.view.ConsolePanel;
    import com.junkbyte.console.view.helpers.ConsoleTextRoller;
    import com.junkbyte.console.vos.ConsoleMenuItem;
    import com.junkbyte.console.core.ModuleTypeMatcher;
    
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.TextEvent;
    import flash.geom.Point;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.utils.Dictionary;

    public class DisplayRoller extends ConsolePanel
    {

        protected var menu:ConsoleMenuItem;

        protected var _rollerKey:KeyBind;

        protected var txtField:TextField;

        private var _settingKey:Boolean;

        public function DisplayRoller()
        {
            super();

            sprite.name = "rollerPanel";
            
            menu = new ConsoleMenuItem("Ro", onMenuClick, null, "Display Roller::Map the display list under your mouse");

			addModuleRegisteryCallback(new ModuleTypeMatcher(IMainMenu), onMainMenuRegistered, onMainMenuUnregistered);
		}
		
		protected function onMainMenuRegistered(module:IMainMenu):void
		{
			module.addMenu(menu);
		}
		
		protected function onMainMenuUnregistered(module:IMainMenu):void
		{
			module.removeMenu(menu);
		}

        override protected function initToConsole():void
        {
            super.initToConsole();

            txtField = new TextField();
            txtField.name = "rollerPrints";
            txtField.styleSheet = style.styleSheet;
            txtField.multiline = true;
            txtField.autoSize = TextFieldAutoSize.LEFT;
            addChild(txtField);
            ConsoleTextRoller.register(txtField, onMenuRollOver, linkHandler);
            registerMoveDragger(txtField);
        }

        override protected function onAddedToParentDisplay():void
        {
            super.onAddedToParentDisplay();

            sprite.addEventListener(Event.ENTER_FRAME, _onFrame);
            sprite.addEventListener(Event.REMOVED_FROM_STAGE, removeListeners);
        }

        override protected function onRemovedFromParentDisplay():void
        {
            super.onRemovedFromParentDisplay();

            removeListeners();

            menu.active = false;
            menu.announceChanged();
        }

        override public function getModuleName():String
        {
            return ConsoleModuleNames.DISPLAY_ROLLER;
        }

        public function setRollerCaptureKey(char:String, shift:Boolean = false, ctrl:Boolean = false, alt:Boolean = false):void
        {

            var keyBinder:KeyBinder = modules.getModuleByName(ConsoleModuleNames.KEYBINDER) as KeyBinder;
            if (keyBinder == null)
            {
                return;
            }
            if (_rollerKey)
            {
                keyBinder.bindKey(_rollerKey, null);
                _rollerKey = null;
            }
            if (char && char.length == 1)
            {
                _rollerKey = new KeyBind(char, shift, ctrl, alt);
                keyBinder.bindKey(_rollerKey, onRollerCaptureKey);
            }
        }

        public function hasKeyBinder():Boolean
        {
            return modules.getModuleByName(ConsoleModuleNames.KEYBINDER) != null;
        }

        protected function onRollerCaptureKey():void
        {
            if (isActive())
            {
                report("Display Roller Capture:<br/>" + getMapString(true), -1);
            }
        }

        public function get rollerCaptureKey():KeyBind
        {
            return _rollerKey;
        }


        protected function onMenuClick():void
        {
            if (isActive())
                close();
            else
                start();
        }

        public function start():void
        {
            x = layer.mainPanel.x + layer.mainPanel.width - 180;
            y = layer.mainPanel.y + 55;

            layer.addPanel(this);

            menu.active = true;
            menu.announceChanged();
        }

        public function isActive():Boolean
        {
            return menu.active;
        }

        private function removeListeners(e:Event = null):void
        {
            sprite.removeEventListener(Event.ENTER_FRAME, _onFrame);
            sprite.removeEventListener(Event.REMOVED_FROM_STAGE, removeListeners);
            if (sprite.stage)
                sprite.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
        }

        private function _onFrame(e:Event):void
        {
            if (!sprite.stage)
            {
                close();
                return;
            }
            if (_settingKey)
            {
                txtField.htmlText = "<high><menu>Press a key to set [ <a href=\"event:cancel\"><b>cancel</b></a> ]</menu></high>";
            }
            else
            {
                txtField.htmlText = "<low>" + getMapString(false) + "</low>";
                txtField.autoSize = TextFieldAutoSize.LEFT;
                txtField.setSelection(0, 0);
            }
            setPanelSize(txtField.width + 4, txtField.height);
        }

        public function getMapString(dolink:Boolean):String
        {
            var stg:Stage = sprite.stage;
            var str:String = "";
            if (!dolink)
            {
                var key:String = rollerCaptureKey ? rollerCaptureKey.key : "unassigned";
                str = "<menu> <a href=\"event:close\"><b>X</b></a></menu>";
                if (hasKeyBinder())
                {
                    str += " Capture key: <menu><a href=\"event:capture\">" + key + "</a>";
                }
                str += "</menu><br/>";
            }
            var p:Point = new Point(stg.mouseX, stg.mouseY);
            if (stg.areInaccessibleObjectsUnderPoint(p))
            {
                str += "<p9>Inaccessible objects detected</p9><br/>";
            }
            var objs:Array = stg.getObjectsUnderPoint(p);

            var stepMap:Dictionary = new Dictionary(true);
            if (objs.length == 0)
            {
                objs.push(stg); // if nothing at least have stage.
            }
            for each (var child:DisplayObject in objs)
            {
                var chain:Array = new Array(child);
                var par:DisplayObjectContainer = child.parent;
                while (par)
                {
                    chain.unshift(par);
                    par = par.parent;
                }
				var refs:ConsoleReferencingModule = getReferencesModule();
                var len:uint = chain.length;
                for (var i:uint = 0; i < len; i++)
                {
                    var obj:DisplayObject = chain[i];
                    if (stepMap[obj] == undefined)
                    {
                        stepMap[obj] = i;
                        for (var j:uint = i; j > 0; j--)
                        {
                            str += j == 1 ? " ∟" : " -";
                        }

                        var n:String = obj.name;
                        var ind:uint;
                        if (dolink && config.useObjectLinking)
                        {
                            ind = refs.setLogRef(obj);
                            n = "<a href='event:cl_" + ind + "'>" + n + "</a> " + refs.makeRefTyped(obj);
                        }
                        else
                            n = n + " (" + EscHTML(getQualifiedShortClassName(obj)) + ")";

                        if (obj == stg)
                        {
                            ind = refs.setLogRef(stg);
                            if (ind)
                                str += "<p3><a href='event:cl_" + ind + "'><i>Stage</i></a> ";
                            else
                                str += "<p3><i>Stage</i> ";
                            str += "[" + stg.mouseX + "," + stg.mouseY + "]</p3><br/>";
                        }
                        else if (i == len - 1)
                        {
                            str += "<p5>" + n + "</p5><br/>";
                        }
                        else
                        {
                            str += "<p2><i>" + n + "</i></p2><br/>";
                        }
                    }
                }
            }
            return str;
        }
		
		
		protected function getReferencesModule():ConsoleReferencingModule
		{
			return console.modules.getFirstMatchingModule(new ModuleTypeMatcher(ConsoleReferencingModule)) as ConsoleReferencingModule;
		}
		
        public override function close():void
        {
            cancelCaptureKeySet();
            removeListeners();
            super.close();
        }

        private function onMenuRollOver(e:TextEvent):void
        {
            var txt:String = e.text ? e.text.replace("event:", "") : "";
            if (txt == "close")
            {
                txt = "Close";
            }
            else if (txt == "capture")
            {
                var key:KeyBind = rollerCaptureKey;
                if (key)
                {
                    txt = "Unassign key ::" + key.key;
                }
                else
                {
                    txt = "Assign key";
                }
            }
            else if (txt == "cancel")
            {
                txt = "Cancel assign key";
            }
            else
            {
                txt = null;
            }
            layer.setTooltip(txt, this);
        }

        protected function linkHandler(e:TextEvent):void
        {
            TextField(e.currentTarget).setSelection(0, 0);
            if (e.text == "close")
            {
                close();
            }
            else if (e.text == "capture")
            {
                if (rollerCaptureKey)
                {
                    setRollerCaptureKey(null);
                }
                else
                {
                    _settingKey = true;
                    sprite.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
                }
				layer.setTooltip(null);
            }
            else if (e.text == "cancel")
            {
                cancelCaptureKeySet();
				layer.setTooltip(null);
            }
            e.stopPropagation();
        }

        private function cancelCaptureKeySet():void
        {
            _settingKey = false;
            if (sprite.stage)
                sprite.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
        }

        private function keyDownHandler(e:KeyboardEvent):void
        {
            if (!e.charCode)
                return;
            var char:String = String.fromCharCode(e.charCode);
            cancelCaptureKeySet();
            setRollerCaptureKey(char, e.shiftKey, e.ctrlKey, e.altKey);
			layer.setTooltip(null);
        }
    }
}