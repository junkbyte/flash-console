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
package com.junkbyte.console.vos {
	import com.junkbyte.console.core.CcCallbackDispatcher;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;


	[Event(name="close", type="flash.events.Event")]
	public class GraphGroup extends EventDispatcher{
		
		public static const FPS:uint = 1;
		public static const MEM:uint = 2;
	
		public var type:uint;
		public var name:String;
		
		public var freq:int = 1; // 0 = every frame, 500 = twice per second, 1000 = once every second
		
		public var fixedMin:Number;
		public var fixedMax:Number;
		
		public var inverted:Boolean;
		public var interests:Array = [];
		
		
		public var align:String;
		public var rect:Rectangle = new Rectangle(0, 0, 80, 40);
		//
		protected var _values:Array = new Array();
		protected var sinceLastUpdate:uint;
		protected var updateDispatcher:CcCallbackDispatcher = new CcCallbackDispatcher();
		//
		//
		public var idle:int;
		
		public function GraphGroup(n:String){
			name = n;
		}
		
		public function tick(timeDelta:uint):void
		{
			sinceLastUpdate += timeDelta;
		}
		
		public function shouldUpdate():Boolean
		{
			if(freq == 0)
			{
				return true;
			}
			return sinceLastUpdate >= freq;
		}
		
		public function updateIfApproate():void
		{
			if(shouldUpdate())
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
				_values[i] = v;
			}
			updateDispatcher.apply(_values);
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
		public function toBytes(bytes:ByteArray):void{
			bytes.writeUTF(name);
			bytes.writeUnsignedInt(idle);
			bytes.writeDouble(fixedMin);
			bytes.writeDouble(fixedMax);
			bytes.writeBoolean(inverted);
			bytes.writeUnsignedInt(interests.length);
			for each(var gi:GraphInterest in interests) gi.toBytes(bytes);
		}
		public static function FromBytes(bytes:ByteArray):GraphGroup{
			var g:GraphGroup = new GraphGroup(bytes.readUTF());
			g.idle = bytes.readUnsignedInt();
			g.fixedMin = bytes.readDouble();
			g.fixedMax = bytes.readDouble();
			g.inverted = bytes.readBoolean();
			var len:uint = bytes.readUnsignedInt();
			while(len){
				g.interests.push(GraphInterest.FromBytes(bytes));
				len--;
			}
			return g;
		}
	}
}