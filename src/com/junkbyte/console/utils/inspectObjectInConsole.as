package com.junkbyte.console.utils
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModulesManager;

	public function inspectObjectInConsole(console:Console, obj:Object, showInherit:Boolean = true, channel:String)
	{
		console.modules.getModuleByClass();
		_central.refs.inspect(obj, showInherit, ConsoleModulesManager.MakeChannelName(channel));
	}
}