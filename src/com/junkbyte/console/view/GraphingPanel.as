/*
*
* Copyright (c) 2008-2010 Lu Aye Oo
*
* @author 		Lu Aye Oo
*
* http://code.google.com/p/flash-console/
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
package com.junkbyte.console.view
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.vos.GraphGroup;
	import com.junkbyte.console.vos.GraphInterest;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.TextEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;

	/**
	 * @private
	 */
	public class GraphingPanel extends ConsolePanel
	{
		//
		public static const FPS:String = "fpsPanel";
		public static const MEM:String = "memoryPanel";
		//
		private var _group:GraphGroup;
		private var _interest:GraphInterest;
		private var _infoMap:Object = new Object();

		private var _menuString:String;
		//
		private var _type:String;
		//
		protected var _bm:Bitmap;
		protected var _bmd:BitmapData;

		protected var lowestValue:Number;
		protected var highestValue:Number;
		protected var lastValues:Object = new Object();

		private var lowTxt:TextField;
		private var highTxt:TextField;
		private var lineRect:Rectangle = new Rectangle(0, 0, 1);

		//
		public function GraphingPanel(m:Console, W:int, H:int, type:String = null)
		{
			super(m);
			_type = type;
			registerDragger(bg);
			minWidth = 32;
			minHeight = 26;
			//
			var textFormat:TextFormat = new TextFormat();
			var lowStyle:Object = style.styleSheet.getStyle("low");
			textFormat.font = lowStyle.fontFamily;
			textFormat.size = lowStyle.fontSize;
			textFormat.color = style.lowColor;

			lowTxt = new TextField();
			lowTxt.name = "lowestField";
			lowTxt.defaultTextFormat = textFormat;
			lowTxt.mouseEnabled = false;
			lowTxt.height = style.menuFontSize + 2;
			addChild(lowTxt);

			highTxt = new TextField();
			highTxt.name = "highestField";
			highTxt.defaultTextFormat = textFormat;
			highTxt.mouseEnabled = false;
			highTxt.height = style.menuFontSize + 2;
			highTxt.y = style.menuFontSize - 4;
			addChild(highTxt);
			//
			txtField = makeTF("menuField");
			txtField.height = style.menuFontSize + 4;
			txtField.y = -3;
			registerTFRoller(txtField, onMenuRollOver, linkHandler);
			registerDragger(txtField); // so that we can still drag from textfield
			addChild(txtField);
			//
			_bm = new Bitmap();
			_bm.name = "graph";
			_bm.y = style.menuFontSize - 2;
			addChild(_bm);
			//

			_menuString = "<menu>";
			if (_type == MEM)
			{
				_menuString += " <a href=\"event:gc\">G</a> ";
			}
			_menuString += "<a href=\"event:reset\">R</a> <a href=\"event:close\">X</a></menu></low></r>";

			//
			init(W, H, true);
		}

		private function stop():void
		{
			if (_group)
			{
				console.graphing.remove(_group.name);
			}
		}

		public function get group():GraphGroup
		{
			return _group;
		}

		public function reset():void
		{
			lowestValue = highestValue = NaN;
			lastValues = new Object();
		}

		override public function set height(n:Number):void
		{
			super.height = n;
			lowTxt.y = n - style.menuFontSize;

			resizeBMD();
		}

		override public function set width(n:Number):void
		{
			super.width = n;
			lowTxt.width = n;
			highTxt.width = n;
			txtField.width = n;
			txtField.scrollH = txtField.maxScrollH;

			resizeBMD();
		}

		private function resizeBMD():void
		{
			var w:Number = width;
			var h:Number = height - style.menuFontSize + 2;
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

		//
		//
		//
		public function update(group:GraphGroup, draw:Boolean):void
		{
			_group = group;
			var interests:Array = group.interests;
			var listchanged:Boolean = false;
			var interest:GraphInterest;
			for each (interest in interests)
			{
				_interest = interest;
				var n:String = _interest.key;
				var info:String = _infoMap[n];
				if (info == null)
				{
					listchanged = true;
					// used to use InterestInfo
					info = _interest.col.toString(16);
					_infoMap[n] = info;
				}

				var v:Number = interest.v;
				if (isNaN(_group.low) && (isNaN(lowest) || v < lowest))
				{
					lowest = v;
				}
				if (isNaN(_group.hi) && (isNaN(highest) || v > highest))
				{
					highest = v;
				}
			}
			for (var X:String in _infoMap)
			{
				var found:Boolean;
				for each (interest in interests)
				{
					if (interest.key == X)
					{
						found = true;
					}
				}
				if (!found)
				{
					listchanged = true;
					delete _infoMap[X];
				}
			}
			if (draw && (listchanged || _type))
			{
				updateKeyText();
			}

			if (draw)
			{

				var lowest:Number = isNaN(_group.low) ? lowestValue : _group.low;
				var highest:Number = isNaN(_group.hi) ? highestValue : _group.hi;

				TextField(group.inv ? highTxt : lowTxt).text = String(lowest);
				TextField(group.inv ? lowTxt : highTxt).text = String(highest);

				if (lowestValue != lowest || highestValue != highest)
				{
					scaleBitmapData(lowest, highest);
				}
				drawBMD();
			}
		}

		protected function drawBMD():void
		{
			var diffValue:Number = highestValue - lowestValue;
			var pixX:uint = _bmd.width - 1;

			var bmdHeight:int = _bmd.height;

			_bmd.lock();

			_bmd.scroll(-1, 0);
			_bmd.fillRect(new Rectangle(pixX, 0, 1, _bmd.height), 0);

			var interests:Array = _group.interests;
			for (var i:int = interests.length - 1; i >= 0; i--)
			{
				var interest:GraphInterest = interests[i];
				var value:Number = interest.v;
				var pixY:int = getPixelValue(value);

				var lastValue:Number = lastValues[i];

				var connectionColor:uint = interest.col + 0xBB000000;

				if (isNaN(lastValue) == false)
				{
					lineRect.x = pixX;
					var prevPixY:int = getPixelValue(lastValue);
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
					else (pixY > prevPixY)
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
				_bmd.setPixel32(pixX, pixY, interest.col + 0xFF000000);

				lastValues[i] = value;
			}
			_bmd.unlock();
		}

		protected function getPixelValue(value:Number):Number
		{
			value = ((value - lowestValue) / (highestValue - lowestValue)) * _bmd.height;
			if (!_group.inv)
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
			matrix.ty = (lowestValue - newLow) / newDiff * _bmd.height;
			matrix.scale(1, oldDiff / newDiff);
			_bmd.draw(scaleBMD, matrix, null, null, null, true);

			scaleBMD.dispose();

			lowestValue = newLow;
			highestValue = newHigh;
		}

		public function updateKeyText():void
		{
			var str:String = "<r><low>";
			if (_type)
			{
				if (isNaN(_interest.v))
				{
					str += "no input";
				}
				else if (_type == FPS)
				{
					str += _interest.avg.toFixed(1);
				}
				else
				{
					str += _interest.v + "mb";
				}
			}
			else
			{
				for (var X:String in _infoMap)
				{
					str += " <font color='#" + _infoMap[X] + "'>" + X + "</font>";
				}
				str += " |";
			}
			txtField.htmlText = str + _menuString;
			txtField.scrollH = txtField.maxScrollH;
		}

		protected function linkHandler(e:TextEvent):void
		{
			TextField(e.currentTarget).setSelection(0, 0);
			if (e.text == "reset")
			{
				reset();
			}
			else if (e.text == "close")
			{
				if (_type == FPS)
				{
					console.fpsMonitor = false;
				}
				else if (_type == MEM)
				{
					console.memoryMonitor = false;
				}
				else
				{
					stop();
				}
				console.panels.removeGraph(_group);
			}
			else if (e.text == "gc")
			{
				console.gc();
			}
			e.stopPropagation();
		}

		protected function onMenuRollOver(e:TextEvent):void
		{
			var txt:String = e.text ? e.text.replace("event:", "") : null;
			if (txt == "gc")
			{
				txt = "Garbage collect::Requires debugger version of flash player";
			}
			console.panels.tooltip(txt, this);
		}
	}
}
