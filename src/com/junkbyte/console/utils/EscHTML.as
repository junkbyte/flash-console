package com.junkbyte.console.utils
{
	public function EscHTML(str:String):String
	{
		return str.replace(/</g, "&lt;").replace(/\>/g, "&gt;").replace(/\x00/g, "");
	}
}