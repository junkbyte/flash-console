package com.junkbyte.console.utils
{
	import com.junkbyte.console.logging.Logs;

	public function makeConsoleChannel(obj:*):String
		{
			if (obj is String) return obj as String;
			else if (obj) return EscHTML(getQualifiedShortClassName(obj));
			return Logs.DEFAULT_CHANNEL;
		}
}