package com.junkbyte.console.view
{
    import com.junkbyte.console.events.ConsolePanelEvent;

    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;

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
