package com.junkbyte.console.view
{

    import com.junkbyte.console.ConsoleStyle;
    import com.junkbyte.console.core.ModuleTypeMatcher;
    import com.junkbyte.console.events.ConsoleLayerEvent;
    import com.junkbyte.console.modules.ConsoleModuleNames;
    
    import flash.events.Event;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;

    public class ToolTipModule extends ConsoleDisplayModule
    {

        private var _tooltipField:TextField;

        public function ToolTipModule()
        {			
			addModuleRegisteryCallback(new ModuleTypeMatcher(StageModule), onAddedToStage, onRemovedFromStage);
        }
		
		override public function getModuleName():String
		{
			return ConsoleModuleNames.TOOLTIPS;
		}
		
		override protected function registeredToConsole():void
		{
			layer.addEventListener(ConsoleLayerEvent.PANEL_ADDED, onPanelAdded);
			layer.addEventListener(ConsoleLayerEvent.PANEL_REMOVED, onPanelRemoved);
			super.registeredToConsole();
		}
		
		override protected function unregisteredFromConsole():void
		{
			layer.removeEventListener(ConsoleLayerEvent.PANEL_ADDED, onPanelAdded);
			layer.removeEventListener(ConsoleLayerEvent.PANEL_REMOVED, onPanelRemoved);
			super.unregisteredFromConsole();
		}

		private function onPanelAdded(event:ConsoleLayerEvent):void
		{
			if (layer.contains(sprite))
			{
				layer.addChild(sprite);
			}
		}
		
		private function onPanelRemoved(event:ConsoleLayerEvent):void
		{
			setTooltip(null);
		}
		
		private function onAddedToStage(stage:StageModule):void
		{
			stage.stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave, false, 0, true);
		}
		
		private function onRemovedFromStage(stage:StageModule):void
		{
			stage.stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onStageMouseLeave(e:Event):void
		{
			setTooltip("");
		}

        override protected function initToConsole():void
        {
            initToolTip();
        }

        private function initToolTip():void
        {
            var style:ConsoleStyle = console.config.style;
            _tooltipField = new TextField();
            _tooltipField.name = "tooltip";
            _tooltipField.styleSheet = style.styleSheet;
            _tooltipField.background = true;
            _tooltipField.backgroundColor = style.backgroundColor;
            _tooltipField.mouseEnabled = false;
            _tooltipField.autoSize = TextFieldAutoSize.CENTER;
            _tooltipField.multiline = true;
        }

        public function setTooltip(str:String, panel:ConsolePanel = null):void
        {
            if (str)
            {
                var split:Array = str.split("::");
                str = split[0];
                if (split.length > 1)
                {
                    str += "<br/><low>" + split[1] + "</low>";
                }
                addChild(_tooltipField);
                _tooltipField.wordWrap = false;
                _tooltipField.htmlText = "<tt>" + str + "</tt>";
                if (_tooltipField.width > 120)
                {
                    _tooltipField.width = 120;
                    _tooltipField.wordWrap = true;
                }
                _tooltipField.x = layer.mouseX - (_tooltipField.width / 2);
                _tooltipField.y = layer.mouseY + 20;
                if (panel)
                {
                    var txtRect:Rectangle = _tooltipField.getBounds(layer);
                    var panRect:Rectangle = new Rectangle(panel.x, panel.y, panel.width, panel.height);
                    var doff:Number = txtRect.bottom - panRect.bottom;
                    if (doff > 0)
                    {
                        if ((_tooltipField.y - doff) > (layer.mouseY + 15))
                        {
                            _tooltipField.y -= doff;
                        }
                        else if (panRect.y < (layer.mouseY - 24) && txtRect.y > panRect.bottom)
                        {
                            _tooltipField.y = layer.mouseY - _tooltipField.height - 15;
                        }
                    }
                    var loff:Number = txtRect.left - panRect.left;
                    var roff:Number = txtRect.right - panRect.right;
                    if (loff < 0)
                    {
                        _tooltipField.x -= loff;
                    }
                    else if (roff > 0)
                    {
                        _tooltipField.x -= roff;
                    }
                }
				layer.addChild(sprite);
            }
            else if (layer.contains(sprite))
            {
				layer.removeChild(sprite);
            }
        }
    }
}
