package com.junkbyte.console.modules.graphing.custom
{
	import com.junkbyte.console.view.ConsolePanel;
	
	import flash.geom.Rectangle;
	import com.junkbyte.console.modules.graphing.GraphingGroup;

	public class CustomGraphingGroup extends GraphingGroup
	{
		
		public var area:Rectangle;
		
		public function CustomGraphingGroup()
		{
			super();
		}
		
		
		
		override public function createPanel():ConsolePanel
		{
			return new CustomGraphingPanelModule(this);
		}
		
		
		public function hasPanelPositioning():Boolean
		{
			return !(isNaN(area.x) && isNaN(area.y));
		}
		
		public function setPanelPosition(panel:ConsolePanel):void
		{
			if(area != null)
			{
				if(!isNaN(area.x))
				{
					panel.x = area.x;
				}
				if(!isNaN(area.y))
				{
					panel.y = area.y;
				}
				
				if(!isNaN(area.width) && !isNaN(area.height))
				{
					panel.setPanelSize(panel.width, panel.height);
				}
				else if(!isNaN(area.width))
				{
					panel.width = area.width;
				}
				else if(!isNaN(area.height))
				{
					panel.height = area.height;
				}
			}
		}
	}
}