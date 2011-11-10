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
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import com.junkbyte.console.view.ConsolePanel;

    public class PanelDragger
    {
        protected var panel:ConsolePanel;

        protected var textField:TextField;
		
		protected var active:Boolean;

        public function PanelDragger(panel:ConsolePanel)
        {
            this.panel = panel;
			
			panel.addEventListener(Event.CLOSE, onPanelClosed);
        }
		
		protected function onPanelClosed(e:Event):void
		{
			stop();
		}
		
		protected function onDraggerMouseDown(e:MouseEvent):void
		{
			start();
		}
		
		public function get isActive():Boolean
		{
			return active;
		}
		
        public function start():void
        {
			if (isActive)
			{
				return;
			}
			active = true;
			
			textField = new TextField();
			textField.name = "draggingText";
			textField.styleSheet = panel.style.styleSheet;
			textField.background = true;
			textField.backgroundColor = panel.style.backgroundColor;
			
            textField.mouseEnabled = false;
            textField.autoSize = TextFieldAutoSize.LEFT;
			
            panel.addChild(textField);
            updateTextField();

            panel.sprite.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
            panel.sprite.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
        }

        public function stop():void
        {
			if (!isActive)
			{
				return;
			}
			active = false;
			
            if (panel.sprite.stage)
            {
                panel.sprite.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
                panel.sprite.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            }
            if (textField.parent)
            {
                textField.parent.removeChild(textField);
            }

            textField = null;
        }

        protected function onMouseUp(e:MouseEvent):void
        {
			stop();
        }

        protected function onMouseMove(e:MouseEvent = null):void
        {
            // override
        }

        protected function updateTextField():void
        {
            // override
        }
    }
}
