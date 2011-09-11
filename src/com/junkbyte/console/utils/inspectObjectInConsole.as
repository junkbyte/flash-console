package com.junkbyte.console.utils
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModules;

	public function inspectObjectInConsole(console:Console, obj:Object, showInherit:Boolean = true, channel:String)
	{
		console.modules.getModuleByClass();
		_central.refs.inspect(obj, showInherit, ConsoleModules.MakeChannelName(channel));
	}
}