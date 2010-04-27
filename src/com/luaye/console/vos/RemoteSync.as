package com.luaye.console.vos {

	/**
	 * @author LuAye
	 */
	public class RemoteSync {
		public var lines:Array;
		public var graphs:Array;
		public var om:Object;
		public var cl:String;
		
		
		public static function FromObject(o:Object):RemoteSync{
			var vo:RemoteSync = new RemoteSync();
			vo.lines = o.lines;
			vo.graphs = o.graphs;
			vo.cl = o.cl;
			vo.om = o.om;
			return vo;
		}
	}
}
