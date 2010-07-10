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
	import flash.geom.Rectangle;

	public class GraphGroup {
		
		public static const TYPE_FPS:uint = 1;
		public static const TYPE_MEM:uint = 2;
	
		public var type:uint;
		public var name:String;
		public var freq:int = 1; // update every n number of frames.
		public var low:Number;
		public var hi:Number;
		public var fixed:Boolean;
		public var averaging:uint;
		public var inv:Boolean;
		public var interests:Array = [];
		public var rect:Rectangle;
		//
		//
		public var idle:int;
		
		public function GraphGroup(n:String){
			name = n;
		}
		public function updateMinMax(v:Number):void{
			if(!isNaN(v) && !fixed){
				if(isNaN(low)) {
					low = v;
					hi = v;
				}
				if(v > hi) hi = v;
				if(v < low) low = v;
			}
		}
		//
		//
		//
		public function toObject():Object{
			var gis:Array = [];
			for each(var gi:GraphInterest in interests) gis.push(gi.toObject());
			return {t:type, n:name, l:low, h:hi, idle:idle, v:inv, i:gis};
		}
		public static function FromObject(o:Object):GraphGroup{
			var g:GraphGroup = new GraphGroup(o.n);
			g.type = o.t;
			g.idle = o.idle;
			g.low = o.l;
			g.hi = o.h;
			g.inv = o.v;
			if(o.i != null) for each(var io:Object in o.i) g.interests.push(GraphInterest.FromObject(io));
			return g;
		}
	}
}