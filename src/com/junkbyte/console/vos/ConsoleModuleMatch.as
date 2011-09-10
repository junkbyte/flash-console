package com.junkbyte.console.vos
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.interfaces.IConsoleModule;

	public class ConsoleModuleMatch
	{
		protected var name:String;
		protected var type:Class;
		
		public static function createForName(name:String):ConsoleModuleMatch
		{
			var comparer:ConsoleModuleMatch = new ConsoleModuleMatch();
			comparer.name = name;
			return comparer;
		}
		
		public static function createForClass(type:Class):ConsoleModuleMatch
		{
			var comparer:ConsoleModuleMatch = new ConsoleModuleMatch();
			comparer.type = type;
			return comparer;
		}
		
		public function matches(module:IConsoleModule):Boolean
		{
			if(name != null && module.getModuleName() == name)
			{
				return true;
			}
			else if(type != null && module is type)
			{
				return true;
			}
			return false;
		}
	}
}