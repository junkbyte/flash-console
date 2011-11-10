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
package com.junkbyte.console.view.helpers
{
    import com.junkbyte.console.events.ConsolePanelEvent;

    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import com.junkbyte.console.view.ConsolePanel;

    public class PanelResizer extends PanelDragger
    {

        protected var scaler:Sprite;

        protected var _snapping:PanelSnapper;

        protected var _dragOffset:Point;

        public function PanelResizer(panel:ConsolePanel)
        {
            super(panel);


            scaler = new Sprite();
            scaler.name = "scaler";
            scaler.graphics.beginFill(0, 0);
            scaler.graphics.drawRect(-10, -18, 10, 18);
            scaler.graphics.endFill();
            scaler.graphics.beginFill(panel.style.controlColor, panel.style.backgroundAlpha);
            scaler.graphics.moveTo(0, 0);
            scaler.graphics.lineTo(-10, 0);
            scaler.graphics.lineTo(0, -10);
            scaler.graphics.endFill();
            scaler.buttonMode = true;
            scaler.doubleClickEnabled = true;
			
            scaler.addEventListener(MouseEvent.MOUSE_DOWN, onDraggerMouseDown);

            panel.addChild(scaler);

            panel.addEventListener(ConsolePanelEvent.PANEL_RESIZED, onPanelResized);
        }

        protected function onPanelResized(e:Event):void
        {
            scaler.x = panel.width;
            scaler.y = panel.height;
        }

        override public function start():void
        {
            if (isActive)
            {
                return;
            }
            _snapping = new PanelSnapper(panel);

            _dragOffset = new Point(panel.width - panel.sprite.mouseX, panel.height - panel.sprite.mouseY);

            super.start();

            panel.dispatchEvent(ConsolePanelEvent.create(ConsolePanelEvent.STARTED_RESIZING));
        }


        override public function stop():void
        {
            if (!isActive)
            {
                return;
            }
            super.stop();

            panel.dispatchEvent(ConsolePanelEvent.create(ConsolePanelEvent.STOPPED_RESIZING));
        }

        override protected function onMouseMove(e:MouseEvent = null):void
        {
            var p:Point = _snapping.getSnapFor(panel.parent.mouseX + _dragOffset.x, panel.parent.mouseY + _dragOffset.y);
            p.x -= panel.x;
            p.y -= panel.y;
            panel.setPanelSize(p.x, p.y);
            updateTextField();
        }

        override protected function updateTextField():void
        {
            textField.text = "<low>" + panel.width + "," + panel.height + "</low>";
            textField.x = panel.width - textField.width - 5;
            textField.y = panel.height - textField.height - 5;
        }
    }
}
