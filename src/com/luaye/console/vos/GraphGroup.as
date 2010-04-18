package com.luaye.console.vos {
	import flash.geom.Rectangle;

	/**
	 * @author LuAye
	 */
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