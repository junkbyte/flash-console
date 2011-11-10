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
	import flash.geom.Point;
	import com.junkbyte.console.view.ConsoleLayer;
	import com.junkbyte.console.view.ConsolePanel;

	public class PanelSnapper
	{
		protected var panel:ConsolePanel;
		
		private var _snaps:Array;
		
		public function PanelSnapper(panel:ConsolePanel)
		{
			this.panel = panel;
			updateSnaps();
		}
		
		public function getSnapFor(X:Number, Y:Number):Point
		{
			var xsnap:Number = getSnapOf(X, panel.width, _snaps[0]);
			var ysnap:Number = getSnapOf(Y, panel.height, _snaps[1]);
			
			return new Point(xsnap, ysnap);
		}
		
		private function getSnapOf(start:Number, size:Number, snapsOnAxis:Array):Number
		{
			var s:int = panelSnapping;
			if(s > 0)
			{
				for each (var ii:Number in snapsOnAxis)
				{
					if (Math.abs(ii - start) < s)
						return ii;
					if (Math.abs(ii - start - size) < s)
						return ii - size;
				}
			}
			return start;
		}
		
		private function get panelSnapping():int
		{
			return panel.style.panelSnapping;
		}
		
		private function updateSnaps():void
		{
			var X:Array = [ 0 ];
			var Y:Array = [ 0 ];
			if (panelSnapping > 0)
			{
				var layer:ConsoleLayer = panel.layer;
				if (layer.stage)
				{
					// this will only work if stage size is not changed or top left aligned
					X.push(layer.stage.stageWidth);
					Y.push(layer.stage.stageHeight);
				}
				var numchildren:int = layer.numChildren;
				for (var i:int = 0; i < numchildren; i++)
				{
					var panel:ConsolePanel = layer.getChildAt(i) as ConsolePanel;
					if (panel && panel.sprite.visible)
					{
						X.push(panel.x, panel.x + panel.width);
						Y.push(panel.y, panel.y + panel.height);
					}
				}
			}
			_snaps = new Array(X, Y);
		}
	}
}