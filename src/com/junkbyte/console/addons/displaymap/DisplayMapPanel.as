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
package com.junkbyte.console.addons.displaymap
{
    import com.junkbyte.console.Console;
    import com.junkbyte.console.core.LogReferences;
    import com.junkbyte.console.view.ConsolePanel;
    
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.TextEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.utils.Dictionary;
	
	/**
	 * @private
	 */
    public class DisplayMapPanel extends ConsolePanel
    {

        public static const NAME:String = "displayMapPanel";

        public static var numOfFramesToUpdate:uint = 10;

        private var rootDisplay:DisplayObject;

        private var mapIndex:uint;

        private var indexToDisplayMap:Object;

        private var openings:Dictionary;

        private var framesSinceUpdate:uint;

        public function DisplayMapPanel(m:Console)
        {
            super(m);
            name = NAME;
            init(60, 100, false);
            txtField = makeTF("mapPrints");
            txtField.multiline = true;
            txtField.autoSize = TextFieldAutoSize.LEFT;
            registerTFRoller(txtField, onMenuRollOver, linkHandler);
            registerDragger(txtField);
            addChild(txtField);
        }

        public function start(container:DisplayObject):void
        {
            rootDisplay = container;
            openings = new Dictionary(true);

            if (rootDisplay == null)
            {
                return;
            }

            rootDisplay.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);

            addToOpening(rootDisplay);
        }

        public function stop():void
        {
            if (rootDisplay == null)
            {
                return;
            }

            rootDisplay.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            rootDisplay = null;
        }

        private function onEnterFrame(event:Event):void
        {
            framesSinceUpdate++;
            if (framesSinceUpdate >= numOfFramesToUpdate)
            {
                framesSinceUpdate = 0;
                update();
            }
        }

        private function update():void
        {
            mapIndex = 0;
            indexToDisplayMap = new Object();

            var string:String = "<p><p3>";

            if (rootDisplay == null)
            {
                string += "null";
            }
            else
            {
                string += "<menu> <a href=\"event:close\"><b>X</b></a></menu><br/>";

                var rootParent:DisplayObjectContainer = rootDisplay.parent;
                if (rootParent)
                {
                    string += "<p5><b>" + makeLink(rootParent, " ^ ", "focus") + "</b>" + makeName(rootParent) + "</p5><br/>";
                    string += printChild(rootDisplay, 1);
                }
                else
                {
                    string += printChild(rootDisplay, 0);
                }
            }

            txtField.htmlText = string + "</p3></p>";

            width = txtField.width + 4;
            height = txtField.height;
        }

        private function printChild(display:DisplayObject, currentStep:uint):String
        {
            if (display == null)
            {
                return "";
            }
            if (display is DisplayObjectContainer)
            {
                var string:String;
                var container:DisplayObjectContainer = display as DisplayObjectContainer;
                if (openings[display] == true)
                {
                    string = "<p5><b>" + generateSteps(display, currentStep) + makeLink(display, "-" + container.numChildren, "minimize") + "</b> " + makeName(display) + "</p5><br/>";
                    string += printChildren(container, currentStep + 1);
                }
                else
                {
                    string = "<p4><b>" + generateSteps(display, currentStep) + makeLink(display, "+" + container.numChildren, "expand") + "</b> " + makeName(display) + "</p4><br/>";
                }
                return string;
            }
            return "<p3>" + generateSteps(display, currentStep) + makeName(display) + "</p3><br/>";
        }

        private function printChildren(container:DisplayObjectContainer, currentStep:uint):String
        {
            var string:String = "";
            var len:uint = container.numChildren;
            for (var i:uint = 0; i < len; i++)
            {
                string += printChild(container.getChildAt(i), currentStep);
            }
            return string;
        }

        private function generateSteps(display:Object, steps:uint):String
        {
            var str:String = "";
            for (var i:uint = 0; i < steps; i++)
            {
                if (i == steps - 1)
                {
                    if (display is DisplayObjectContainer)
                    {
                        str += makeLink(display, " &gt; ", "focus");
                    }
                    else
                    {
                        str += " &gt; ";
                    }
                }
                else
                {
                    str += " · ";
                }
            }
            return str;
        }

        private function onMenuRollOver(e:TextEvent):void
        {
            var txt:String = e.text ? e.text.replace("event:", "") : "";

            if (txt == "close")
            {
                txt = "Close";
            }
            else if (txt.indexOf("expand") == 0)
            {
                txt = "expand";
            }
            else if (txt.indexOf("minimize") == 0)
            {
                txt = "minimize";
            }
            else if (txt.indexOf("focus") == 0)
            {
                txt = "focus";
            }
            else
            {
                txt = null;
            }
            console.panels.tooltip(txt, this);
        }

        private function makeName(display:Object):String
        {
            return makeLink(display, display.name, "scope") + " {<menu>" + makeLink(display, LogReferences.ShortClassName(display), "inspect") + "</menu>}";
        }

        private function makeLink(display:Object, text:String, event:String):String
        {
            mapIndex++;
            indexToDisplayMap[mapIndex] = display;
            return "<a href='event:" + event + "_" + mapIndex + "'>" + text + "</a>";
        }

        private function getDisplay(string:String):DisplayObject
        {
            var split:Array = string.split("_");
            return indexToDisplayMap[split[split.length - 1]];
        }

        protected function linkHandler(e:TextEvent):void
        {
            TextField(e.currentTarget).setSelection(0, 0);
            console.panels.tooltip(null);

            if (e.text == "close")
            {
                close();
            }
            else if (e.text.indexOf("expand") == 0)
            {
                addToOpening(getDisplay(e.text));
            }
            else if (e.text.indexOf("minimize") == 0)
            {
                removeFromOpening(getDisplay(e.text));
            }
            else if (e.text.indexOf("focus") == 0)
            {
                focus(getDisplay(e.text) as DisplayObjectContainer);
            }
            else if (e.text.indexOf("scope") == 0)
            {
                scope(getDisplay(e.text));
            }
            else if (e.text.indexOf("inspect") == 0)
            {
                inspect(getDisplay(e.text));
            }

            e.stopPropagation();
        }

		private function focus(container:DisplayObjectContainer):void
        {
            rootDisplay = container;
            addToOpening(container);
            update();
        }

        private function addToOpening(display:DisplayObject):void
        {
            if (openings[display] == undefined)
            {
                openings[display] = true;
                update();
            }
        }

		private function removeFromOpening(display:DisplayObject):void
        {
            if (openings[display] != undefined)
            {
                delete openings[display];
                update();
            }
        }

        protected function scope(display:DisplayObject):void
        {
            console.cl.setReturned(display, true);
        }

        protected function inspect(display:DisplayObject):void
        {
            console.refs.focus(display);
        }

        override public function close():void
        {
            stop();
            super.close();
        }
    }
}
