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
    
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import com.junkbyte.console.view.ConsolePanel;

    public class PanelMover extends PanelDragger
    {
        protected var _snapping:PanelSnapper;

        protected var _dragOffset:Point;

        public function PanelMover(panel:ConsolePanel)
        {
            super(panel);
        }
		
		public function registerDragger(mc:DisplayObject):void
		{
			mc.addEventListener(MouseEvent.MOUSE_DOWN, onDraggerMouseDown);
		}
		
		public function unregisterDragger(mc:DisplayObject):void
		{
			mc.removeEventListener(MouseEvent.MOUSE_DOWN, onDraggerMouseDown);
		}

        override public function start():void
        {
			if (isActive || panel.sprite.stage == null)
			{
				return;
			}
			
            _snapping = new PanelSnapper(panel);

            _dragOffset = new Point(panel.sprite.mouseX, panel.sprite.mouseY);

            super.start();
			
			
			panel.dispatchEvent(ConsolePanelEvent.create(ConsolePanelEvent.STARTED_MOVING));
        }
		
		
		override public function stop():void
		{
			if (!isActive)
			{
				return;
			}
			super.stop();
			
			panel.dispatchEvent(ConsolePanelEvent.create(ConsolePanelEvent.STOPPED_MOVING));
		}

        override protected function onMouseMove(e:MouseEvent = null):void
        {
            var p:Point = _snapping.getSnapFor(panel.parent.mouseX - _dragOffset.x, panel.parent.mouseY - _dragOffset.y);
            panel.x = p.x;
            panel.y = p.y;
            updateTextField();
        }

        override protected function updateTextField():void
        {
            textField.text = "<low>" + panel.x + "," + panel.y + "</low>";
        }
    }
}
