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
    import com.junkbyte.console.events.ConsolePanelEvent;

    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import com.junkbyte.console.view.helpers.PanelMover;
    import com.junkbyte.console.view.helpers.PanelResizer;

    [Event(name = "close", type = "flash.events.Event")]
    [Event(name = "startedMoving", type = "com.junkbyte.console.events.ConsolePanelEvent")]
    [Event(name = "stoppedMoving", type = "com.junkbyte.console.events.ConsolePanelEvent")]
    [Event(name = "startedScaling", type = "com.junkbyte.console.events.ConsolePanelEvent")]
    [Event(name = "stoppedScaling", type = "com.junkbyte.console.events.ConsolePanelEvent")]
    [Event(name = "panelResized", type = "com.junkbyte.console.events.ConsolePanelEvent")]
    public class ConsolePanel extends ConsoleDisplayModule
    {
        protected var panelMover:PanelMover;

        protected var background:Sprite;

        protected var minSize:Point = new Point(18, 18);

        public function ConsolePanel()
        {
            super();

            createBackground();
        }

        // override for init
        override protected function initToConsole():void
        {
            drawBackground();
        }

        protected function createBackground():void
        {
            background = new Sprite();
            background.name = "background";
            addChild(background);
        }

        protected function drawBackground(col:Number = -1, a:Number = -1, rounding:int = -1):void
        {
            if (background == null)
            {
                return;
            }
            background.graphics.clear();
            background.graphics.beginFill(col >= 0 ? col : style.backgroundColor, a >= 0 ? a : style.backgroundAlpha);
            if (rounding < 0)
                rounding = style.roundBorder;
            if (rounding <= 0)
                background.graphics.drawRect(0, 0, 100, 100);
            else
            {
                background.graphics.drawRoundRect(0, 0, rounding + 10, rounding + 10, rounding, rounding);
                background.scale9Grid = new Rectangle(rounding * 0.5, rounding * 0.5, 10, 10);
            }
        }

        public function close():void
        {
            dispatchEvent(new Event(Event.CLOSE));
            if (parent != null)
            {
                parent.removeChild(sprite);
            }
        }

        public function get width():Number
        {
            return background.width;
        }

        public function set width(n:Number):void
        {
            setPanelSize(n, height);
        }

        public function get height():Number
        {
            return background.height;
        }

        public function set height(n:Number):void
        {
            setPanelSize(width, n);
        }

        public function setPanelSize(w:Number, h:Number):void
        {
            if (w < minSize.x)
            {
                w = minSize.x;
            }
            if (h < minSize.y)
            {
                h = minSize.y;
            }
            resizePanel(w, h);
        }

        protected function resizePanel(w:Number, h:Number):void
        {
            background.width = w;
            background.height = h;

            dispatchEvent(ConsolePanelEvent.create(ConsolePanelEvent.PANEL_RESIZED));
        }

        public function registerMoveDragger(mc:DisplayObject):void
        {
            if (panelMover == null)
            {
                panelMover = createMoveDragger();
            }
            panelMover.registerDragger(mc);
        }

        public function unregisterMoveDragger(mc:DisplayObject):void
        {
            if (panelMover != null)
            {
                panelMover.unregisterDragger(mc);
            }
        }

        protected function createMoveDragger():PanelMover
        {
            return new PanelMover(this);
        }

        protected function startPanelResizer():void
        {
            new PanelResizer(this);
        }
    }
}
