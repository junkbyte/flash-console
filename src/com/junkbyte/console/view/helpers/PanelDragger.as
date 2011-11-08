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
