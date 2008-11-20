package com.atticmedia.console.core {

	/**
	 * @author lu
	 */
	public class LogLineVO {
		public var text:String;
		public var c:String;
		public var p:int;
		public var time:int;
		public var r:Boolean;
		public var s:Boolean;
		public function LogLineVO(t:String, c:String, p:int, repeating:Boolean = false, skipSafe:Boolean = false, time:int = 0){
			this.text = t;
			this.c = c;
			this.p = p;
			this.time = time;
			this.r = repeating;
			this.s = skipSafe;
		}
	}
}
