package com.junkbyte.console.view
{
    import com.junkbyte.console.events.ConsolePanelEvent;
    
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.geom.Point;

    public class PanelMover extends PanelDragger
    {
        protected var _snapping:PanelSnapper;

        protected var _dragOffset:Point;
		
		protected var count:uint;

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
