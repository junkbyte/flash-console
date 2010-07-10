package com.luaye.console 
{
	/**
	 * @author LuAye
	 */
	public class KeyBind 
	{
		
		private static const SHIFT:uint = 1;
		private static const CTRL:uint = 1<<1;
		private static const ALT:uint = 1<<2;
		
		public var char:String;
		public var extra:uint;
		
		public function KeyBind(character:String, shift:Boolean = false, ctrl:Boolean = false, alt:Boolean = false)
		{
			if(!character || character.length != 1){
				throw new Error("KeyBind: character (first char) must be a single character. You gave ["+character+"]");
			}
			char = character.toUpperCase();
			if(shift) extra |= SHIFT;
			if(ctrl) extra |= CTRL;
			if(alt) extra |= ALT;
		}
		
		public function get key():String
		{
			return char+extra;
		}
		public function toString():String
		{
			var str:String = char;
			if(extra & SHIFT) str+="+shift";
			if(extra & CTRL) str+="+ctrl";
			if(extra & ALT) str+="+alt";
			return str;
		}
	}
}
