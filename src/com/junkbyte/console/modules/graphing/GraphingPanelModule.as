package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.view.ConsolePanel;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class GraphingPanelModule extends ConsolePanel
	{

		protected var _group:GraphingGroup;

		protected var _text:GraphingText;

		private var _bm:Bitmap;
		private var _bmd:BitmapData;

		private var lastLow:Number;
		private var lastHigh:Number;
		private var lastValues:Object = new Object();

		public function GraphingPanelModule(group:GraphingGroup)
		{
			super();
			
			_group = group;
		}

		public function get group():GraphingGroup
		{
			return _group;
		}

		override protected function initToConsole():void
		{
			super.initToConsole();
			
			_text = new GraphingText(this, group);
			
			group.addEventListener(GraphingGroupEvent.PUSH, onPushEvent);
			startPanelResizer();

			registerMoveDragger(background);

			minSize.x = 32;
			minSize.y = 26;

			_bm = new Bitmap();
			_bm.y = style.menuFontSize;
			addChild(_bm);


			setPanelSize(80, 40);
			addToLayer();
		}

		override protected function unregisteredFromConsole():void
		{
			_group.removeEventListener(GraphingGroupEvent.PUSH, onPushEvent);
			_group = null;
			super.unregisteredFromConsole();
		}

		override protected function resizePanel(w:Number, h:Number):void
		{
			_text.setArea(0,0,w, h);
			super.resizePanel(w, h);
			updateBitmapSize();
		}

		private function updateBitmapSize():void
		{
			var w:uint = width - 5;
			var h:int = height - _bm.y;
			if (h < 3)
			{
				h = 3;
			}
			if (w < 1)
			{
				w = 1;
			}
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
			lastLow = lastHigh = NaN;
			lastValues = new Object();
		}

		private function onPushEvent(event:GraphingGroupEvent):void
		{
			var values:Vector.<Number> = event.values;

			pushValuesToGraph(values);
			
			_text.update(event);
		}

		private function pushValuesToGraph(values:Vector.<Number>):void
		{
			var lowest:Number = isNaN(group.fixedMin) ? lastLow : group.fixedMin;
			var highest:Number = isNaN(group.fixedMax) ? lastHigh : group.fixedMax;

			for each (var v:Number in values)
			{
				if (isNaN(group.fixedMin) && (isNaN(lowest) || v < lowest))
				{
					lowest = v;
				}
				if (isNaN(group.fixedMax) && (isNaN(highest) || v > highest))
				{
					highest = v;
				}
			}

			if (lastLow != lowest || lastHigh != highest)
			{
				scaleBitmapData(lowest, highest);
			}
			draw(highest, lowest, values);
			lastLow = lowest;
			lastHigh = highest;
		}

		private function scaleBitmapData(newLow:Number, newHigh:Number):void
		{
			var scaleBMD:BitmapData = _bmd.clone();
			
			_bmd.fillRect(new Rectangle(0, 0, _bmd.width, _bmd.height), 0);
			
			var oldDiff:Number = lastHigh - lastLow;
			var newDiff:Number = newHigh - newLow;
			
			var matrix:Matrix = new Matrix();
			matrix.ty = (newHigh-lastHigh) / oldDiff * _bmd.height;
			matrix.scale(1, oldDiff / newDiff);
			_bmd.draw(scaleBMD, matrix, null, null, null, true);
			scaleBMD.dispose();
		}

		private function draw(highest:Number, lowest:Number, values:Vector.<Number>):void
		{
			var diffGraph:Number = highest - lowest;
			var pixX:uint = _bmd.width - 1;

			var H:int = _bmd.height;

			_bmd.lock();

			_bmd.scroll(-1, 0);
			_bmd.fillRect(new Rectangle(pixX, 0, 1, _bmd.height), 0);

			for (var i:int = _group.lines.length - 1; i >= 0; i--)
			{
				var interest:GraphingLine = _group.lines[i];
				var value:Number = values[i];
				var pixY:int = ((value - lowest) / diffGraph) * H;
				pixY = makePercentValue(pixY);

				var lastValue:Number = lastValues[i];

				if (isNaN(lastValue) == false)
				{
					var pixY2:int = ((lastValue - lowest) / diffGraph) * H;
					pixY2 = makePercentValue(pixY2);
					var min:int = Math.min(pixY, pixY2);
					var max:int = Math.max(pixY, pixY2);
					_bmd.fillRect(new Rectangle(pixX, min, 1, Math.max(1, max - min)), interest.color + 0xFF000000);
				}
				_bmd.setPixel32(pixX, pixY, interest.color + 0xFF000000);

				lastValues[i] = value;
			}
			_bmd.unlock();
		}

		private function makePercentValue(value:Number):Number
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
