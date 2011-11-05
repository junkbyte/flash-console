package com.junkbyte.console.utils
{
	import flash.utils.getQualifiedClassName;

	/**
	 * Produces class name without package path
	 * e.g: flash.display.Sprite => Sprite
	 */
	public function getQualifiedShortClassName(obj:Object):String
	{
		var str:String = getQualifiedClassName(obj);
		var ind:int = str.indexOf("::");
		var st:String = obj is Class ? "*" : "";
		str = st + str.substring(ind >= 0 ? (ind + 2) : 0) + st;
		return str;
	}
}