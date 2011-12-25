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

		protected var _textField:TextField;

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

			group.addEventListener(GraphingGroupEvent.PUSH, onPushEvent);
			startPanelResizer();

			registerMoveDragger(background);

			minSize.x = 32;
			minSize.y = 26;

			_textField = new TextField();
			_textField.name = "menuField";
			_textField.autoSize = TextFieldAutoSize.RIGHT;
			_textField.height = style.menuFontSize + 4;
			_textField.y = -3;
			_textField.defaultTextFormat = new TextFormat(style.menuFont, style.menuFontSize, style.menuColor);
			registerMoveDragger(_textField);
			addChild(_textField);

			_bm = new Bitmap();
			_bm.y = style.menuFontSize;
			addChild(_bm);

			setPanelSize(100, 80);
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

			super.resizePanel(w, h);
		}

		private function updateBitmapSize():void
		{
			var w:uint = width - 5;
			var h:int = height - _bm.y;
			if (h <= 0)
			{
				h = 1;
			}
			if (_bmd != null && _bmd.width == w && _bmd.height == h)
			{
				return;
			}
			var prevBMD:BitmapData = _bmd;
			_bmd = new BitmapData(w, h, true, 0);
			if (prevBMD)
			{
				_bmd.draw(prevBMD);
				prevBMD.dispose();
			}
			_bm.bitmapData = _bmd;
		}

		private function scaleBitmapData(newLow:Number, newHigh:Number):void
		{
			var scaleBMD:BitmapData = _bmd.clone();
			_bmd.fillRect(new Rectangle(0, 0, _bmd.width, _bmd.height), 0);
			var matrix:Matrix = new Matrix();
			var oldDiff:Number = lastHigh - lastLow;
			var newDiff:Number = newHigh - newLow;

			matrix.ty = ((lastLow - newLow) / newDiff) * _bmd.height;
			matrix.scale(1, oldDiff / newDiff);
			_bmd.draw(scaleBMD, matrix);
			scaleBMD.dispose();
		}

		private function onPushEvent(event:GraphingGroupEvent):void
		{
			updateBitmapSize();

			var values:Vector.<Number> = event.values;

			var H:int = _bmd.height;

			var lowest:Number = isNaN(group.fixedMin)?lastLow:group.fixedMin;
			var highest:Number = isNaN(group.fixedMax)?lastHigh:group.fixedMax;
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
			_bmd.lock();
			_textField.text = String(values[0]);

			if (lastLow != lowest || lastHigh != highest)
			{
				scaleBitmapData(lowest, highest);
			}
			var diffGraph:Number = highest - lowest;
			var pixX:uint = _bmd.width - 1;

			_bmd.scroll(-1, 0);
			_bmd.fillRect(new Rectangle(pixX, 0, 1, _bmd.height), 0);
			var newValues:Object = new Object();
			for (var i:int = _group.lines.length - 1; i >= 0; i--)
			{
				var interest:GraphingLine = _group.lines[i];
				var value:Number = values[i];
				var pixY:int = ((value - lowest) / diffGraph) * H;
				pixY = makePercentValue(pixY);

				var lastValue:Number = lastValues[interest.key];
				if (isNaN(lastValue) == false)
				{
					var pixY2:int = ((lastValue - lowest) / diffGraph) * H;
					pixY2 = makePercentValue(pixY2);
					var min:int = Math.min(pixY, pixY2);
					var max:int = Math.max(pixY, pixY2);
					_bmd.fillRect(new Rectangle(pixX, min, 1, Math.max(1, max - min)), interest.color + 0xFF000000);
				}
				_bmd.setPixel32(pixX, pixY, interest.color + 0xFF000000);

				newValues[interest.key] = value;
			}
			_bmd.unlock();
			lastLow = lowest;
			lastHigh = highest;
			lastValues = newValues;
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
