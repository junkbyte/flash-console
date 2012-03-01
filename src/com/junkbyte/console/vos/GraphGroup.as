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
package com.junkbyte.console.vos
{
	import com.junkbyte.console.console_internal;
	import com.junkbyte.console.core.CcCallbackDispatcher;
	
	import flash.display.StageAlign;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	use namespace console_internal;

	[Event(name = "close", type = "flash.events.Event")]
	public class GraphGroup extends EventDispatcher
	{
		public var name:String;

		public var freq:int = 1; // 0 = every frame, 500 = twice per second, 1000 = once every second

		/**
		 * Fix graph's range.
		 * When fixed, graph will only show within the fixed value however offset the real values may be.
		 * <p>
		 * For example: if the graph is fixed between 100 and 200, and the graph value at one point is 300,
		 * graph will not expand to accompany up to value 10, but remain fixed to 100 - 200 range.
		 * Pass NaN to min or max to unfix graph.
		 * No effect if no graph of the name exists.
		 * </p>
		 */
		public var fixedMin:Number;
		public var fixedMax:Number;

		public var inverted:Boolean;
		public var interests:Array = [];

		public var numberDisplayPrecision:uint = 4;

		public var alignRight:Boolean;
		public var rect:Rectangle = new Rectangle(0, 0, 80, 40);
		//
		protected var _updateArgs:Array = new Array();
		protected var sinceLastUpdate:uint;
		protected var updateDispatcher:CcCallbackDispatcher = new CcCallbackDispatcher();

		//
		//

		public function GraphGroup(n:String)
		{
			name = n;
			_updateArgs.push(this);
		}

		public function tick(timeDelta:uint):void
		{
			sinceLastUpdate += timeDelta;

			if (sinceLastUpdate >= freq)
			{
				update();
			}
		}

		public function update():void
		{
			sinceLastUpdate = 0;
			dispatchUpdates();
		}

		protected function dispatchUpdates():void
		{
			for (var i:int = interests.length - 1; i >= 0; i--)
			{
				var graph:GraphInterest = interests[i];
				var v:Number = graph.getCurrentValue();
				_updateArgs[i + 1] = v;
			}
			applyUpdateDispather(_updateArgs);
		}
		
		console_internal function applyUpdateDispather(args:Array):void
		{
			updateDispatcher.apply(args);
		}

		public function addUpdateListener(listener:Function):void
		{
			updateDispatcher.add(listener);
		}

		public function removeUpdateListener(listener:Function):void
		{
			updateDispatcher.remove(listener);
		}

		public function close():void
		{
			updateDispatcher.clear();
			dispatchEvent(new Event(Event.CLOSE));
		}

		//
		//
		//
		public function writeToBytes(bytes:ByteArray):void
		{
			bytes.writeUTF(name);
			bytes.writeDouble(fixedMin);
			bytes.writeDouble(fixedMax);
			bytes.writeBoolean(inverted);

			bytes.writeBoolean(alignRight);

			bytes.writeFloat(rect.x);
			bytes.writeFloat(rect.y);
			bytes.writeFloat(rect.width);
			bytes.writeFloat(rect.height);

			bytes.writeUnsignedInt(interests.length);

			for each (var gi:GraphInterest in interests)
			{
				gi.toBytes(bytes);
			}
		}

		public static function FromBytes(bytes:ByteArray):GraphGroup
		{
			var g:GraphGroup = new GraphGroup(bytes.readUTF());
			g.fixedMin = bytes.readDouble();
			g.fixedMax = bytes.readDouble();
			g.inverted = bytes.readBoolean();

			g.alignRight = bytes.readBoolean();

			var rect:Rectangle = g.rect;
			rect.x = bytes.readFloat();
			rect.y = bytes.readFloat();
			rect.width = bytes.readFloat();
			rect.height = bytes.readFloat();

			var len:uint = bytes.readUnsignedInt();
			while (len)
			{
				g.interests.push(GraphInterest.FromBytes(bytes));
				len--;
			}
			return g;
		}
	}
}
