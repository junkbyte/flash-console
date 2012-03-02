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
	import flash.display.StageAlign;
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

		private var _menuString:String;
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
		public function GraphingPanel(m:Console, group:GraphGroup)
		{
			super(m);
			_group = group;
			name = group.name;
			registerDragger(bg);
			minWidth = 32;
			minHeight = 26;
			//
			var textFormat:TextFormat = new TextFormat();
			var lowStyle:Object = style.styleSheet.getStyle("low");
			textFormat.font = lowStyle.fontFamily;
			textFormat.size = lowStyle.fontSize;
			textFormat.color = style.lowColor;
			
			_bm = new Bitmap();
			_bm.name = "graph";
			_bm.y = style.menuFontSize - 2;
			addChild(_bm);
			
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

			_menuString = "<menu>";
			/*if (_type == MEM)
			{
				_menuString += " <a href=\"event:gc\">G</a> ";
			}*/
			_menuString += "<a href=\"event:reset\">R</a> <a href=\"event:close\">X</a></menu></low></r>";

			_group.addUpdateListener(onGroupUpdate);
			//
			var rect:Rectangle = group.rect;
			var w:Number = Math.max(minWidth, rect.width);
			var h:Number = Math.max(minHeight, rect.height);
			var mainPanel:MainPanel = console.panels.mainPanel;
			x = mainPanel.x+rect.x;
			y = mainPanel.y+rect.y;
			if(group.alignRight)
			{
				x = mainPanel.x+mainPanel.width-x;
			}
			
			init(w, h, true);
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
			
		}
		
		protected function onGroupUpdate(groupvalues:Array):void
		{
			var interests:Array = _group.interests;
			var listchanged:Boolean = false;
			var interest:GraphInterest;
			
			var lowest:Number = isNaN(_group.fixedMin) ? lowestValue : _group.fixedMin;
			var highest:Number = isNaN(_group.fixedMax) ? highestValue : _group.fixedMax;
			var numInterests:uint = interests.length;
			for (var i:uint = 0; i<numInterests; i++)
			{
				interest = interests[i];

				var v:Number = groupvalues[i + 1];
				if (isNaN(_group.fixedMin) && (isNaN(lowest) || v < lowest))
				{
					lowest = v;
				}
				if (isNaN(_group.fixedMax) && (isNaN(highest) || v > highest))
				{
					highest = v;
				}
			}
			
			updateKeyText(groupvalues);
			
			if(lowestValue != lowest || highestValue != highest)
			{
				scaleBitmapData(lowest, highest);
				if(group.inverted)
				{
					highTxt.text = makeValueString(lowest);
					lowTxt.text = makeValueString(highest);
				}
				else
				{
					lowTxt.text = makeValueString(lowest);
					highTxt.text = makeValueString(highest);
				}
			}
			
			pushBMD(groupvalues);
		}

		protected function pushBMD(groupvalues:Array):void
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
				var value:Number = groupvalues[i + 1];
				var pixY:int = getPixelValue(value);

				var lastValue:Number = lastValues[i];

				var connectionColor:uint = interest.col + 0xFF000000;

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
				_bmd.setPixel32(pixX, pixY, connectionColor);

				lastValues[i] = value;
			}
			_bmd.unlock();
		}

		protected function getPixelValue(value:Number):Number
		{
			if(highestValue == lowestValue)
			{
				return _bmd.height * 0.5;
			}
			value = ((value - lowestValue) / (highestValue - lowestValue)) * _bmd.height;
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

		protected function scaleBitmapData(newLow:Number, newHigh:Number):void
		{
			var scaleBMD:BitmapData = _bmd.clone();
			_bmd.fillRect(_bmd.rect, 0);

			var newDiff:Number = newHigh - newLow;
			
			if(newDiff == 0)
			{
				lowestValue = newLow;
				highestValue = newHigh;
				return;
			}
			//
			// Try to pixel round outside given value so that it reduces the need to rescale.
			var valuePerPixel:Number = newDiff / _bmd.height;
			var valuePerHalfPixel:Number = valuePerPixel * 0.5;
			newHigh += valuePerPixel;
			newLow -= valuePerPixel;
			if (!isNaN(_group.fixedMax) && newHigh > _group.fixedMax)
			{
				newHigh = _group.fixedMax;
			}
			if (!isNaN(_group.fixedMin) && newLow < _group.fixedMin)
			{
				newLow = _group.fixedMin;
			}
			//

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

		public function updateKeyText(groupvalues:Array):void
		{
			var str:String = "<r><low>";
			
			var numInterests:uint = _group.interests.length;
			for (var i:uint = 0; i<numInterests; i++)
			{
				var interest:GraphInterest = _group.interests[i];
				str += "<font color='#" + interest.col.toString(16) + "'>" + makeValueString(groupvalues[i+1]) + interest.key+"</font> ";
			}
			txtField.htmlText = str + _menuString;
			txtField.scrollH = txtField.maxScrollH;
		}
		
		private function makeValueString(value:Number):String
		{
			var precision:uint = _group.numberDisplayPrecision;
			if(precision == 0 || value == 0)
			{
				return String(value);
			}
			return value.toPrecision(precision);
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
				_group.close();
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
