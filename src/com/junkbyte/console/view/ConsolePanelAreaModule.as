package com.junkbyte.console.view
{

    import com.junkbyte.console.view.mainPanel.MainPanel;
    
    import flash.geom.Rectangle;

    public class ConsolePanelAreaModule extends ConsoleDisplayModule
    {

        private var parentPanel:ConsolePanel;

        private var _area:Rectangle = new Rectangle();

        public function ConsolePanelAreaModule(parentPanel:ConsolePanel)
        {
            super();
            this.parentPanel = parentPanel;
        }

        override protected function registeredToConsole():void
        {
            super.registeredToConsole();

            if (parentPanel != null)
            {
                parentPanel.addChild(sprite);
            }
        }

        override protected function unregisteredFromConsole():void
        {
            super.unregisteredFromConsole();

            if (parentPanel != null)
            {
                parentPanel.removeChild(sprite);
            }
        }

        protected function get mainPanel():MainPanel
        {
            return layer.mainPanel;
        }

        public function setArea(x:Number, y:Number, width:Number, height:Number):void
        {
            _area.x = x;
            _area.y = y;
            _area.width = width;
            _area.height = height;
        }

        public function get area():Rectangle
        {
            return _area;
        }
    }
}
