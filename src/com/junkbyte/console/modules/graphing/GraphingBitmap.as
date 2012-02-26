package com.junkbyte.console.modules.graphing
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	public class GraphingBitmap
	{
		protected var _panel:GraphingPanelModule;
		protected var _group:GraphingGroup;

		protected var _bm:Bitmap;
		protected var _bmd:BitmapData;

		protected var lowestValue:Number;
		protected var highestValue:Number;
		protected var lastValues:Object = new Object();
		
		private var lineRect:Rectangle = new Rectangle(0, 0, 1);

		public function GraphingBitmap(panel:GraphingPanelModule, group:GraphingGroup)
		{
			_panel = panel;
			_group = group;
			initDisplay();
		}

		protected function initDisplay():void
		{

			_bm = new Bitmap();
			_panel.addChild(_bm);
		}

		public function setArea(x:Number, y:Number, w:Number, h:Number):void
		{
			_bm.y = y;
			if (_bmd != null && _bmd.width == w && _bmd.height == h)
			{
				return;
			}
			var prevBMD:BitmapData = _bmd;
			_bmd = new BitmapData(w, h, true, 0);
			if (prevBMD != null)
			{
				var matrix:Matrix = new Matrix(1, 0, 0, _bmd.height / prevBMD.height);
				matrix.tx = _bmd.width - prevBMD.width;
				_bmd.draw(prevBMD, matrix, null, null, null, true);
				prevBMD.dispose();
			}
			_bm.bitmapData = _bmd;
		}

		public function reset():void
		{
			lowestValue = highestValue = NaN;
			lastValues = new Object();
		}

		public function push(values:Vector.<Number>):void
		{
			var lowest:Number = isNaN(_group.fixedMin) ? lowestValue : _group.fixedMin;
			var highest:Number = isNaN(_group.fixedMax) ? highestValue : _group.fixedMax;

			for each (var v:Number in values)
			{
				if (isNaN(_group.fixedMin) && (isNaN(lowest) || v < lowest))
				{
					lowest = v;
				}
				if (isNaN(_group.fixedMax) && (isNaN(highest) || v > highest))
				{
					highest = v;
				}
			}

			if (lowestValue != lowest || highestValue != highest)
			{
				scaleBitmapData(lowest, highest);
			}
			draw(values);
		}

		protected function scaleBitmapData(newLow:Number, newHigh:Number):void
		{
			var scaleBMD:BitmapData = _bmd.clone();
			_bmd.fillRect(new Rectangle(0, 0, _bmd.width, _bmd.height), 0);
			
			var newDiff:Number = newHigh - newLow;
			
			var valuePerPixel:Number = newDiff / _bmd.height;
			var valuePerHalfPixel:Number = valuePerPixel * 0.5;
			newHigh += valuePerHalfPixel;
			newLow -= valuePerHalfPixel;
			
			newDiff = newHigh - newLow;
			
			var oldDiff:Number = highestValue - lowestValue;
			
			var matrix:Matrix = new Matrix();
			if(_group.inverted)
			{
				matrix.ty = (lowestValue - newLow) / oldDiff * _bmd.height;
			}
			else
			{
				matrix.ty = ( newHigh - highestValue) / oldDiff * _bmd.height;
			}
			matrix.scale(1, oldDiff / newDiff);
			_bmd.draw(scaleBMD, matrix, null, null, null, true);
			
			scaleBMD.dispose();
			
			lowestValue = newLow;
			highestValue = newHigh;
		}

		protected function draw(values:Vector.<Number>):void
		{
			var diffValue:Number = highestValue - lowestValue;
			var pixX:uint = _bmd.width - 1;

			var bmdHeight:int = _bmd.height;

			_bmd.lock();

			_bmd.scroll(-1, 0);
			_bmd.fillRect(new Rectangle(pixX, 0, 1, _bmd.height), 0);

			for (var i:int = _group.lines.length - 1; i >= 0; i--)
			{
				var interest:GraphingLine = _group.lines[i];
				var value:Number = values[i];
				var pixY:int = ((value - lowestValue) / diffValue) * bmdHeight;
				pixY = makePercentValue(pixY);

				var lastValue:Number = lastValues[i];

				var connectionColor:uint = interest.color + 0xBB000000;

				if (isNaN(lastValue) == false)
				{
					var prevPixY:int = ((lastValue - lowestValue) / diffValue) * bmdHeight;
					prevPixY = makePercentValue(prevPixY);
					
					lineRect.x = pixX;
					var half:Number;
					if (pixY < prevPixY)
					{
						half = (prevPixY - pixY) * 0.5;
						lineRect.y = pixY;
						lineRect.height = half;
						_bmd.fillRect(lineRect, connectionColor);
						lineRect.x--;
						lineRect.y = pixY + half;
						_bmd.fillRect(lineRect, connectionColor);
					}
					else
					{
						half = (pixY - prevPixY) * 0.5;
						lineRect.y = prevPixY + half;
						lineRect.height = half;
						
						_bmd.fillRect(lineRect, connectionColor);
						lineRect.x--;
						lineRect.y = prevPixY;
						_bmd.fillRect(lineRect, connectionColor);
					}
				}
				_bmd.setPixel32(pixX, pixY, interest.color + 0xFF000000);

				lastValues[i] = value;
			}
			_bmd.unlock();
		}

		protected function makePercentValue(value:Number):Number
		{
			if (!_group.inverted)
			{
				value = _bmd.height - value;
			}
			if (value < 0)
			{
				value = 0;
			}
			if (value >= _bmd.height)
			{
				value = _bmd.height - 1;
			}
			return value;
		}
	}
}
